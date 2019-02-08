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

import JavaScriptCore

/*
 A native object that will be registered under global[namespace] and
 callable from JavaScript.
 The path to a cooresponding JavaScript file can be supplied under sourceJS
 if needed. This file will be evaluated after the plugin is loaded.
 */
@objc public protocol NKNativePlugin: AnyObject {
    
    var namespace: String { get }
    
    var sourceJS: String? { get }
}

/*
 A native object that can proxy native method calls to or otherwise manipulate
 it's cooresponding JSValue. This property will become nil after the NKScriptContext
 is disposed to break any retain cycles.
 */
@objc public protocol NKNativeProxy: AnyObject {
    
    var nkScriptObject: JSValue? { get set }
    
    #error("NKNative proxy needs a reference to it's JSValue, needs to be updated to NKScriptValue")
}
