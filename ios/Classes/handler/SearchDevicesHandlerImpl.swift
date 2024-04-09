//
//  SearchDevicesHandlerImpl.swift
//  lan_scan
//
//  Created by arthur on 2024/4/7.
//

import Foundation
import Flutter

class SearchDevicesHandlerImpl: NSObject, FlutterStreamHandler {
    
    let wireless =  Wireless()
    
    func onListen(withArguments arguments: Any?, eventSink: @escaping FlutterEventSink) -> FlutterError? {
      
        guard wireless.isWiFiConnected()else{
            let notConnectedError = HostsScanError.notConnected
            eventSink(FlutterError(code: notConnectedError.rawValue, message: notConnectedError.description, details: nil))
            eventSink(FlutterEndOfEventStream)
            return nil
        }
        
        guard let ipv4 = wireless.getInternalWifiIpAddress(),
              let cidrPrefixLength = wireless.getInternalWifiCidrPrefixLength() else{
            let notConnectedError = HostsScanError.notConnected
            eventSink(FlutterError(code: notConnectedError.rawValue, message: notConnectedError.description, details: nil))
            eventSink(FlutterEndOfEventStream)
            return nil
        }
        
        let scanHostsAsyncTask = ScanHostsAsyncTask(eventSink: eventSink)
        Task{
            await scanHostsAsyncTask.scanHosts(ipv4: ipv4, cidrPrefixLength: cidrPrefixLength, timeout: 5000)
        }
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        return nil
    }
}
