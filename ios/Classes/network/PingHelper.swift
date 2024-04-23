//
//  PingHelper.swift
//  lan_scan
//
//  Created by arthur on 2024/4/9.
//

import Foundation
import MacFinder

class PingHelper: NSObject, GBPingDelegate {
    
    let ip:String
    let timeout:TimeInterval
    private var continuation: UnsafeContinuation<Bool?, any Error>?
    var hadReceivedValue:Bool = false
    
    init(ip: String, timeout: TimeInterval = TimeInterval(3)) {
        self.ip = ip
        self.timeout = timeout
    }
    
    private lazy var ping: GBPing = {
        let ping = GBPing()
        ping.host = self.ip
        ping.timeout = self.timeout
        ping.delegate = self
        return ping
    }()
    
    func  start () async  -> Bool {
        guard (try? await ping.setup()) != nil else{
            return false
        }
        
        var isSuccess:Bool? = try? await withUnsafeThrowingContinuation { cont in
            self.ping.startPinging()
            continuation = cont
        }
        self.ping.stop()
        
        if (isSuccess != true) && (MacFinder.ip2mac(self.ip) != nil){
            isSuccess = true
        }
        return isSuccess==true
    }
    
    func ping(_ pinger: GBPing, didSendPingWith summary: GBPingSummary) {
        debugPrint("didSendPingWith:summary-\(summary)")
    }
    
    func ping(_ pinger: GBPing, didTimeoutWith summary: GBPingSummary) {
        if !hadReceivedValue {
            hadReceivedValue = true
            continuation?.resume(returning: false)
            debugPrint("didTimeoutWith:summary-\(summary)")
        }

    }
    
    func ping(_ pinger: GBPing, didFailToSendPingWith summary: GBPingSummary, error: any Error) {
        if !hadReceivedValue {
            hadReceivedValue = true
            continuation?.resume(returning: false)
            debugPrint("didFailToSendPingWith:summary-\(summary)")
        }
    }
    
    func ping(_ pinger: GBPing, didFailWithError error: any Error) {
        if !hadReceivedValue {
            hadReceivedValue = true
            continuation?.resume(returning: false)
            debugPrint("didFailWithError")
        }
    }
    
    func ping(_ pinger: GBPing, didReceiveReplyWith summary: GBPingSummary) {
        if !hadReceivedValue {
            hadReceivedValue = true
            continuation?.resume(returning: true)
            debugPrint("didReceiveReplyWith:summary-\(summary)")
        }
    }
    
    func ping(_ pinger: GBPing, didReceiveUnexpectedReplyWith summary: GBPingSummary) {
        if !hadReceivedValue {
            hadReceivedValue = true
            continuation?.resume(returning: true)
            debugPrint("didReceiveUnexpectedReplyWith:summary-\(summary)")
        }
    }
}
