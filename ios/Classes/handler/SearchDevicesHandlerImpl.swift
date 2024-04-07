//
//  SearchDevicesHandlerImpl.swift
//  lan_scan
//
//  Created by arthur on 2024/4/7.
//

import Foundation
import Flutter

class SearchDevicesHandlerImpl: NSObject, FlutterStreamHandler {
    // Handle events on the main thread.
    private var timer : Timer?
    
    func onListen(withArguments arguments: Any?, eventSink: @escaping FlutterEventSink) -> FlutterError? {
        // 模拟发送Stream数据
        var counter = 0
        self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { timer in
            eventSink(counter)
            counter += 1
            if counter > 10 {
                timer.invalidate() // 当计数器达到10时停止计时器
                eventSink(FlutterEndOfEventStream)
            }
        })
        
        self.timer?.fire()
        
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.timer?.invalidate()
        return nil
    }
}
