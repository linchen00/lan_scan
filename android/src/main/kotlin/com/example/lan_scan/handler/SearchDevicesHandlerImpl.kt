package com.example.lan_scan.handler

import android.content.Context
import android.text.format.DateUtils
import com.example.lan_scan.HostScanError
import com.example.lan_scan.network.Wireless
import com.example.lan_scan.task.ScanHostsAsyncTask
import io.flutter.plugin.common.EventChannel

class SearchDevicesHandlerImpl(context: Context) : EventChannel.StreamHandler {

    private val wireless = Wireless(context)

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {

        if (!wireless.isEnabled()) {
            events.error(
                HostScanError.WIFI_NOT_AVAILABLE.code,
                HostScanError.WIFI_NOT_AVAILABLE.description,
                null,
            )
            events.endOfStream()
            return
        }

        if (!wireless.isConnectedWifi()) {
            events.error(
                HostScanError.WIFI_NOT_CONNECTED.code,
                HostScanError.WIFI_NOT_CONNECTED.description,
                null,
            )
            events.endOfStream()
            return
        }


        val localIp = wireless.getInternalWifiIpAddress() // 获取内网IP
        val cidrPrefixLength = wireless.getInternalWifiCidrPrefixLength() // CIDR 前缀长度

        val scanHostsAsyncTask = ScanHostsAsyncTask(events)
        scanHostsAsyncTask.scanHosts(localIp, cidrPrefixLength, 5*DateUtils.MINUTE_IN_MILLIS)

    }

    override fun onCancel(arguments: Any?) {
    }
}