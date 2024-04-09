//
//  HostsScanError.swift
//  lan_scan
//
//  Created by arthur on 2024/4/9.
//

import Foundation

enum HostsScanError: String {
    // 枚举成员，每个成员都有一个关联的描述信息
    case notAvailable = "1"
    case notConnected = "2"

    // 计算属性，用于获取描述信息
    var description: String {
        switch self {
        case .notAvailable:
            return "Wi-Fi is not available"
        case .notConnected:
            return "Wi-Fi is not connected"
        }
    }
}
