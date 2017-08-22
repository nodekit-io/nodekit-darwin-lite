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

public class NKJSContext: NSObject {
    
    private let nodeKitTimerKey = "NodeKitTimer"
    
    private let _jsContext: JSContext
    private let _id: Int
    
    internal init(_ jsContext: JSContext, id: Int) {
        _jsContext = jsContext
        _id = id
        super.init()
    }
    
    
    internal func prepareEnvironment() -> Void {
        
        
        let logjs: @convention(block) (String, String, [String: AnyObject] ) -> () = { body, severity, labels in
    
            NKLogging.log(body, level: NKLogging.Level(description: severity), labels: labels);
        }
        
        _jsContext.exceptionHandler =  { (ctx: JSContext!, value: JSValue!) in
            NKLogging.log("JavaScript Error");
            // type of String
            let stacktrace = value.objectForKeyedSubscript("stack").toString()
            // type of Number
            let lineNumber = value.objectForKeyedSubscript("line")
            // type of Number
            let column = value.objectForKeyedSubscript("column")
            let moreInfo = "in method \(stacktrace) Line number: \(lineNumber), column: \(column)"
            
            NKLogging.log("JavaScript Error: \(value) \(moreInfo)")
        }
        
        _jsContext.exceptionHandler =  { (ctx: JSContext!, value: JSValue!) in
            // type of String
            let stacktrace = value.objectForKeyedSubscript("stack").toString()
            // type of Number
            let lineNumber = value.objectForKeyedSubscript("line")
            // type of Number
            let column = value.objectForKeyedSubscript("column")
            let moreInfo = "in method \(stacktrace) Line number: \(lineNumber), column: \(column)"
            
            NKLogging.log("JavaScript Error: \(value) \(moreInfo)")
        }
        
        let scriptingBridge = JSValue(newObjectInContext: _jsContext)
        
        scriptingBridge.setObject(unsafeBitCast(logjs, AnyObject.self), forKeyedSubscript: "log")
        _jsContext.setObject(unsafeBitCast(scriptingBridge, AnyObject.self), forKeyedSubscript: "NKScriptingBridge")

        let setTimeout: @convention(block) (JSValue, Int) -> () =
            { callback, timeout in
                let timeVal = Int64(Double(timeout) * Double(NSEC_PER_MSEC))
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, timeVal), dispatch_get_main_queue(), { callback.callWithArguments(nil)})
        }
        
        self._jsContext.setObject(unsafeBitCast(setTimeout, AnyObject.self), forKeyedSubscript: "setTimeout")
        
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
        
        self._jsContext.setObject(NKJSTimer(), forKeyedSubscript: nodeKitTimerKey)
        
        NKStorage.attachTo(self)
    }
}

extension NKJSContext: NKScriptContext {
    
    public var id: Int {
        get { return self._id }
    }

    public func loadPlugin(object: AnyObject, namespace: String, options: Dictionary<String, AnyObject> = Dictionary<String, AnyObject>() ) -> Void {
    
        self.setObjectForNamespace(object, namespace: namespace)
        
        NKLogging.log("+Plugin object \(object) is bound to \(namespace) with NKScriptingLite (JSExport) channel")
        
        objc_setAssociatedObject(self, unsafeAddressOf(object), object, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        guard let jspath: String = options["js"] as? String else { return; }
        
        guard let js = NKStorage.getResource(jspath, object.dynamicType) else { return; }
        
        self.injectJavaScript(NKScriptSource(source: js, asFilename: jspath))

    }

    public func injectJavaScript(script: NKScriptSource) -> Void {
        
        script.inject(self)
      
        objc_setAssociatedObject(self, unsafeAddressOf(script), script, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
    }


    public func evaluateJavaScript(javaScriptString: String,
        completionHandler: ((AnyObject?,
        NSError?) -> Void)?) {
        
        let result = self._jsContext.evaluateScript(javaScriptString)
        
        completionHandler?(result, nil)
        
        
    }

    public func serialize(object: AnyObject?) -> String {
    
        var obj: AnyObject? = object
        
        if let val = obj as? NSValue {
        
            obj = val as? NSNumber ?? val.nonretainedObjectValue
       
        }

        
        if let s = obj as? String {
         
            let d = try? NSJSONSerialization.dataWithJSONObject([s], options: NSJSONWritingOptions(rawValue: 0))
            
            let json = NSString(data: d!, encoding: NSUTF8StringEncoding)!
            
            return json.substringWithRange(NSMakeRange(1, json.length - 2))
            
        } else if let n = obj as? NSNumber {
            
            if CFGetTypeID(n) == CFBooleanGetTypeID() {
            
                return n.boolValue.description
            
            }
            
            return n.stringValue
        
        } else if let date = obj as? NSDate {
          
            return "\"\(date.toJSONDate())\""
        
        } else if let _ = obj as? NSData {
       
            // TODO: map to Uint8Array object
        
        } else if let a = obj as? [AnyObject] {
        
            return "[" + a.map(self.serialize).joinWithSeparator(", ") + "]"
       
        } else if let d = obj as? [String: AnyObject] {
        
            return "{" + d.keys.map {"\"\($0)\": \(self.serialize(d[$0]!))"}.joinWithSeparator(", ") + "}"
        
        } else if obj === NSNull() {
        
            return "null"
       
        } else if obj == nil {
       
            return "undefined"
       
        }
       
        return "'\(obj!.description)'"
    }
    
    public func stop() -> Void {
        
        if let timer = _jsContext.objectForKeyedSubscript(nodeKitTimerKey).toObject() as? NKJSTimer {
            
            timer.invalidateAll()
        }
    }

    // private methods
    private func setObjectForNamespace(object: AnyObject, namespace: String) -> Void {

        let global = _jsContext.globalObject

        var fullNameArr = namespace.characters.split {$0 == "."}.map(String.init)
        
        let lastItem = fullNameArr.removeLast()
        
        if (fullNameArr.isEmpty) {
        
            _jsContext.setObject(object, forKeyedSubscript: lastItem)
            
            return
        
        }

        let jsv = fullNameArr.reduce(global, combine: {previous, current in

            if (previous.hasProperty(current)) {
            
                return previous.objectForKeyedSubscript(current)
           
            }
            
            let _jsv = JSValue(newObjectInContext: _jsContext)
            
            previous.setObject(_jsv, forKeyedSubscript: current)
            
            return _jsv
        })
        
        jsv.setObject(object, forKeyedSubscript: lastItem)
        
        let selfjsv = jsv.objectForKeyedSubscript(lastItem) as JSValue
        
        objc_setAssociatedObject(object, unsafeAddressOf(JSValue), selfjsv, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
    }
}

public extension NSObject {
    
    var NKscriptObject: JSValue? {
        
        return objc_getAssociatedObject(self, unsafeAddressOf(JSValue)) as? JSValue
        
    }
    
}
