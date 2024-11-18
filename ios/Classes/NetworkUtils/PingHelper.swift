//
//  PingHelper.swift
//  lan_scan
//
//  Created by arthur on 2024/4/9.
//

import Foundation

class PingHelper: NSObject {
    
    let ipAddress:String
    let timeout:TimeInterval
    
    init(ipAddress: String, timeout: TimeInterval = TimeInterval(3)) {
        self.ipAddress = ipAddress
        self.timeout = timeout
    }
    
    func  start () async  -> Bool {
        var isSuccess:Bool? = try? await withUnsafeThrowingContinuation { cont in
            let pingTool = ICMPPingTool(host: ipAddress, timeout: 1)
            pingTool.startPing { isSuccess in
                cont.resume(returning: isSuccess)
            }
        }
        
        if (isSuccess != true) && (MacFinder.ip2mac(self.ipAddress) != nil){
            isSuccess = true
        }
        return isSuccess == true
    }
    
}
