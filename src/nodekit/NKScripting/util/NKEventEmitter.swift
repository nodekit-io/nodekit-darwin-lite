/*
* nodekit.io
*
* Copyright (c) 2016 OffGrid Networks. All Rights Reserved.
* Portions Copyright (c) 2013 GitHub, Inc. under MIT License
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

/*
* NKEventEmitter:  A very basic type safe event emitter for Swift
*
* USAGE
* let emitter = NKEventEmitter()
* let subscription = emitter.on<String>("ready", { print("received ready event: \($0)") })
* emitter.emit<String>("ready", "now")
* subscription.remove()
*/

// Static variables (class variables not allowed for generics)
private var seq: Int = 1

public protocol NKEventSubscription {
 
    func remove()

}

open class NKEventSubscriptionGeneric<T>: NKEventSubscription {

   public typealias NKHandler = (T) -> Void

    let handler: NKHandler

    fileprivate let emitter: NKEventEmitter

    fileprivate let eventType: String
    
    fileprivate let id: Int

    public init(emitter: NKEventEmitter, eventType: String,  handler: @escaping NKHandler) {
    
        id = seq
        
        seq += 1
        
        self.eventType = eventType
        
        self.emitter = emitter
        
        self.handler = handler
    }

    open func remove() {
    
        _ = emitter.subscriptions[eventType]?.removeValue(forKey: id)
    }
}

open class NKEventEmitter: NSObject {

    // global EventEmitter that is actually a signal emitter (retains early triggers without subscriptions until once is called)
    open static var global: NKEventEmitter = NKSignalEmitter()

    fileprivate var currentSubscription: NKEventSubscription?

    fileprivate var subscriptions: [String: [Int:NKEventSubscription]] = [:]

    open func on<T>(_ eventType: String, handler: @escaping (T) -> Void) -> NKEventSubscription {
    
        var eventSubscriptions: [Int:NKEventSubscription]

        if let values = subscriptions[eventType] {
        
            eventSubscriptions = values
       
        } else {
        
            eventSubscriptions = [:]
        
        }

        let subscription = NKEventSubscriptionGeneric<T>(
        
            emitter: self,
            
            eventType: eventType,
            
            handler: handler
        
        )

        eventSubscriptions[subscription.id] = subscription
        
        subscriptions[eventType] = eventSubscriptions
       
        return subscription
    }

    open func once<T>(_ event: String, handler: @escaping (T) -> Void) {
        
        _ = on(event) { (data: T) -> Void in
        
            self.currentSubscription?.remove()
            
            handler(data)
        
        }
    
    }

    open func removeAllListeners(_ eventType: String?) {
    
        if let eventType = eventType {
        
            subscriptions.removeValue(forKey: eventType)
      
        } else {
        
            subscriptions.removeAll()
       
        }
    
    }

    open func emit<T>(_ event: String, _ data: T) {
    
        if let subscriptions = subscriptions[event] {
        
            for (_, subscription) in subscriptions {
            
                currentSubscription = subscription
                
                (subscription as! NKEventSubscriptionGeneric<T>).handler(data)
            
            }
        
        }
    
    }

}

private class NKSignalEmitter: NKEventEmitter {
    
    fileprivate var earlyTriggers: [String: Any] = [:]
    
    override func once<T>(_ event: String, handler: @escaping (T) -> Void) {

        let registerBlock = { () -> Void in
        
            if let data = self.earlyTriggers[event] {
            
                self.earlyTriggers.removeValue(forKey: event)
                
                handler(data as! T)
                
                return
            
            }
            
            _ = self.on(event) { (data: T) -> Void in
            
                self.currentSubscription?.remove()
                
                handler(data)
            
            }
        
        }
        
        if (Thread.isMainThread) {
        
            registerBlock()
       
        } else {
        
            DispatchQueue.main.async(execute: registerBlock)
        
        }
    
    }
    
    override func emit<T>(_ event: String, _ data: T) {
    
        let triggerBlock = { () -> Void in
        
            if let subscriptions = self.subscriptions[event] {
            
                for (_, subscription) in subscriptions {
                
                    (subscription as! NKEventSubscriptionGeneric<T>).handler(data)
                
                }
           
            } else {
            
                self.earlyTriggers[event] = data
            
            }
        
        }
        
        if (Thread.isMainThread) {
        
            triggerBlock()
        
        } else {
        
            DispatchQueue.main.async(execute: triggerBlock)
        
        }
    
    }

}
