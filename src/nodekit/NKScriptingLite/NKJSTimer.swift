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
    
    func setTimeout(callback: JSValue, _ milliseconds: Double) -> String
    
    func setInterval(callback: JSValue, _ milliseconds: Double) -> String
    
    func clearTimeout(identifier: String)
}


@objc class NKJSTimer: NSObject, TimerJSExport {
    
    var timers = [String: NSTimer]()
    var callbacks = [String: JSValue]()
    
    deinit {
        
        timers.forEach({$0.1.invalidate()})
    }
    
    func clearTimeout(identifier: String) {
        
        let timer = timers.removeValueForKey(identifier)
        
        timer?.invalidate()
        
        callbacks.removeValueForKey(identifier)
    }
    
    func setInterval(callback: JSValue, _ milliseconds: Double) -> String {
        
        return createTimer(callback, milliseconds: milliseconds, repeats: true)
    }
    
    func setTimeout(callback: JSValue, _ milliseconds: Double) -> String {
        
        return createTimer(callback, milliseconds: milliseconds , repeats: false)
    }
    
    private func createTimer(callback: JSValue, milliseconds: Double, repeats : Bool) -> String {
        
        let timeInterval  = milliseconds / 1000.0
        
        let uuid = NSUUID().UUIDString
    
        dispatch_async(dispatch_get_main_queue()) {
            
            let userInfo: [String: AnyObject] = [
                "repeats": NSNumber(bool: repeats),
                "uuid": uuid
            ]
            
            self.callbacks[uuid] = callback
            
            let timer = NSTimer.scheduledTimerWithTimeInterval(timeInterval,
                                                               target: self,
                                                               selector: #selector(self.callJsCallback),
                                                               userInfo: userInfo,
                                                               repeats: repeats)
            self.timers[uuid] = timer
        }
        
        return uuid
    }
    
    func callJsCallback(timer: NSTimer) {
        
        guard let userInfo = timer.userInfo,
              let uuid = userInfo["uuid"] as? String,
              let callback = callbacks[uuid],
              let repeats = userInfo["repeats"] as? NSNumber else {
                
            return
        }
        
        callback.callWithArguments([])
        
        if !repeats.boolValue {
            
            clearTimeout(uuid)
        }
    }
}

