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

public protocol NKScriptContext: class {
    
    var id: Int { get }

    func loadPlugin(_ object: NKNativePlugin) -> Void
    
    func injectJavaScript(_ script: NKScriptSource) -> Void
    
    func evaluateJavaScript(_ javaScriptString: String, completionHandler: ((AnyObject?,NSError?) -> Void)?)
    
    func serialize(_ object: AnyObject?) -> String

    func stop() -> Void
}

public protocol NKScriptContextDelegate: class {

    func NKScriptEngineDidLoad(_ context: NKScriptContext) -> Void
    
    func NKScriptEngineReady(_ context: NKScriptContext) -> Void
}

public enum NKScriptExportType: Int {
    
    case nkScriptExport = 0
    
    case jsExport
}

public typealias NKScriptExport = JSExport
