//
//  ScanHostsAsynsTask.swift
//  lan_scan
//
//  Created by arthur on 2024/4/9.
//

import Foundation
import Flutter

class ScanHostsAsyncTask{
    
    let eventSink:FlutterEventSink
    
    init(eventSink:@escaping  FlutterEventSink) {
        self.eventSink = eventSink
    }
    
    func scanHosts(ipv4:Int,cidrPrefixLength:Int,timeout:Int) async{
        
        let hostBits = 32.0 - Double(cidrPrefixLength)
        let netmask = (0xFFFFFFFF >> (32 - cidrPrefixLength)) << (32 - cidrPrefixLength)
        let numberOfHosts = pow(2.0, hostBits) - 2
        let firstAddr = (ipv4 & netmask) + 1
        
        let scanThreads = hostBits
        let chunk = Int(ceil(numberOfHosts / scanThreads))
        var previousStart = firstAddr
        var previousStop = firstAddr + (chunk - 2)
        
        let ipList =  await withTaskGroup(of: [String].self, returning: [String].self) { taskGroup in
            for _ in 0..<Int(scanThreads){
                let start =  previousStart
                let stop =  previousStop
                taskGroup.addTask {
                    let scanHostsRunnable = ScanHostsRunnable(start: start, stop: stop, timeout: TimeInterval(1))
                    let results = await scanHostsRunnable.run()
                    return results
                }
                
                previousStart = stop+1
                previousStop = previousStart+(chunk-1)
            }
            
            var ipList:[String] = []
        
            
            for await taskResult in taskGroup {
                ipList.append(contentsOf: taskResult)
            }
            
            return ipList
        }
        
        await withTaskGroup(of: Void.self) { taskGroup in
            for ip in ipList{
                
                taskGroup.addTask {
                    var host = Host(ip: ip)
                    let mdnsResolver = MDNSResolver(timeout: TimeInterval(5))
                    let netBIOSResolver = NetBIOSResolver()
                    
                    if let hostname = self.getHostName(for: host.ip){
                        host.hostname = hostname
                    } else if let hostname = await mdnsResolver.resolve(ip: ip){
                        host.hostname = hostname
                    }else if let hostname = netBIOSResolver.resolve(ip: ip){
                        host.hostname = hostname
                    }

                    // 将 JSON 数据转换为字符串输出
                    if let jsonData = try? JSONEncoder().encode(host),
                       let jsonString = String(data: jsonData, encoding: .utf8) {
                        self.eventSink(jsonString)
                        
                    }
                }
                
            }
           await taskGroup.waitForAll()
        }
        
        eventSink(FlutterEndOfEventStream)
        
        print("finish")
        
    }
    
    func getHostName(for ipAddress: String) -> String? {
            // 将 IP 地址转换为 C 字符串
            let cIpAddress = ipAddress.cString(using: .utf8)

            // 将 C 字符串转换为 in_addr 结构体
            var addr = in_addr()
            if let cIpAddress = cIpAddress {
                inet_aton(cIpAddress, &addr)
            } else {
                return nil
            }

            // 通过 IP 地址获取主机名
            guard let host = gethostbyaddr(&addr, socklen_t(MemoryLayout<in_addr>.size), AF_INET),
                  let hostnamePtr = host.pointee.h_name else {
                return nil
            }

            // 从返回的 host 结构体中获取主机名

            return String(cString: hostnamePtr)
        }
    
}
