package com.example.lan_scan.network

import java.io.IOException
import java.net.InetAddress

interface Resolver {
    @Throws(IOException::class)
    fun resolve(ip: InetAddress): Array<String?>?

    fun close()

}