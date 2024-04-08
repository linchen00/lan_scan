package com.example.lan_scan.network

import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetAddress

class NetBIOSResolver(timeout: Long) : Resolver {
    private val requestData = byteArrayOf(
        0xA2.toByte(), 0x48, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x20, 0x43,
        0x4b, 0x41, 0x41, 0x41, 0x41, 0x41, 0x41, 0x41, 0x41, 0x41, 0x41, 0x41, 0x41, 0x41,
        0x41, 0x41, 0x41, 0x41, 0x41, 0x41, 0x41, 0x41, 0x41, 0x41, 0x41, 0x41, 0x41, 0x41,
        0x41, 0x41, 0x41, 0x00, 0x00, 0x21, 0x00, 0x01
    )
    private val netBIOSPort = 137
    private val responseTypePos = 47
    private val responseTypeNbtstat: Byte = 33
    private val responseBaseLen = 57
    private val responseNameLen = 15
    private val responseNameBlockLen = 18
    private val groupNameFlag = 128
    private val nameTypeDomain = 0x00
    private val nameTypeMessenger = 0x03


    private var socket = DatagramSocket()

    init {
        socket.soTimeout = timeout.toInt()
    }

    override fun resolve(ip: InetAddress): Array<String?>? {
        socket.send(
            DatagramPacket(
                requestData,
                requestData.size,
                ip,
                netBIOSPort
            )
        )

        val response = ByteArray(1024)
        val responsePacket = DatagramPacket(response, response.size)
        socket.receive(responsePacket)

        if (responsePacket.length < responseBaseLen || response[responseTypePos] != responseTypeNbtstat) {
            return null // response was too short - no names returned
        }

        val nameCount = response[responseBaseLen - 1].toInt() and 0xFF
        if (responsePacket.length < responseBaseLen + responseNameBlockLen * nameCount) {
            return null // data was truncated or something is wrong
        }

        return extractNames(response, nameCount)
    }

    private fun extractNames(response: ByteArray, nameCount: Int): Array<String?> {
        val computerName = if (nameCount > 0) name(response, 0) else null
        var groupName: String? = null
        for (i in 1 until nameCount) {
            if (nameType(response, i) == nameTypeDomain && (nameFlag(
                    response,
                    i
                ) and groupNameFlag) > 0
            ) {
                groupName = name(response, i)
                break
            }
        }
        var userName: String? = null
        for (i in nameCount - 1 downTo 1) {
            if (nameType(response, i) == nameTypeMessenger) {
                userName = name(response, i)
                break
            }
        }
        val macAddress = String.format(
            "%02X-%02X-%02X-%02X-%02X-%02X",
            nameByte(response, nameCount, 0), nameByte(response, nameCount, 1),
            nameByte(response, nameCount, 2), nameByte(response, nameCount, 3),
            nameByte(response, nameCount, 4), nameByte(response, nameCount, 5)
        )
        return arrayOf(computerName, userName, groupName, macAddress)
    }

    private fun name(response: ByteArray, i: Int): String {
        // as we have no idea in which encoding are the received names,
        // assume that local default encoding matches the remote one (they are on the same LAN most probably)
        return String(
            response,
            responseBaseLen + responseNameBlockLen * i,
            responseNameLen
        ).trim { it <= ' ' }
    }

    private fun nameByte(response: ByteArray, i: Int, n: Int): Int {
        return response[responseBaseLen + responseNameBlockLen * i + n].toInt() and 0xFF
    }

    private fun nameFlag(response: ByteArray, i: Int): Int {
        return response[responseBaseLen + responseNameBlockLen * i + responseNameLen + 1].toInt() and 0xFF + (response[responseBaseLen + responseNameBlockLen * i + responseNameLen + 2].toInt() and 0xFF) * 0xFF
    }

    private fun nameType(response: ByteArray, i: Int): Int {
        return response[responseBaseLen + responseNameBlockLen * i + responseNameLen].toInt() and 0xFF
    }

    override fun close() {
        socket.close()
    }
}