//
//  LanDeviceHandler.swift
//  flutter_scan_plugin
//
//  Created by arthur on 2024/11/15.
//

import Foundation
import Flutter

class LanDeviceHandler: NSObject,FlutterStreamHandler {
    
    private var lanDeviceScanner: LanDeviceScanner?;
    
    private var wireless: Wireless = Wireless();
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        print("onListen......")
        
        if let ipv4 = wireless.getInternalWifiIpAddress(),
           let cidrPrefixLength = wireless.getInternalWifiCidrPrefixLength() {
            lanDeviceScanner = LanDeviceScanner(eventSink: events, ipv4: ipv4, cidrPrefixLength: cidrPrefixLength)
            Task{
                await lanDeviceScanner?.startScanning()
            }
            
        }else{
            DispatchQueue.main.async {
                print("no wifi")
                events(nil)
            }
        }
        
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        print("onCancel......")
        lanDeviceScanner?.stopScanning()
        return nil
    }
    
}
