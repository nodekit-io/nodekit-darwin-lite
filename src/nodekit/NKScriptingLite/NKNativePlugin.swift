//
//  NKNativePlugin.swift
//  NKScriptingLite
//
//  Created by Patrick Goley on 6/7/18.
//  Copyright © 2018 OffGrid Networks. All rights reserved.
//

public protocol NKNativePlugin: AnyObject {
    
    var namespace: String { get }
    
    var options: [String: AnyObject] { get }
}
