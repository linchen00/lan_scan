package com.example.lan_scan.handler

import android.annotation.SuppressLint
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.Build
import androidx.annotation.RequiresApi
import io.flutter.plugin.common.EventChannel

class WiFiConnectionStatusHandler(private var context: Context) : EventChannel.StreamHandler {

    private var eventSink: EventChannel.EventSink? = null
    private var wifiStateReceiver: BroadcastReceiver? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        registerReceiver()
    }

    override fun onCancel(arguments: Any?) {
        unregisterReceiver()
    }

    private fun registerReceiver() {
        if (wifiStateReceiver == null) {
            wifiStateReceiver = object : BroadcastReceiver() {
                override fun onReceive(context: Context?, intent: Intent?) {
                    val isConnected = isWifiConnected()
                    eventSink?.success(isConnected)
                }
            }
            val filter = IntentFilter().apply {
                addAction(ConnectivityManager.CONNECTIVITY_ACTION)
                // 针对 Android 7.0 及以上版本
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    addAction(ConnectivityManager.ACTION_CAPTIVE_PORTAL_SIGN_IN)
                    addAction(ConnectivityManager.ACTION_RESTRICT_BACKGROUND_CHANGED)
                }
            }
            context.registerReceiver(wifiStateReceiver, filter)
        }
    }

    private fun unregisterReceiver() {
        if (wifiStateReceiver != null) {
            context.unregisterReceiver(wifiStateReceiver)
            wifiStateReceiver = null
        }
    }

    private fun isWifiConnected(): Boolean {
        val connectivityManager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val network = connectivityManager.activeNetwork ?: return false
            val capabilities = connectivityManager.getNetworkCapabilities(network) ?: return false
            return capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)
        } else {
            val networkInfo = connectivityManager.activeNetworkInfo ?: return false
            return networkInfo.type == ConnectivityManager.TYPE_WIFI && networkInfo.isConnected
        }
    }
}