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

import Cocoa
import NKScripting

fileprivate let cycleEnginePeriodically = false

class SampleAppDelegate: NSObject, NSApplicationDelegate, NKScriptContextDelegate {
    
    fileprivate let statusItem: NSStatusItem
    
    var context: NKScriptContext?

    override init() {
        
        statusItem = NSStatusBar.system.statusItem(withLength: 24)
        
        super.init()
        
        setupStatusMenu()
        
        startNodeKitScripting()
    }
    
    @objc func quitApp(_ sender: AnyObject) {
        
        NSApplication.shared.terminate(self)
        
    }

    func setupStatusMenu() {
        
            statusItem.image = NSImage(named: NSImage.Name("MenuIcon"))
        
            statusItem.title = "";
        
            let menu = NSMenu()
        
            let quitMenuItem = NSMenuItem(title:"Quit", action:#selector(SampleAppDelegate.quitApp(_:)), keyEquivalent:"")
            
            quitMenuItem.target = self
            
            menu.addItem(quitMenuItem)
            
            statusItem.menu = menu
        
    }
    
    
    fileprivate func startNodeKitScripting() {
        
        let options: [String: AnyObject] = [
        "Engine":  NKEngineType.javaScriptCore.rawValue as NSNumber
        ]
        
        NKScriptContextFactory().createScriptContext(options, delegate: self)
    }
    
    func NKScriptEngineDidLoad(_ context: NKScriptContext) -> Void {
        
        SamplePlugin.attachTo(context)
        
        context.injectJavaScript(NKScriptSource(source: "process.bootstrap('app/index.js');", asFilename: "boot"))
        
        self.context = context
        
        if cycleEnginePeriodically {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5) {
                
                self.context?.stop()
                self.context = nil
                
                self.startNodeKitScripting()
            }
        }
    }
    
    func NKScriptEngineReady(_ context: NKScriptContext) -> Void {
        
        NKEventEmitter.global.emit("nk.jsApplicationReady", "" as AnyObject)
    }
}
