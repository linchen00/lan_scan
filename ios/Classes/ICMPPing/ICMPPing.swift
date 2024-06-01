//
//  ICMPPing.swift
//  lan_scan
//
//  Created by arthur on 2024/5/31.
//

import Foundation

// ICMP Header Structure
struct ICMPHeader {
    var type: UInt8
    var code: UInt8
    var checksum: UInt16
    var identifier: UInt16
    var sequenceNumber: UInt16
}

class ICMPPingTool: NSObject {
    private var timeout: TimeInterval
    private var host: String
    private var completion: ((Bool) -> Void)?
    private var socket: CFSocket?
    private var runLoopSource: CFRunLoopSource?
    private var timeoutWorkItem: DispatchWorkItem?
    private var identifier: UInt16
    private var addressData: Data?
    
    init(host: String, timeout: TimeInterval) {
        self.host = host
        self.timeout = timeout
        self.identifier = Self.generateIdentifier(for: host)
    }
    
    private static func generateIdentifier(for host: String) -> UInt16 {
        let randomPart = UInt16.random(in: 0...UInt16.max)
        let hostHash = UInt16(host.hashValue & 0xFFFF)
        return hostHash ^ randomPart
    }
    
    func startPing(completion: @escaping (Bool) -> Void) {
        self.completion = completion
        
        resolveHost { [weak self] success in
            guard success, let self = self else {
                completion(false)
                return
            }
            DispatchQueue.main.async {
                self.createSocket()
                DispatchQueue.global().async {
                    self.sendPing()
                }
                
            }
            
        }
        
    }
    
    private func resolveHost(hostResolved: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .background).async {
            let unmanagedHost = CFHostCreateWithName(nil, self.host as CFString)
            let hostRef = unmanagedHost.takeRetainedValue()
            
            var resolved: DarwinBoolean = false
            if !CFHostStartInfoResolution(hostRef, .addresses, nil) {
                hostResolved(false)
                return
            }
            
            guard let addresses = CFHostGetAddressing(hostRef, &resolved)?.takeUnretainedValue() as NSArray?,
                  let addressData = addresses.firstObject as? Data else {
                hostResolved(false)
                return
            }
            self.addressData = addressData
            hostResolved(true)
        }
    }
    
    private func createSocket() {
        var context = CFSocketContext(version: 0, info: UnsafeMutableRawPointer(Unmanaged.passRetained(self).toOpaque()), retain: nil, release: nil, copyDescription: nil)
        self.socket = CFSocketCreate(nil, PF_INET, SOCK_DGRAM, IPPROTO_ICMP, CFSocketCallBackType.dataCallBack.rawValue, { (socket, type, address, data, info) in
            
            guard let info = info else { return }
            let icmpTool = Unmanaged<ICMPPingTool>.fromOpaque(info).takeUnretainedValue()
            
            guard let data = data else { return }
            let icmpData = Unmanaged<CFData>.fromOpaque(data).takeUnretainedValue() as Data
            
            let icmpDataStartIndex = 20
            guard icmpData.count >= icmpDataStartIndex + MemoryLayout<ICMPHeader>.size else { return  }
            
            let icmpHeader = icmpData[icmpDataStartIndex..<icmpDataStartIndex + MemoryLayout<ICMPHeader>.size]
            
            icmpHeader.withUnsafeBytes { pointer in
                let header = pointer.baseAddress!.assumingMemoryBound(to: ICMPHeader.self).pointee
                guard header.identifier == icmpTool.identifier else { return }
                icmpTool.handleSocketData(socket: socket, type: type, address: address, data: data)
            }
        }, &context)
        
        guard let socket = self.socket else {
            completion?(false)
            return
        }
        
        CFSocketSetSocketFlags(socket, CFOptionFlags(kCFSocketAutomaticallyReenableDataCallBack))
        self.runLoopSource = CFSocketCreateRunLoopSource(nil, socket, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), self.runLoopSource, .defaultMode)
    }
    
    private func sendPing() {
        guard let addressData = self.addressData else {
            completion?(false)
            return
        }
        
        var socketAddress = sockaddr_in()
        addressData.withUnsafeBytes { (rawBufferPointer: UnsafeRawBufferPointer) in
            if let baseAddress = rawBufferPointer.baseAddress, rawBufferPointer.count >= MemoryLayout<sockaddr_in>.size {
                socketAddress = baseAddress.bindMemory(to: sockaddr_in.self, capacity: 1).pointee
            }
        }
        
        let packet = createICMPPacket()
        sendICMPPacket(packet, to: &socketAddress)
        
        let timeoutWorkItem = DispatchWorkItem { [weak self] in
            self?.completion?(false)
            self?.stopPing()
            
        }
        
        self.timeoutWorkItem = timeoutWorkItem
        DispatchQueue.global().asyncAfter(deadline: .now() + timeout, execute: timeoutWorkItem)
    }
    
    private func createICMPPacket() -> Data {
        var icmpHeader = ICMPHeader(type: 8, code: 0, checksum: 0, identifier: self.identifier, sequenceNumber: 0)
        
        var packet = Data(bytes: &icmpHeader, count: MemoryLayout<ICMPHeader>.size)
        let checksum = calculateChecksum(packet)
        
        icmpHeader.checksum = checksum
        packet = Data(bytes: &icmpHeader, count: MemoryLayout<ICMPHeader>.size)
        return packet
    }
    
    private func calculateChecksum(_ data: Data) -> UInt16 {
        var sum: UInt32 = 0
        data.withUnsafeBytes { (rawBufferPointer: UnsafeRawBufferPointer) in
            let bufferPointer = rawBufferPointer.bindMemory(to: UInt16.self)
            for word in bufferPointer {
                sum += UInt32(word)
            }
        }
        
        sum = (sum >> 16) + (sum & 0xFFFF)
        sum += (sum >> 16)
        
        return ~UInt16(sum & 0xFFFF)
    }
    
    private func sendICMPPacket(_ packet: Data, to address: inout sockaddr_in) {
        let addressData = Data(bytes: &address, count: MemoryLayout<sockaddr_in>.size)
        addressData.withUnsafeBytes { (rawBufferPointer: UnsafeRawBufferPointer) in
            if rawBufferPointer.baseAddress != nil {
                _ = CFSocketSendData(socket, addressData as CFData, packet as CFData, timeout)
            }
        }
    }
    
    private func handleSocketData(socket: CFSocket!, type: CFSocketCallBackType, address: CFData!, data: UnsafeRawPointer!) {
        timeoutWorkItem?.cancel()
        completion?(true)
        stopPing()
    }
    
    private func stopPing() {
        if let socket = self.socket {
            CFSocketInvalidate(socket)
            self.socket = nil
        }
        if let runLoopSource = self.runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .defaultMode)
            self.runLoopSource = nil
        }
    }
}
