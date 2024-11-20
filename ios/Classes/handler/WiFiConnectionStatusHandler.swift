//
//  WiFiConnectionStatusHandler.swift
//  lan_scan
//
//  Created by arthur on 2024/11/20.
//

import Foundation
import Flutter
import Network

class WiFiConnectionStatusHandler: NSObject,FlutterStreamHandler {
    
    private var eventSink: FlutterEventSink?
    private var monitor: NWPathMonitor?
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        startMonitoring()
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        stopMonitoring()
        eventSink = nil
        return nil
    }
    
    private func startMonitoring() {
        monitor = NWPathMonitor()
        let queue = DispatchQueue.global(qos: .default)
        monitor?.pathUpdateHandler = { [weak self] path in
            guard let eventSink = self?.eventSink else { return }
            if path.usesInterfaceType(.wifi) {
                eventSink(true)  // Wi-Fi is connected
            } else {
                eventSink(false) // Wi-Fi is not connected
            }
        }
        monitor?.start(queue: queue)
    }
    
    private func stopMonitoring() {
        monitor?.cancel()
        monitor = nil
    }
}
