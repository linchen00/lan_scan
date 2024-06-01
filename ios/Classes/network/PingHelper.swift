//
//  PingHelper.swift
//  lan_scan
//
//  Created by arthur on 2024/4/9.
//

import Foundation

class PingHelper: NSObject {
    
    let ip:String
    let timeout:TimeInterval
    
    init(ip: String, timeout: TimeInterval = TimeInterval(3)) {
        self.ip = ip
        self.timeout = timeout
    }
    
    func  start () async  -> Bool {
        var isSuccess:Bool? = try? await withUnsafeThrowingContinuation { cont in
            let pingTool = ICMPPingTool(host: ip, timeout: 1)
            pingTool.startPing { isSuccess in
                cont.resume(returning: isSuccess)
            }
        }
        
        if (isSuccess != true) && (MacFinder.ip2mac(self.ip) != nil){
            isSuccess = true
        }
        return isSuccess == true
    }
    
}
