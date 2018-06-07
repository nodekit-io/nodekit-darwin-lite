//
//  Disposable.swift
//  NKScriptingLite
//
//  Created by Patrick Goley on 6/7/18.
//  Copyright © 2018 OffGrid Networks. All rights reserved.
//

/*
 Should be implemented by any NKNativePlugin object that
 needs to perform cleanup on engine tear-down, such as
 timers, filehandles, etc.
 */
protocol Disposable {
    
    func dispose()
}
