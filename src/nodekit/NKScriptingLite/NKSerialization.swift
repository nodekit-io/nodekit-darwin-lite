//
//  NKSerialization.swift
//  NKScriptingLite
//
//  Created by Patrick Goley on 2/7/19.
//  Copyright © 2019 OffGrid Networks. All rights reserved.
//

import Foundation

final class NKSerialization {
    
    static public func serialize(_ object: AnyObject?) -> String {
        
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
}
