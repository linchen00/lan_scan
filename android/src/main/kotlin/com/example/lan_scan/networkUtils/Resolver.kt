package com.example.lan_scan.networkUtils

import java.io.IOException
import java.net.InetAddress

interface Resolver {
    @Throws(IOException::class)
    fun resolve(ip: InetAddress): Array<String?>?

    fun close()

}