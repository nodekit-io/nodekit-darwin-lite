/*
* nodekit.io
*
* Copyright (c) 2016 OffGrid Networks. All Rights Reserved.
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

public enum NKEngineType: Int {
 
    case javaScriptCore  = 0
    
    case nitro = 1
    
    case uiWebView = 2
}

open class NKScriptContextFactory: NSObject {

    internal static var _contexts: Dictionary<Int, AnyObject> = Dictionary<Int, AnyObject>()

    open class var sequenceNumber: Int {

        struct sequence {
        
            static var number: Int = 0
        
        }
       
        let temp = sequence.number
       
        sequence.number += 1
       
        return temp
    
    }

    open func createScriptContext(_ options: [String: AnyObject] = Dictionary<String, AnyObject>(), delegate cb: NKScriptContextDelegate) {
    
        let engine = NKEngineType(rawValue: (options["Engine"] as? Int)!) ?? NKEngineType.javaScriptCore

        switch engine {
        
        case .javaScriptCore:
        
            self.createContextJavaScriptCore(options, delegate: cb)
         
        case .nitro:
        
            NKLogging.log("Nitro Not Implemented in NKScriptingLite")
            
        case .uiWebView:
        
            NKLogging.log("UIWebView JSC Not Implemented in NKScriptingLite")
            
        }
    
    }
    
    public static var defaultQueue: DispatchQueue = {
        
        let label = "io.nodekit.scripting.default-queue"
        
        return DispatchQueue(label: label, attributes: [])
        
    }()

}


public protocol NKScriptContextHost: class {
    
    func NKcreateScriptContext(_ id: Int, options: [String: AnyObject], delegate cb: NKScriptContextDelegate) -> Void
    
}
