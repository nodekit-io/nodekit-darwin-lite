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
        
        guard let _ = NKStorage.getResource("lib-scripting.nkar/lib-scripting/timer.js", NKJSContext.self) else {
            NKLogging.die("Failed to read provision script: timer")
        }
        
        loadPlugin(NKJSTimer())
        
        let scriptingBridge = JSValue(newObjectIn: _jsContext)
        
        scriptingBridge?.setObject(logjs as AnyObject, forKeyedSubscript: "log" as NSString)
        _jsContext.setObject(scriptingBridge, forKeyedSubscript: "NKScriptingBridge" as NSString)
        
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
        
        NKStorage.attachTo(self)
    }
}

extension NKJSContext: NKScriptContext {
    
    public var id: Int {
        get { return self._id }
    }

    public func loadPlugin(_ plugin: NKNativePlugin) -> Void {
    
        if let jsValue = setObjectForNamespace(plugin, namespace: plugin.namespace),
            let proxy = plugin as? NKNativeProxy {
            proxy.nkScriptObject = jsValue
        }
        
        NKLogging.log("+Plugin object \(plugin) is bound to \(plugin.namespace) with NKScriptingLite (JSExport) channel")
        
        plugins[plugin.namespace] = plugin
        
        guard let jspath: String = plugin.sourceJS else { return }
        
        guard let js = NKStorage.getResource(jspath, type(of: plugin)) else { return }
        
        self.injectJavaScript(
            NKScriptSource(
                source: js,
                asFilename: jspath,
                namespace: plugin.namespace
            )
        )
    }

    public func injectJavaScript(_ script: NKScriptSource) -> Void {
        
        script.inject(self)
      
        sources[script.filename] = script
    }

    public func evaluateJavaScript(_ javaScriptString: String,
        completionHandler: ((AnyObject?,
        NSError?) -> Void)?) {
        
        let result = self._jsContext.evaluateScript(javaScriptString)
        
        completionHandler?(result, nil)
    }
    
    public func stop() -> Void {
        
        for plugin in plugins.values {
            if let proxy = plugin as? NKNativeProxy {
                proxy.nkScriptObject = nil
            }
            if let disposable = plugin as? NKDisposable {
                disposable.dispose()
            }
        }

        for script in sources.values {
            script.eject()
        }

        plugins.removeAll()
        sources.removeAll()
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

    // private methods
    fileprivate func setObjectForNamespace(_ object: AnyObject, namespace: String) -> JSValue? {

        let global = _jsContext.globalObject

        var fullNameArr = namespace.split {$0 == "."}.map(String.init)
        
        let lastItem = fullNameArr.removeLast()
        
        if (fullNameArr.isEmpty) {
        
            _jsContext.setObject(object, forKeyedSubscript: lastItem as NSString)
            
            return nil
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
        
        return selfjsv
    }
}
