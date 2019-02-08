//
//  NKErrors.swift
//  NKScriptingLite
//
//  Created by Patrick Goley on 2/7/19.
//  Copyright © 2019 OffGrid Networks. All rights reserved.
//

import Foundation

public enum NKError: Int, Error {
    
    static let domain = "NKScripting.Errors"
    
    case invalidJavaScript
}

extension NSError {
    
    static func invalidJavaScriptError(_ err: Error, source: String) -> NSError {
        return NSError(
            domain: NKError.domain,
            code: NKError.invalidJavaScript.rawValue,
            userInfo: [
                "description": "Error evaluating Javascript: \(err)",
                "source:": source
            ]
        )
    }
}
