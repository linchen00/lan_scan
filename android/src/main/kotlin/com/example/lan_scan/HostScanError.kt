package com.example.lan_scan

enum class HostScanError(val code: String, val description: String) {
    WIFI_NOT_AVAILABLE("1", "Wi-Fi is not available"),
    WIFI_NOT_CONNECTED("2", "Wi-Fi is not connected"),
}
