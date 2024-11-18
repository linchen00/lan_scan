//
//  NetBIOSResolver.swift
//  lan_scan
//
//  Created by arthur on 2024/4/9.
//

import Foundation
import TOSMBClient

class NetBIOSResolver:Resolver {
    
    func resolve(ip: String) -> String? {
        let netBIOSNameService = TONetBIOSNameService()
        return netBIOSNameService.lookupNetworkName(forIPAddress: ip)
    }

}
