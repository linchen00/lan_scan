//
//  Resolver.swift
//  lan_scan
//
//  Created by arthur on 2024/4/9.
//

import Foundation

protocol Resolver {
    func resolve(ip:String)async -> String?
}
