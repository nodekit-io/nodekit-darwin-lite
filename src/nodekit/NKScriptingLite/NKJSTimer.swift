/*
 * nodekit.io
 *
 * Copyright (c) 2016 OffGrid Networks. All Rights Reserved.
 * Portions Copyright 2015 XWebView
 * Portions Copyright (c) 2014 Intel Corporation.  All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Foundation
import JavaScriptCore


@objc protocol TimerJSExport: JSExport {
    
    func setTimeout(_ callback: JSValue, _ milliseconds: Double) -> String
    
    func setInterval(_ callback: JSValue, _ milliseconds: Double) -> String
    
    func clearTimeout(_ identifier: String)
}


@objc class NKJSTimer: NSObject, TimerJSExport, NKNativePlugin, NKDisposable {
    
    public let namespace: String = "NodeKitTimer"
    public let sourceJS: String? = "lib-scripting.nkar/lib-scripting/timer.js"
    private let queue = DispatchQueue(label: "NSJSTimerQueue", attributes: [])

    var timers = [String: Timer]()
    var callbacks = [String: JSValue]()
    
    func clearTimeout(_ identifier: String) {
        queue.sync {
            _clearTimeout(identifier)
        }
    }
    
    func setInterval(_ callback: JSValue, _ milliseconds: Double) -> String {
        
        return createTimer(callback, milliseconds: milliseconds, repeats: true)
    }
    
    func setTimeout(_ callback: JSValue, _ milliseconds: Double) -> String {
        
        return createTimer(callback, milliseconds: milliseconds , repeats: false)
    }
    
    func dispose() {
        
        queue.sync {
            timers.forEach({$0.1.invalidate()})
            timers.removeAll()
            callbacks.removeAll()
        }
    }
    
    fileprivate func createTimer(_ callback: JSValue, milliseconds: Double, repeats : Bool) -> String {
        
        return queue.sync {
            
            let timeInterval  = milliseconds / 1000.0
            
            let uuid = UUID().uuidString
            
            let userInfo: [String: AnyObject] = [
                "repeats": NSNumber(value: repeats as Bool),
                "uuid": uuid as AnyObject
            ]
            
            self.callbacks[uuid] = callback
            
            let timer = Timer.scheduledTimer(timeInterval: timeInterval,
                                             target: self,
                                             selector: #selector(self.callJsCallback),
                                             userInfo: userInfo,
                                             repeats: repeats)
            
            self.timers[uuid] = timer
            
            return uuid
        }
    }
    
    @objc func callJsCallback(_ timer: Timer) {
        
        var callback: JSValue?
        
        queue.sync {

            guard let userInfo = timer.userInfo as? [String: AnyObject],
                  let uuid = userInfo["uuid"] as? String,
                  let cb = callbacks[uuid],
                  let repeats = userInfo["repeats"] as? NSNumber else {
                    
                return
            }
            
            if !repeats.boolValue {
                
                _clearTimeout(uuid)
            }
            
            callback = cb
        }
        
        // Important that the callback is invoked outside of the serial queue
        // otherwise nested calls to setTimeout will deadlock or crash
        callback?.call(withArguments: [])
    }
    
    private func _clearTimeout(_ identifier: String) {
        
        let timer = timers.removeValue(forKey: identifier)
        
        timer?.invalidate()
        
        callbacks.removeValue(forKey: identifier)
    }
}

