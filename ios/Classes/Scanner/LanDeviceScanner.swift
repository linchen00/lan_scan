//
//  LanDeviceScanner.swift
//  flutter_scan_plugin
//
//  Created by arthur on 2024/11/15.
//

import Foundation
import Flutter
import Network

class LanDeviceScanner{
    
    private var eventSink:FlutterEventSink;
    private var ipv4:Int;
    private var cidrPrefixLength:Int;
    
    private var scanningTask: Task<Void, Never>?
    
    
    init(eventSink:@escaping FlutterEventSink, ipv4 : Int, cidrPrefixLength: Int) {
        self.eventSink = eventSink
        self.ipv4 = ipv4
        self.cidrPrefixLength = cidrPrefixLength
    }
    
    func startScanning() -> Void {
        scanningTask = Task {
            let netmask = (0xFFFFFFFF << (32 - cidrPrefixLength)) & 0xFFFFFFFF
            let hostBits = Double(32 - cidrPrefixLength)
            let numberOfHosts = Int(pow(2.0, hostBits)) - 2
            let concurrentThreads = (32 - cidrPrefixLength) * 8
            let firstAddr = (ipv4 & netmask) + 1
            
            await withTaskGroup(of: Void.self) { taskGroup in
                for i in 0..<concurrentThreads {
                    taskGroup.addTask {
                        for index in stride(from: i, to: numberOfHosts, by: concurrentThreads) {
                            if Task.isCancelled { return }
                            let ipAddress = self.getIPAddress(index: firstAddr + index)
                            let pingHelper = PingHelper(ipAddress: ipAddress, timeout: TimeInterval(1))
                            let pingSuccess = await pingHelper.start()
                            if Task.isCancelled { return }
                            if pingSuccess {
                                let host = await self.resolveHostname(ipAddress: ipAddress)
                                if let jsonData = try? JSONEncoder().encode(host),
                                   let jsonString = String(data: jsonData, encoding: .utf8) {
                                    DispatchQueue.main.async {
                                        self.eventSink(jsonString)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            if(scanningTask != nil){
                scanningTask = nil
                DispatchQueue.main.async {
                    self.eventSink(nil)
                }
            }
            
        }
        
    }
    
    func stopScanning() -> Void {
        if (scanningTask != nil){
            scanningTask?.cancel()
            scanningTask = nil
            DispatchQueue.main.async {
                self.eventSink(nil)
            }
        }
        
    }
    
    private  func getIPAddress(index: Int) -> String {
        let byte1 = UInt8((index >> 24) & 0xFF)
        let byte2 = UInt8((index >> 16) & 0xFF)
        let byte3 = UInt8((index >> 8) & 0xFF)
        let byte4 = UInt8(index & 0xFF)
        return "\(byte1).\(byte2).\(byte3).\(byte4)"
    }
    
    private func resolveHostname(ipAddress: String)async ->Host {
        
        var host = Host(ip: ipAddress)
        let mdnsResolver = MDNSResolver(timeout: .seconds(1))
        let netBIOSResolver = NetBIOSResolver()
        var hostname = host.hostname
        
        if hostname == nil{
            if(scanningTask?.isCancelled == true) { return host}
            hostname = await mdnsResolver.resolve(ip: ipAddress)
        }
        
        if hostname == nil {
            if(scanningTask?.isCancelled == true) { return host}
            hostname = netBIOSResolver.resolve(ip: ipAddress)
        }
        
        if hostname == nil {
            if(scanningTask?.isCancelled == true) { return host}
            hostname = getHostName( ipAddress: ipAddress)
        }
        
        host.hostname = hostname
        
        return host
        
    }
    
    private func getHostName( ipAddress: String) -> String? {
        // 将 C 字符串转换为 in_addr 结构体
        var addr = in_addr()
        
        // 将 IP 地址转换为 C 字符串
        let cIpAddress = ipAddress.cString(using: .utf8)
        if cIpAddress != nil {
            inet_aton(cIpAddress, &addr)
        } else {
            return nil
        }
        
        let hostLength = socklen_t(MemoryLayout<in_addr>.size)
        if let host = gethostbyaddr(&addr, hostLength, AF_INET), let hostnamePtr = host.pointee.h_name {
            return String(cString: hostnamePtr)
        }
        return nil
        
    }
    
}
