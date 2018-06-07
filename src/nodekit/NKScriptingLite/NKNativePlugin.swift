//
//  NKNativePlugin.swift
//  NKScriptingLite
//
//  Created by Patrick Goley on 6/7/18.
//  Copyright © 2018 OffGrid Networks. All rights reserved.
//

import JavaScriptCore

/*
 A native object that will be registered under global[namespace] and
 callable from JavaScript.
 Options can include a JavaScript source file to be loaded like so:
 ["js": "path/to/file.js" as NSString]
 */
@objc public protocol NKNativePlugin: AnyObject {
    
    var namespace: String { get }
    
    var options: [String: AnyObject] { get }
}

/*
 A native object that can proxy native method calls to it's cooresponding
 JSValue. This property will be nil after the NKScriptContext is disposed
 to break any retain cycles.
 */
@objc public protocol NKNativeProxy: AnyObject {
    
    var nkScriptObject: JSValue? { get set }
}
