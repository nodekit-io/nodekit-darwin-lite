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

import JavaScriptCore

open class NKJSContext: NSObject {
    
    fileprivate let nodeKitTimerKey = "NodeKitTimer"
    
    fileprivate let _jsContext: JSContext
    fileprivate let _id: Int
    
    private var plugins: [String: NKNativePlugin] = [:] //namespace -> plugin
    private var sources: [String: NKScriptSource] = [:] //filename -> source
    
    internal init(_ jsContext: JSContext, id: Int) {
        _jsContext = jsContext
        _id = id
        super.init()
    }
    
    
    internal func prepareEnvironment() -> Void {
        
        
        let logjs: @convention(block) (String, String, [String: AnyObject] ) -> () = { body, severity, labels in
    
            NKLogging.log(body, level: NKLogging.Level(description: severity), labels: labels);
        }
        
        _jsContext.exceptionHandler =  { (ctx: JSContext?, value: JSValue?) in
            NKLogging.log("JavaScript Error");
            // type of String
            let stacktrace = value?.objectForKeyedSubscript("stack").toString() ?? "No stack trace"
            // type of Number
            let lineNumber: Any = value?.objectForKeyedSubscript("line") ?? "Unknown"
            // type of Number
            let column: Any = value?.objectForKeyedSubscript("column") ?? "Unknown"
            let moreInfo = "in method \(stacktrace) Line number: \(lineNumber), column: \(column)"
            
            let errorString = value.map { $0.description } ?? "null"
            
            NKLogging.log("JavaScript Error: \(errorString) \(moreInfo)")
        }
        
        let scriptingBridge = JSValue(newObjectIn: _jsContext)
        
        scriptingBridge?.setObject(unsafeBitCast(logjs, to: AnyObject.self), forKeyedSubscript: "log" as NSString)
        _jsContext.setObject(unsafeBitCast(scriptingBridge, to: AnyObject.self), forKeyedSubscript: "NKScriptingBridge" as NSString)

        let setTimeout: @convention(block) (JSValue, Int) -> () =
            { callback, timeout in
                let timeVal = Int64(Double(timeout) * Double(NSEC_PER_MSEC))
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(timeVal) / Double(NSEC_PER_SEC), execute: { callback.call(withArguments: nil)})
        }
        
        self._jsContext.setObject(unsafeBitCast(setTimeout, to: AnyObject.self), forKeyedSubscript: "setTimeout" as NSString)
        
        let appjs = NKStorage.getResource("lib-scripting.nkar/lib-scripting/init_jsc.js", NKJSContext.self)
        
        let script = "function loadinit(){\n" + appjs! + "\n}\n" + "loadinit();" + "\n"
        
        self.injectJavaScript(NKScriptSource(source: script, asFilename: "io.nodekit.scripting/init_jsc", namespace: "io.nodekit.scripting.init"))
        
        guard let promiseSource = NKStorage.getResource("lib-scripting.nkar/lib-scripting/promise.js", NKJSContext.self) else {
            NKLogging.die("Failed to read provision script: promise")
        }
        
        self.injectJavaScript(
            NKScriptSource(
                source: promiseSource,
                asFilename: "io.nodekit.scripting/NKScripting/promise.js",
                namespace: "Promise"
            )
        )
        
        guard let timerSource = NKStorage.getResource("lib-scripting.nkar/lib-scripting/timer.js", NKJSContext.self) else {
            NKLogging.die("Failed to read provision script: timer")
        }
        
        self.injectJavaScript(
            NKScriptSource(
                source: timerSource,
                asFilename: "io.nodekit.scripting/NKScripting/timer.js",
                namespace: "Timer"
            )
        )
        
        self._jsContext.setObject(NKJSTimer(), forKeyedSubscript: nodeKitTimerKey as NSString)
        
        NKStorage.attachTo(self)
    }
}

extension NKJSContext: NKScriptContext {
    
    public var id: Int {
        get { return self._id }
    }

    public func loadPlugin(_ plugin: NKNativePlugin) -> Void {
    
        self.setObjectForNamespace(plugin, namespace: plugin.namespace)
        
        NKLogging.log("+Plugin object \(plugin) is bound to \(plugin.namespace) with NKScriptingLite (JSExport) channel")
        
        plugins[plugin.namespace] = plugin
        
        guard let jspath: String = plugin.options["js"] as? String else { return; }
        
        guard let js = NKStorage.getResource(jspath, type(of: plugin)) else { return; }
        
        self.injectJavaScript(NKScriptSource(source: js, asFilename: jspath))
    }

    public func injectJavaScript(_ script: NKScriptSource) -> Void {
        
        script.inject(self)
      
        objc_setAssociatedObject(self, Unmanaged.passUnretained(script).toOpaque(), script, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }


    public func evaluateJavaScript(_ javaScriptString: String,
        completionHandler: ((AnyObject?,
        NSError?) -> Void)?) {
        
        let result = self._jsContext.evaluateScript(javaScriptString)
        
        completionHandler?(result, nil)
        
        
    }

    public func serialize(_ object: AnyObject?) -> String {
    
        var obj: AnyObject? = object
        
        if let val = obj as? NSValue {
        
            obj = val as? NSNumber ?? val.nonretainedObjectValue as AnyObject?
       
        }

        
        if let s = obj as? String {
         
            let d = try? JSONSerialization.data(withJSONObject: [s], options: JSONSerialization.WritingOptions(rawValue: 0))
            
            let json = NSString(data: d!, encoding: String.Encoding.utf8.rawValue)!
            
            return json.substring(with: NSMakeRange(1, json.length - 2))
            
        } else if let n = obj as? NSNumber {
            
            if CFGetTypeID(n) == CFBooleanGetTypeID() {
            
                return n.boolValue.description
            
            }
            
            return n.stringValue
        
        } else if let date = obj as? Date {
          
            return "\"\(date.toJSONDate())\""
        
        } else if let _ = obj as? Data {
       
            // TODO: map to Uint8Array object
        
        } else if let a = obj as? [AnyObject] {
        
            return "[" + a.map(self.serialize).joined(separator: ", ") + "]"
       
        } else if let d = obj as? [String: AnyObject] {
        
            return "{" + d.keys.map {"\"\($0)\": \(self.serialize(d[$0]!))"}.joined(separator: ", ") + "}"
        
        } else if obj === NSNull() {
        
            return "null"
       
        } else if obj == nil {
       
            return "undefined"
       
        }
       
        return "'\(obj!)'"
    }
    
    public func stop() -> Void {
        
        if let timer = _jsContext.objectForKeyedSubscript(nodeKitTimerKey).toObject() as? NKJSTimer {
            
            timer.invalidateAll()
        }
    }

    // private methods
    fileprivate func setObjectForNamespace(_ object: AnyObject, namespace: String) -> Void {

        let global = _jsContext.globalObject

        var fullNameArr = namespace.split {$0 == "."}.map(String.init)
        
        let lastItem = fullNameArr.removeLast()
        
        if (fullNameArr.isEmpty) {
        
            _jsContext.setObject(object, forKeyedSubscript: lastItem as NSString)
            
            return
        
        }

        let jsv = fullNameArr.reduce(global, {previous, current in

            if (previous?.hasProperty(current))! {
            
                return previous?.objectForKeyedSubscript(current)
           
            }
            
            let _jsv = JSValue(newObjectIn: _jsContext)
            
            previous?.setObject(_jsv, forKeyedSubscript: current as NSString)
            
            return _jsv
        })
        
        jsv?.setObject(object, forKeyedSubscript: lastItem as NSString)
        
        let selfjsv = (jsv?.objectForKeyedSubscript(lastItem))! as JSValue
        
        objc_setAssociatedObject(object, Unmanaged<AnyObject>.passUnretained(JSValue.self).toOpaque(), selfjsv, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
    }
}

public extension NSObject {
    
    var NKscriptObject: JSValue? {
        
        return objc_getAssociatedObject(self, Unmanaged<AnyObject>.passUnretained(JSValue.self).toOpaque()) as? JSValue
        
    }
    
}
