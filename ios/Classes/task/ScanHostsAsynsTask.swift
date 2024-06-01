//
//  ScanHostsAsynsTask.swift
//  lan_scan
//
//  Created by arthur on 2024/4/9.
//

import Foundation
import Flutter
import Network

class ScanHostsAsyncTask{
    
    let eventSink:FlutterEventSink
    
    init(eventSink:@escaping  FlutterEventSink) {
        self.eventSink = eventSink
    }
    
    func scanHosts(ipv4: Int, cidrPrefixLength: Int, timeout: Int) async {
        let netmask = (0xFFFFFFFF << (32 - cidrPrefixLength)) & 0xFFFFFFFF
        let hostBits = Double(32 - cidrPrefixLength)
        let numberOfHosts = Int(pow(2.0, hostBits)) - 2
        let scanThreads = (32 - cidrPrefixLength) * 4 * 2
        let firstAddr = (ipv4 & netmask) + 1
        
        let startTime =  Date()
        let ipList = await scanIPRange(firstAddr: firstAddr,numberOfHosts:numberOfHosts,threadsCount: scanThreads)
        
        print("difference:\(Date().timeIntervalSince(startTime))")
        if (ipList.isEmpty){
             DispatchQueue.main.async {
                 self.eventSink(FlutterEndOfEventStream)
             }
             return
         }
    
        let ipChunkSize = Int(ceil((Double(ipList.count) / Double(scanThreads))))
        
        await withTaskGroup(of: Void.self) { group in
            for start in stride(from: 0, to: ipList.count, by: ipChunkSize) {
                let end = min(start + ipChunkSize, ipList.count)
                let sublist = Array(ipList[start..<end])
                group.addTask {
                    for ip in sublist {
                        let host = await self.resolveHostname(ip: ip)
                        
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
        
        DispatchQueue.main.async {
            self.eventSink(FlutterEndOfEventStream)
        }
        
        print("finish:\(Date().timeIntervalSince(startTime))")
    }
    
    private func scanIPRange(firstAddr: Int, numberOfHosts: Int, threadsCount: Int) async -> [String] {
        let chunkSize = Int(ceil(Double(numberOfHosts) / Double(threadsCount)))
        let extraHosts = chunkSize*threadsCount-numberOfHosts

        var previousStart = firstAddr
        var previousEnd = firstAddr + (chunkSize - extraHosts)
        
        let ipList = await withTaskGroup(of: [String].self) { taskGroup in
            for _ in 0..<Int(threadsCount) {
                let start = previousStart
                let end = previousEnd
                taskGroup.addTask {
                    let scanHostsRunnable = ScanHostsRunnable(start: start, end: end, timeout: TimeInterval(1))
                    return await scanHostsRunnable.run()
                }
                
                previousStart = end + 1
                previousEnd = previousStart + (chunkSize - 1)
            }
            
            var ipList: [String] = []
            for await taskResult in taskGroup {
                ipList.append(contentsOf: taskResult)
            }
            return ipList
        }
        
        return ipList
    }
    
    private func resolveHostname(ip: String)async ->Host {
        
        var host = Host(ip: ip)
        let mdnsResolver = MDNSResolver(timeout: .seconds(1))
        let netBIOSResolver = NetBIOSResolver()
        var hostname = await mdnsResolver.resolve(ip: ip)
        
        if hostname == nil {
            hostname = netBIOSResolver.resolve(ip: ip)
        }
        
        host.hostname = hostname
        
        return host
        
    }
    
    // 堵塞线程
    func getHostName(for ipAddress: String) -> String? {
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
