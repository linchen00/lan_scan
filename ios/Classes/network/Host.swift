//
//  Host.swift
//  lan_scan
//
//  Created by arthur on 2024/4/9.
//

import Foundation

struct Host : Codable {
    var ip:String
    var mac:String?
    var hostname:String? {
        didSet {
            if let newHostname = hostname,newHostname.isEmpty || newHostname.hasSuffix(".local"){
                self.hostname = String(newHostname.prefix(newHostname.count-6))
            }
        }
    }
    
    init(ip: String, mac: String? = nil, hostname: String? = nil) {
        self.ip = ip
        self.mac = mac
        self.hostname = hostname
    }
    
    
}
