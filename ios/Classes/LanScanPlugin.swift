import Flutter
import UIKit

public class LanScanPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "lan_scan", binaryMessenger: registrar.messenger())
        let instance = LanScanPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        let searchChannel = FlutterEventChannel(name: "lan_scan_search_devices", binaryMessenger: registrar.messenger())
        searchChannel.setStreamHandler(SearchDevicesHandlerImpl())
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
          var host  =   Host(ip: "192.168.1.5")
            host.hostname = "1555"
            if let jsonData = try? JSONEncoder().encode(host),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                print(jsonString)
                
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
