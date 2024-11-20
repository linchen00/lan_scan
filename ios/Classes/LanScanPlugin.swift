import Flutter
import UIKit

public class LanScanPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "lan_scan", binaryMessenger: registrar.messenger())
        let instance = LanScanPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        let lanScanEventChannel = FlutterEventChannel(name: "lan_scan_event",
                                                binaryMessenger:registrar.messenger(),
                                                codec:FlutterStandardMethodCodec.sharedInstance(),
                                                taskQueue: registrar.messenger().makeBackgroundTaskQueue?())
        lanScanEventChannel.setStreamHandler(LanDeviceHandler())
        
        let wifiConnectionStatusChangeEventChannel = FlutterEventChannel(name: "wifi_connection_status_change_event",
                                                binaryMessenger:registrar.messenger())
        wifiConnectionStatusChangeEventChannel.setStreamHandler(WiFiConnectionStatusHandler())
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
        case "isWifiConnected":
            Wireless().checkWifiConnection{ isConnected in
                result(isConnected)
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
