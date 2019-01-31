/*
 * nodekit.io
 *
 * Copyright (c) 2016 OffGrid Networks. All Rights Reserved.
 * Portions Copyright (c) 2013 GitHub, Inc. under MIT License
 * Portions Copyright (c) 2015 lazyapps. All rights reserved.
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

struct NKAR_BytesReader {
    
    let bytes: UnsafePointer<UInt8>
    
    var index: Int
    
    init(bytes b: UnsafePointer<UInt8>, index i: Int) {
     
        bytes = b
        
        index = i
    
    }
    
}

extension NKAR_BytesReader {
    
    mutating func skip(_ dist: Int, backward: Bool = false) {
        
        self.index = backward ? self.index - dist : self.index + dist
        
    }
    
    mutating func skipb(_ dist: Int) {
        
        skip(dist, backward: true)
        
    }
    
    mutating func byte(_ readBackward: Bool = false) -> UInt8 {
       
        let result = bytes[index]
        
        self.index = readBackward ? self.index-1 : self.index+1
        
        return result
    }
    
    mutating func byteb() -> UInt8 {
        
        return byte(true)
    
    }
    
    mutating func le16(_ readBackward: Bool = false) -> UInt16 {
    
        let rng = index..<index+2
        
        let result = rng.reduce(UInt16.min) { $0 + UInt16(bytes[$1]) << UInt16(($1 - rng.lowerBound) * 8) }
        
        index = readBackward ? rng.lowerBound-1 : rng.upperBound
        
        return result
    }
    
    mutating func le16b() -> UInt16 {
        
        return le16(true)
    }
    
    mutating func le32(_ readBackward: Bool = false) -> UInt32 {
        
        let rng = index..<index+4
        
        let result = rng.reduce(UInt32.min) { $0 + UInt32(bytes[$1]) << UInt32(($1 - rng.lowerBound) * 8) }
        
        index = readBackward ? rng.lowerBound-1 : rng.upperBound
        
        return result
    }
    
    mutating func le32b() -> UInt32 {
        
        return le32(true)
    }
    
    mutating func string(_ len: Int) -> String? {
        
        let buffp = UnsafeBufferPointer<UInt8>(start: bytes.advanced(by: index), count: len)
        
        let bytesSequence = AnySequence(buffp.makeIterator)
        
        let s = String(bytes: bytesSequence, encoding: String.Encoding.utf8)
        
        index += len
        
        return s
    }
}

