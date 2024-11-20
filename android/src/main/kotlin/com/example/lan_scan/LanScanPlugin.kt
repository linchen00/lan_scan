package com.example.lan_scan

import com.example.lan_scan.handler.LanDeviceHandler
import com.example.lan_scan.handler.WiFiConnectionStatusHandler
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.StandardMethodCodec

/** LanScanPlugin */
class LanScanPlugin : FlutterPlugin, MethodCallHandler {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel

    private lateinit var lanScanEventChannel: EventChannel
    private lateinit var wifiConnectionStatusChangeEventChannel: EventChannel

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "lan_scan")
        channel.setMethodCallHandler(this)

        lanScanEventChannel =
            EventChannel(
                flutterPluginBinding.binaryMessenger,
                "lan_scan_event",
                StandardMethodCodec.INSTANCE,
                flutterPluginBinding.binaryMessenger.makeBackgroundTaskQueue()
            )
        lanScanEventChannel.setStreamHandler(LanDeviceHandler(flutterPluginBinding.applicationContext))

        wifiConnectionStatusChangeEventChannel =
            EventChannel(
                flutterPluginBinding.binaryMessenger,
                "wifi_connection_status_change_event",
                StandardMethodCodec.INSTANCE,
                flutterPluginBinding.binaryMessenger.makeBackgroundTaskQueue()
            )
        wifiConnectionStatusChangeEventChannel.setStreamHandler(WiFiConnectionStatusHandler(flutterPluginBinding.applicationContext))
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        if (call.method == "getPlatformVersion") {
            result.success("Android ${android.os.Build.VERSION.RELEASE}")
        } else {
            result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        lanScanEventChannel.setStreamHandler(null)
        wifiConnectionStatusChangeEventChannel.setStreamHandler(null)
    }
}
