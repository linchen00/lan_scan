package com.example.lan_scan.networkUtils

import kotlinx.serialization.Serializable
@Serializable
data class Host(val ip: String) {

    var mac: String? = null

    var hostname: String? = null
        set(value) {
            field = if (value != null && (value.isEmpty() || value.endsWith(".local"))) {
                value.substring(0, value.length - 6)
            } else {
                value
            }
        }

    override fun toString(): String {
        return "Host(ip='$ip', mac='$mac', hostname=$hostname)"
    }

}
