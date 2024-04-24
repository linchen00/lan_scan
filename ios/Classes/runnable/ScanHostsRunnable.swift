//
//  ScanHostsRunnable.swift
//  lan_scan
//
//  Created by arthur on 2024/4/9.
//

import Foundation

class ScanHostsRunnable{
    let start :Int
    let end :Int
    let timeout :TimeInterval
    
    init(start: Int, end: Int, timeout: TimeInterval) {
        self.start = start
        self.end = end
        self.timeout = timeout
    }
    
    func run()async -> [String] {
        var ipList:[String] = []
        
        for i in start...end {
            let ipAddress = self.getIPAddress(index: i)
            let pingHelper =  PingHelper(ip: ipAddress,timeout: self.timeout)
            let isSuccess =  await pingHelper.start()
            if isSuccess {
                ipList.append(ipAddress)
            }
        }
        return ipList
    }
    
    
    func getIPAddress(index: Int) -> String {
        let byte1 = UInt8((index >> 24) & 0xFF)
        let byte2 = UInt8((index >> 16) & 0xFF)
        let byte3 = UInt8((index >> 8) & 0xFF)
        let byte4 = UInt8(index & 0xFF)
        return "\(byte1).\(byte2).\(byte3).\(byte4)"
    }
    
}
