//
//  MDNSResolver.swift
//  lan_scan
//
//  Created by arthur on 2024/4/9.
//

import Foundation
import NIOCore
import NIOPosix

class MDNSResolver: Resolver {
    
    let mdnsIP:String = "224.0.0.251"
    let mdnsPort:Int = 5353
    
    private let timeout:TimeAmount
    
    static let group: MultiThreadedEventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount) // 根据核心数设置线程数
    
    init(timeout: TimeAmount) {
        self.timeout = timeout
    }

    
    func resolve(ip: String) async -> String? {
        do {
            let chatMulticastGroup = try SocketAddress(ipAddress: mdnsIP, port: mdnsPort)
            let responsePromise = MDNSResolver.group.next().makePromise(of: String?.self)
            let datagramChannel = try await createDatagramChannel(group:MDNSResolver.group, chatMulticastGroup: chatMulticastGroup,responsePromise: responsePromise)
            
            let timeoutFuture = datagramChannel.eventLoop.scheduleTask(in: timeout) {
                responsePromise.succeed(nil)
            }
            
            try await writeRequest(datagramChannel: datagramChannel, ip: ip, chatMulticastGroup: chatMulticastGroup)
            
            let name = try? await responsePromise.futureResult.get()
            timeoutFuture.cancel()

            try? datagramChannel.close().wait()
            return name
        } catch {
            return nil
        }
    }
    
    private func createDatagramChannel(group: MultiThreadedEventLoopGroup, chatMulticastGroup: SocketAddress,responsePromise: EventLoopPromise<String?>) async throws -> Channel {
        let datagramBootstrap = DatagramBootstrap(group: group)
            .channelOption(ChannelOptions.socket(SOL_SOCKET, SO_REUSEPORT), value: 1)
            .channelOption(ChannelOptions.socket(SOL_SOCKET, SO_REUSEADDR), value: 1)
            .channelOption(ChannelOptions.socket(SOL_SOCKET, SO_BROADCAST), value: 1)
            .channelInitializer { channel in
                return channel.pipeline.addHandler(ChatMessageEncoder()).flatMap {
                    channel.pipeline.addHandler(ChatMessageDecoder(responsePromise: responsePromise))
                }
            }
        let datagramChannel = try await datagramBootstrap
            .bind(host: "0.0.0.0", port: 7654)
            .flatMap { channel -> EventLoopFuture<Channel> in
                let channel = channel as! MulticastChannel
                return channel.joinGroup(chatMulticastGroup).map { channel }
            }.get()
        return datagramChannel
    }
    
    private func writeRequest(datagramChannel: Channel, ip: String, chatMulticastGroup: SocketAddress) async throws {
        if let requestID = calculateRequestID(ip: ip){
            let data = dnsRequest(id: requestID, name: reverseName(name: ip))
            try await datagramChannel.writeAndFlush(AddressedEnvelope(remoteAddress: chatMulticastGroup, data: data, metadata: nil))
        }
    }

}

private final class ChatMessageDecoder: ChannelInboundHandler {
    public typealias InboundIn = AddressedEnvelope<ByteBuffer>
    
    let responsePromise: EventLoopPromise<String?>
    
    init(responsePromise: EventLoopPromise<String?>) {
        self.responsePromise = responsePromise
    }

    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        
        let envelope = self.unwrapInboundIn(data)
        var buffer = envelope.data
        
        guard let responseBytes = buffer.readBytes(length: buffer.readableBytes) else {
            debugPrint("Error: invalid string received")
            return
        }
        guard let ipAddress = envelope.remoteAddress.ipAddress,
              let requestID = calculateRequestID(ip: ipAddress) else{
            return
        }

        let requestBytes = dnsRequest(id: requestID, name: reverseName(name: ipAddress)) //得发送data才能得到回应，这个根据交互方案传值
        if(responseBytes[0] != requestBytes[0]) && (responseBytes[1] != requestBytes[1]){
            return
        }
        
        var offset = requestBytes.count
        if responseBytes[5] == 0{
            offset = 12 + reverseName(name:ipAddress).count
        }
        offset += 2+2+2+4+2
        
        let hostName = decodeName(bytes: responseBytes, offset: offset, length: responseBytes.count-offset)
        
        if let name = hostName?.split(separator: ".").first{
            
            responsePromise.succeed(String(name))
            debugPrint("receive-\(envelope.remoteAddress): \(name)")
        }
    }
}


private final class ChatMessageEncoder: ChannelOutboundHandler {
    public typealias OutboundIn = AddressedEnvelope<Array<UInt8>>
    public typealias OutboundOut = AddressedEnvelope<ByteBuffer>

    func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        let message = self.unwrapOutboundIn(data)
        var buffer = context.channel.allocator.buffer(capacity:message.data.count)
        buffer.writeBytes(message.data)
        context.write(self.wrapOutboundOut(AddressedEnvelope(remoteAddress: message.remoteAddress, data: buffer)), promise: promise)
    }
}


private func calculateRequestID(ip:String ) -> Int?{
    let addrParts = ip.split(separator: ".").compactMap { Int($0) }
    
    guard addrParts.count == 4 else {
        return nil
    }
    let requestID = addrParts[2] * 255 + addrParts[3]
    return requestID
}

private func reverseName(name:String) -> String{
    let addr = name.split(separator: ".")
    return "\(addr[3]).\(addr[2]).\(addr[1]).\(addr[0]).in-addr.arpa"
}

private func dnsRequest(id: Int, name: String) -> [UInt8] {
    var byteArray = [UInt8]()
    
    // ID
    byteArray += [UInt8(id >> 8), UInt8(id & 0xff)]
    
    // Flags
    byteArray += [0, 0, 0, 1, 0, 0, 0, 0, 0, 0]
    
    // Name
    let labels = name.split(separator: ".")
    for label in labels {
        byteArray.append(UInt8(label.count))
        byteArray.append(contentsOf: label.utf8)
    }
    byteArray.append(0) // 最后一个标签以0结尾
    
    // Type (PTR)
    byteArray += [0, 12]
    
    // Class (IN)
    byteArray += [0, 1]
    
    return byteArray
}

private func decodeName( bytes:[UInt8],offset :Int,length :Int) ->String?{
    
    var name:String = ""
    var i = offset
    while i<offset+length{
        let lableCount = Int(bytes[i])
        if lableCount == 0{
            break
        }
        i+=1
        
        if let str = String(bytes: bytes[i..<i+lableCount], encoding: .utf8) {
            name.append("\(str).")
            i += lableCount
        } else {
            break
        }
    }
    
    return name
    
    
}
