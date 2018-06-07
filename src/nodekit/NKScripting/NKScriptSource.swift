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

open class NKScriptSource: NSObject {

    open let source: String

    open let cleanup: String?
    
    open let filename: String
    
    open let namespace: String?
    
    open var context: NKScriptContext?
    
    public init(source: String, asFilename: String, namespace: String? = nil, cleanup: String? = nil) {
    
        self.filename = asFilename

        if (cleanup != nil) {
        
            self.cleanup = cleanup
            
            self.namespace = namespace
       
        } else if let namespace = namespace {

            self.cleanup = "delete \(namespace)"
            
            self.namespace = namespace
      
        } else {
        
            self.namespace = nil
            
            self.cleanup = nil
        }

        if (filename == "") {
        
            self.source = source
       
        } else {
        
            self.source = source + "\r\n//# sourceURL=" + filename + "\r\n"
        }
    }
    
    deinit {
        
        eject()
    }
    
    internal func inject(_ context: NKScriptContext) {
        
        self.context = context
        
        context.evaluateJavaScript(source, completionHandler: nil)
        
        NKLogging.log("+E\(context.id) Injected \(filename) ")
    }
    
    internal func eject() {
        
        guard let context = context else { return }
        
        if let cleanup = cleanup {
            
            context.evaluateJavaScript(cleanup, completionHandler: nil)
        }
        
        self.context =  nil
    }
}
