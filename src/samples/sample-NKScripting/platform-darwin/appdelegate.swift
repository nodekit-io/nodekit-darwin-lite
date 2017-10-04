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

class SampleAppDelegate: NSObject, NSApplicationDelegate {
    
    fileprivate let statusItem: NSStatusItem
    
    fileprivate let scriptContextDelegate : NKScriptContextDelegate

     override init() {
        
        statusItem = NSStatusBar.system.statusItem(withLength: 24)
        
        scriptContextDelegate = SampleScriptDelegate()
        
        super.init()
        
        setupStatusMenu()
        
        startNodeKitScripting()
        
    }
    
    @objc func quitApp(_ sender: AnyObject) {
        
        NSApplication.shared.terminate(self)
        
    }

    func setupStatusMenu() {
        
            statusItem.image = NSImage(named: NSImage.Name(rawValue: "MenuIcon"))
        
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
        
        NKScriptContextFactory().createScriptContext(options, delegate: self.scriptContextDelegate)
        
    }

}
