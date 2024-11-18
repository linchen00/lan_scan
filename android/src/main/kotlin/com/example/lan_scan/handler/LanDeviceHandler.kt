package com.example.lan_scan.handler

import android.content.Context
import android.os.Handler
import android.os.Looper
import com.example.lan_scan.networkUtils.Wireless
import com.example.lan_scan.scanner.LanDeviceScanner
import io.flutter.plugin.common.EventChannel

class LanDeviceHandler(context: Context) : EventChannel.StreamHandler {

    private val wireless = Wireless(context)
    private var lanDeviceScanner: LanDeviceScanner? = null;

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {

        if (wireless.isEnabled() && wireless.isConnectedWifi() && events != null) {
            val ipv4 = wireless.getInternalWifiIpAddress() // 获取内网IP
            val cidrPrefixLength = wireless.getInternalWifiCidrPrefixLength() // CIDR 前缀长度
            lanDeviceScanner = LanDeviceScanner(events, ipv4, cidrPrefixLength)
            lanDeviceScanner?.startScanning()
        } else {
            Handler(Looper.getMainLooper()).post {
                events?.success(null)
            }
        }
    }

    override fun onCancel(arguments: Any?) {
        lanDeviceScanner?.stopScanning()
    }
}