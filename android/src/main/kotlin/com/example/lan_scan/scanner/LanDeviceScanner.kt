package com.example.lan_scan.scanner

import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.ParcelFileDescriptor
import android.text.format.DateUtils
import android.util.Log
import com.example.lan_scan.networkUtils.Host
import com.example.lan_scan.networkUtils.MDNSResolver
import com.example.lan_scan.networkUtils.NetBIOSResolver
import com.example.lan_scan.networkUtils.Resolver
import com.google.gson.Gson
import io.flutter.plugin.common.EventChannel.EventSink
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.TimeoutCancellationException
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.isActive
import kotlinx.coroutines.joinAll
import kotlinx.coroutines.launch
import kotlinx.coroutines.withTimeout
import java.io.BufferedReader
import java.io.IOException
import java.io.InputStreamReader
import java.math.BigInteger
import java.net.InetAddress
import java.net.InetSocketAddress
import java.net.Socket
import java.net.UnknownHostException
import java.nio.charset.StandardCharsets
import kotlin.math.pow


class LanDeviceScanner(
    private val eventSink: EventSink,
    private val ipv4: Int,
    private val cidrPrefixLength: Int
) {

    init {
        System.loadLibrary("ipneigh")
    }

    private val tag = LanDeviceScanner::class.java.simpleName

    private val gson = Gson()

    private external fun nativeIPNeigh(fd: Int): Int

    private val neighborIncomplete = "INCOMPLETE"

    private val neighborFailed = "FAILED"

    private val mainHandler = Handler(Looper.getMainLooper())

    private var job: Job? = null

    fun startScanning() {
        val hostBits = 32.0 - cidrPrefixLength
        val netmask = -0x1 shr 32 - cidrPrefixLength shl 32 - cidrPrefixLength
        val numberOfHosts = 2.0.pow(hostBits).toInt() - 2
        val firstAddress = (ipv4 and netmask) + 1
        val scanThreads = hostBits.toInt() * 8

        job = CoroutineScope(Dispatchers.IO).launch {
            try {
                withTimeout(5 * DateUtils.MINUTE_IN_MILLIS) {
                    coroutineScope {
                        // 启动多个协程，每个协程处理分配的部分任务
                        List(scanThreads) { threadIndex ->
                            launch {
                                for (index in threadIndex until numberOfHosts step scanThreads) {
                                    if (!isActive) return@launch
                                    val numericIp = index + firstAddress
                                    val bytes = BigInteger.valueOf(numericIp.toLong()).toByteArray()
                                    val inetAddress = InetAddress.getByAddress(bytes)
                                    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
                                        handleSocketConnection(inetAddress)
                                    } else {
                                        handleReachability(inetAddress)
                                    }
                                }
                            }
                        }.joinAll()
                    }
                }
            } catch (e: TimeoutCancellationException) {
                println("Timeout occurred! Cancelling tasks...")
            }

            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
                handleArpTable()
            }

            if (isActive) {
                mainHandler.post {
                    eventSink.success(null)
                }
            }

        }

    }

    fun stopScanning() {
        job?.cancel()
        job = null
        mainHandler.post {
            eventSink.success(null)
        }

    }

    private fun handleSocketConnection(inetAddress: InetAddress) {
        try {
            Socket().use { socket ->
                socket.tcpNoDelay = true
                socket.connect(
                    InetSocketAddress(inetAddress, 7),
                    DateUtils.SECOND_IN_MILLIS.toInt()
                )
                Log.d(tag, "ip: ${inetAddress.hostAddress}")
            }
        } catch (_: IOException) {
            // Ignore connection failures for ARP table population
        }
    }

    private suspend fun handleReachability(inetAddress: InetAddress) = coroutineScope {
        if (inetAddress.isReachable(DateUtils.SECOND_IN_MILLIS.toInt())) {
            inetAddress.hostAddress?.let {
                var host = Host(it)
                host = processHost(host)
                if (!isActive) return@coroutineScope
                mainHandler.post {
                    eventSink.success(gson.toJson(host))
                }
            }
        }
    }


    private suspend fun handleArpTable() = coroutineScope {
        val hostList = parseAndExtractValidArpFromInputStream()
        try {
            hostList.map { host ->
                async(Dispatchers.IO) {
                    if (!isActive) return@async null
                    val processedHost = processHost(host)
                    mainHandler.post {
                        eventSink.success(gson.toJson(processedHost))
                    }
                }
            }.awaitAll()
        } catch (e: Exception) {
            Log.e(tag, "Error processing ARP table", e)
        }
    }

    private fun parseAndExtractValidArpFromInputStream(): ArrayList<Host> {

        val hosts: ArrayList<Host> = ArrayList()
        val pipe: Array<ParcelFileDescriptor> = ParcelFileDescriptor.createPipe()
        val readSidePfd = pipe[0]
        val writeSidePfd = pipe[1]
        val inputStream = ParcelFileDescriptor.AutoCloseInputStream(readSidePfd)

        val fdWrite = writeSidePfd.detachFd()
        val returnCode: Int = nativeIPNeigh(fdWrite)

        if (returnCode != 0) {
            return hosts
        }

        val reader = BufferedReader(InputStreamReader(inputStream, StandardCharsets.UTF_8))
        val lines = reader.readLines()
        lines.forEach { line ->
            val neighborLine = line.split(Regex("\\s+"))
            if (neighborLine.size > 5) {
                val ip = neighborLine[0]
                val macAddress = neighborLine[4]
                val state = neighborLine.last()

                try {
                    val address = InetAddress.getByName(ip)
                    // 排除Link-local和Loopback地址
                    if (!address.isLinkLocalAddress && !address.isLoopbackAddress) {
                        // 有效ARP条目的状态不是Failed或者Incomplete
                        // Determine if the ARP entry is valid.
                        // https://github.com/sivasankariit/iproute2/blob/master/ip/ipneigh.c
                        if (state != neighborFailed && state != neighborIncomplete) {
                            val host = Host(ip)
                            host.mac = macAddress
                            hosts.add(host)
                        }
                    }
                } catch (e: UnknownHostException) {
                    // 处理IP地址解析异常
                    e.printStackTrace()
                }
            }
        }

        return hosts

    }

    private fun processHost(host: Host): Host {
        try {
            val add = try {
                InetAddress.getByName(host.ip)
            } catch (e: UnknownHostException) {
                return host
            }
            val hostname = add.canonicalHostName
            host.hostname = hostname
            // BUG: Some devices don't respond to mDNS if NetBIOS is queried first. Why?
            // So let's query mDNS first, to keep in mind for eventual UPnP implementation.
            val lanSocketTimeout = DateUtils.SECOND_IN_MILLIS
            val isResolveHostName =
                resolveHostName(host, MDNSResolver(lanSocketTimeout))
            if (!isResolveHostName) {
                resolveHostName(host, NetBIOSResolver(lanSocketTimeout))
            }

        } catch (e: Exception) {
            e.printStackTrace()
        }
        return host

    }

    private fun resolveHostName(
        host: Host,
        resolver: Resolver
    ): Boolean {
        val add = try {
            InetAddress.getByName(host.ip)
        } catch (e: UnknownHostException) {
            resolver.close()
            return false
        }
        val name = try {
            resolver.resolve(add)
        } catch (e: IOException) {
            resolver.close()
            return false
        }
        resolver.close()
        if ((name != null) && !name.first().isNullOrBlank()) {
            host.hostname = name[0]
            return true
        }
        return false
    }


}