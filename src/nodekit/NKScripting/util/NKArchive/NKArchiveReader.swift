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

public struct NKArchiveReader {
    
    var _cacheCDirs: NSCache<NSString, NKArchive>
    
    var _cacheArchiveData: NSCache<NSString, NSData>

}

public extension NKArchiveReader {
    
    static func create() -> NKArchiveReader {
        
        let cacheArchiveData2 = NSCache<NSString, NSData>()

        cacheArchiveData2.countLimit = 10
        
        return NKArchiveReader( _cacheCDirs: NSCache(), _cacheArchiveData: cacheArchiveData2)
    
    }
    
    mutating func dataForFile(_ archive: String, filename: String) -> Data? {
        
        if let nkArchive = _cacheCDirs.object(forKey: archive as NSString) {
            
            if let data = _cacheArchiveData.object(forKey: archive as NSString) {
                
                return nkArchive[filename, withArchiveData: data as Data]
                
            } else
                
            {
                return nkArchive[filename] as Data?
            }
            
        } else {
            
            guard let (nkArchive, data) = NKArchive.createFromPath(archive) else { return nil }
            
            _cacheCDirs.setObject(nkArchive, forKey: archive as NSString)
            _cacheArchiveData.setObject(data as NSData, forKey: archive as NSString)
            
            return nkArchive[filename, withArchiveData: data]
        }
    }
    
    mutating func exists(_ archive: String, filename: String) -> Bool {
        
        if let nkArchive = _cacheCDirs.object(forKey: archive as NSString) {
            
                return nkArchive.exists(filename)
            
        } else {
            
            guard let (nkArchive, data) = NKArchive.createFromPath(archive) else { return false }
            
            _cacheCDirs.setObject(nkArchive, forKey: archive as NSString)
            _cacheArchiveData.setObject(data as NSData, forKey: archive as NSString)
            
            return nkArchive.exists(filename)
        }
    }
    
    mutating func stat(_ archive: String, filename: String) -> Dictionary<String, AnyObject> {
        
        if let nkArchive = _cacheCDirs.object(forKey: archive as NSString) {
            
            return nkArchive.stat(filename)
            
        } else {
            
            guard let (nkArchive, data) = NKArchive.createFromPath(archive) else { return Dictionary<String, AnyObject>() }
            
            _cacheCDirs.setObject(nkArchive, forKey: archive as NSString)
            _cacheArchiveData.setObject(data as NSData, forKey: archive as NSString)
            
            return nkArchive.stat(filename)
        }
    }
    
    mutating func getDirectory(_ archive: String, foldername: String) -> [String] {
        
        if let nkArchive = _cacheCDirs.object(forKey: archive as NSString) {
            
            return nkArchive.getDirectory(foldername)
            
        } else {
            
            guard let (nkArchive, data) = NKArchive.createFromPath(archive) else { return [String]() }
            
            _cacheCDirs.setObject(nkArchive, forKey: archive as NSString)
            _cacheArchiveData.setObject(data as NSData, forKey: archive as NSString)
            
            return nkArchive.getDirectory(foldername)
        }
    }    
}

