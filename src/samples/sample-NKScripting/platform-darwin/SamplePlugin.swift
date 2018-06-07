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
import Cocoa
import WebKit
import NKScripting

@objc protocol SamplePluginProtocol: NKScriptExport, NKNativePlugin {
    func logconsole(_ text: AnyObject?) -> Void
    func alertSync(_ text: AnyObject?) -> String
}


class SamplePlugin: NSObject, SamplePluginProtocol {
    
    let namespace: String = "io.nodekit.test"
    let options: [String : AnyObject] = [
        "PluginBridge": NKScriptExportType.nkScriptExport.rawValue as NSNumber
    ]
    
    class func attachTo(_ context: NKScriptContext) {
        context.loadPlugin(SamplePlugin())
    }

    func logconsole(_ text: AnyObject?) -> Void {
        print(text as? String! ?? "")
    }

    func alertSync(_ text: AnyObject?) -> String {
        DispatchQueue.main.async {
            self._alert(title: text as? String, message: nil)
        }
        return "OK"
    }

    fileprivate func _alert(title: String?, message: String?) {
        let myPopup: NSAlert = NSAlert()
        myPopup.messageText = message ?? "NodeKit"
        myPopup.informativeText = title ?? ""
        myPopup.alertStyle = .warning
        myPopup.addButton(withTitle: "OK")
        myPopup.runModal()
    }
}
