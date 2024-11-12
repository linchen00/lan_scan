package com.example.lan_scan.task

import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.ParcelFileDescriptor
import android.text.format.DateUtils
import android.util.Log
import android.util.Pair
import com.example.lan_scan.network.Host
import com.example.lan_scan.network.MDNSResolver
import com.example.lan_scan.network.NetBIOSResolver
import com.example.lan_scan.network.Resolver
import com.example.lan_scan.runnable.ScanHostsRunnable
import com.google.gson.Gson
import io.flutter.plugin.common.EventChannel.EventSink
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.TimeoutCancellationException
import kotlinx.coroutines.async
import kotlinx.coroutines.cancelChildren
import kotlinx.coroutines.launch
import kotlinx.coroutines.withTimeout
import java.io.BufferedReader
import java.io.IOException
import java.io.InputStreamReader
import java.net.InetAddress
import java.net.UnknownHostException
import java.nio.charset.StandardCharsets
import kotlin.math.ceil
import kotlin.math.pow


class ScanHostsAsyncTask(private val eventSink: EventSink) {


    private val tag = ScanHostsAsyncTask::class.java.simpleName

    init {
        System.loadLibrary("ipneigh")
    }

    private external fun nativeIPNeigh(fd: Int): Int

    private val neighborIncomplete = "INCOMPLETE"

    private val neighborFailed = "FAILED"

    private val mainHandler = Handler(Looper.getMainLooper())

    fun scanHosts(ipv4: Int, cidrPrefixLength: Int, timeout: Long) {

        // 创建一个固定大小的线程池，其中包含多个线程
        val hostBits = 32.0 - cidrPrefixLength
        val netmask = -0x1 shr 32 - cidrPrefixLength shl 32 - cidrPrefixLength
        val numberOfHosts = 2.0.pow(hostBits).toInt() - 2
        val firstAddress = (ipv4 and netmask) + 1

        val scanThreads = hostBits.toInt() * 4 * 2
        val chunk = ceil(numberOfHosts.toDouble() / scanThreads).toInt()
        var previousStart = firstAddress
        var previousStop = firstAddress + (chunk - 2)

        CoroutineScope(Dispatchers.Main).launch {
            val scanHostJob = async {
                // 创建多个协程并存储引用
                withTimeout(timeout) {
                    for (i in 0 until scanThreads) {
                        val start = previousStart
                        val stop = previousStop
                        launch(Dispatchers.IO) {
                            val scanHostsRunnable =
                                ScanHostsRunnable(
                                    start,
                                    stop,
                                    DateUtils.SECOND_IN_MILLIS
                                )
                            scanHostsRunnable.run()
                        }
                        previousStart = previousStop + 1
                        previousStop = previousStart + (chunk - 1)
                    }
                }
            }

            try {
                scanHostJob.await()
            } catch (e: TimeoutCancellationException) {
                e.printStackTrace()
                scanHostJob.cancelChildren() // 超时时取消所有协程
            }

            if(Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                Log.d(tag, "android 13+")
                eventSink.endOfStream()
            }else{
                val arpList = parseAndExtractValidArpFromInputStream()
                Log.d(tag, "arpListSize:${arpList.size}")
                async {
                    arpList.forEach { arp ->
                        launch(Dispatchers.IO) {
                            val host = processArp(arp)
                            val json = Gson().toJson(host)
                            mainHandler.post {
                                eventSink.success(json)
                            }
                        }
                    }
                }.await()

                eventSink.endOfStream()
            }




        }

    }

    private fun parseAndExtractValidArpFromInputStream(): MutableList<Pair<String, String>> {

        val pairs: MutableList<Pair<String, String>> = ArrayList()

        val pipe: Array<ParcelFileDescriptor> = ParcelFileDescriptor.createPipe()
        val readSidePfd = pipe[0]
        val writeSidePfd = pipe[1]
        val inputStream = ParcelFileDescriptor.AutoCloseInputStream(readSidePfd)

        val fdWrite = writeSidePfd.detachFd()
        val returnCode: Int = nativeIPNeigh(fdWrite)

        if (returnCode != 0) {
            return pairs
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
                            pairs.add(Pair<String, String>(ip, macAddress))
                        }
                    }
                } catch (e: UnknownHostException) {
                    // 处理IP地址解析异常
                    e.printStackTrace()
                }
            }
        }

        return pairs

    }

    private fun processArp(arp: Pair<String, String>): Host {
        val ip = arp.first
        val macAddress = arp.second
        val host = Host(ip)
        host.mac = macAddress
        try {
            val add = try {
                InetAddress.getByName(ip)
            } catch (e: UnknownHostException) {
                return host
            }
            val hostname = add.canonicalHostName
            host.hostname = hostname
            // BUG: Some devices don't respond to mDNS if NetBIOS is queried first. Why?
            // So let's query mDNS first, to keep in mind for eventual UPnP implementation.
            val lanSocketTimeout = DateUtils.SECOND_IN_MILLIS
            val isResolveHostName =
                resolveHostName(ip, host, MDNSResolver(lanSocketTimeout))
            if (!isResolveHostName) {
                resolveHostName(ip, host, NetBIOSResolver(lanSocketTimeout))
            }

        } catch (e: Exception) {
            e.printStackTrace()
        }
        return host

    }

    private fun resolveHostName(
        ip: String,
        host: Host,
        resolver: Resolver
    ): Boolean {
        val add = try {
            InetAddress.getByName(ip)
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