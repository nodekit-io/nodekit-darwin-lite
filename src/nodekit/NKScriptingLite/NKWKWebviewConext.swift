//
//  NKWKWebviewConext.swift
//  NKScriptingLite
//
//  Created by Patrick Goley on 2/7/19.
//  Copyright © 2019 OffGrid Networks. All rights reserved.
//

import WebKit

extension WKWebView: NKScriptContextHost {
    
    public func NKcreateScriptContext(_ id: Int, options: [String: AnyObject] = Dictionary<String, AnyObject>(), delegate cb: NKScriptContextDelegate) -> Void {
        
        let context = NKWKWebViewContext(id: id)
        
        NKLogging.log("+NodeKit JavaScriptCore JavaScript Engine Lite E\(id)")
        
        cb.NKScriptEngineDidLoad(context)
        
        cb.NKScriptEngineReady(context)
    }
}

final class NKWKWebViewContext: NKScriptContext {
    
    let id: Int
    let webView: WKWebView
    
    var plugins: [String: NKNativePlugin] = [:] //namespace -> plugin
    
    var sources: [String: NKScriptSource] = [:] //filename -> source
    
    init(id: Int) {
        self.id = id
        self.webView = WKWebView(frame: .zero)
    }
    
    func loadPlugin(_ plugin: NKNativePlugin) {
        
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
    
    func evaluateJavaScript(_ javaScriptString: String, completionHandler: ((Any?, NSError?) -> Void)?) {
        
        webView.evaluateJavaScript(javaScriptString) { (result, err) in
            
            if let err = err {
                
                let errMessage = """
                Error evaluating Javascript: \(err)
                Source:
                \(javaScriptString)
                """
                
                NKLogging.log(errMessage, level: .error)
                
                let error = NSError.invalidJavaScriptError(err, source: javaScriptString)
                
                completionHandler?(result, error)
                
            } else {
                
                completionHandler?(result, nil)
            }
        }
    }
    
    func setObjectForNamespace(_ object: AnyObject, namespace: String) -> JSValue? {
        
        #error("Can't return JSValue from WKWebView, need NKScriptValue")
    }
}
