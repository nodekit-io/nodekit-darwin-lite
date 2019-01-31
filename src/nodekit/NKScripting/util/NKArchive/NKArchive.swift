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

open class NKArchive {
    
    var path: String
    
    var _cdirs: [String: NKAR_CentralDirectory]
    
    open var keys: [String] {
        get {
            return Array(_cdirs.keys)
        }
    }
    
    init(path: String, _cdirs: [String: NKAR_CentralDirectory]) {
        
        self.path = path
        
        self._cdirs = _cdirs
        
    }
    
    static func createFromPath(_ path: String) -> (NKArchive, Data)? {
        
        guard let data = FileManager.default.contents(atPath: path)
            
            else { return nil }
        
        let bytes = (data as NSData).bytes.assumingMemoryBound(to: UInt8.self)
        
        let len = data.count
        
        guard let _endrec = NKAR_EndRecord.findEndRecordInBytes(bytes, length: len)
            
            else { return nil }
        
        guard let _cdirs = NKAR_CentralDirectory.findCentralDirectoriesInBytes(bytes, length: len, withEndRecord: _endrec)
            
            else { return nil }
        
        return (NKArchive(path: path, _cdirs: _cdirs), data)
        
    }
    
    public static func createFromData(_ path: String, data: Data) -> NKArchive? {
        
        let bytes = (data as NSData).bytes.assumingMemoryBound(to: UInt8.self)
        
        let len = data.count
        
        guard let _endrec = NKAR_EndRecord.findEndRecordInBytes(bytes, length: len)
            
            else { return nil }
        
        guard let _cdirs = NKAR_CentralDirectory.findCentralDirectoriesInBytes(bytes, length: len, withEndRecord: _endrec)
            
            else { return nil }
        
        return NKArchive(path: path, _cdirs: _cdirs)
        
    }
    
}

public extension NKArchive {
    
    fileprivate func getDirectory_(_ filename: String) -> NKAR_CentralDirectory? {
        
        let cdir = _cdirs[filename]
        
        if (cdir != nil) { return cdir }
        
        if !filename.hasPrefix("*") { return nil }
        
        let filename = (filename as NSString).substring(from: 1)
        
        let depth = (filename as NSString).pathComponents.count
        
        guard let item = self.files.filter({(item: String) -> Bool in
            return item.lowercased().hasSuffix(filename.lowercased()) &&
                ((item as NSString).pathComponents.count == depth)
            
        }).first else { return nil }
        
        return self._cdirs[item]
        
    }
    
    func dataForFile(_ filename: String) -> Data? {
        
        guard let _cdir = self.getDirectory_(filename) else { return nil }
        
        guard let file: FileHandle = FileHandle(forReadingAtPath: self.path) else { return nil }
        
        file.seek(toFileOffset: UInt64(_cdir.dataOffset))
        
        let data = file.readData(ofLength: Int(_cdir.compressedSize))
        
        file.closeFile()
        
        let bytes = (data as NSData).bytes.assumingMemoryBound(to: UInt8.self)
        
        return NKAR_Uncompressor.uncompressWithFileBytes(_cdir, fromBytes: bytes)
    }
    
    func dataForFileWithArchiveData(_ filename: String, data: Data) -> Data? {
        
        guard let _cdir = self.getDirectory_(filename) else  { return nil }
        
        return NKAR_Uncompressor.uncompressWithArchiveData(_cdir, data: data)
    }
    
    
    func exists(_ filename: String) -> Bool {
        
        if (self.getDirectory_(filename) != nil) {return true} else { return false }
    }
    
    var files: [String] {
        
        return Array(self._cdirs.keys)
    }
    
    func containsFile(_ file: String) -> Bool {
        
        return self.getDirectory_(file) != nil
        
    }
    
    func containsFolder(_ module: String) -> Bool {
        
        var folder = module
        
        if !folder.hasSuffix("/") {
            folder += "/"
        }
        
        return self.getDirectory_(folder) != nil
    }
    
    
    func stat(_ filename: String) -> Dictionary<String, AnyObject> {
        
        var storageItem  = Dictionary<String, NSObject>()
        
        guard let cdir = self.getDirectory_(filename)
            ?? self.getDirectory_(filename + "/")
            else { return storageItem }
        
        storageItem["birthtime"] = Date(timeIntervalSince1970: Double(cdir.lastmodUnixTimestamp)) as NSObject?
        
        storageItem["size"] = NSNumber(value: cdir.uncompressedSize as UInt32)
        
        storageItem["mtime"] = storageItem["birthtime"]
        
        storageItem["path"] = (self.path as NSString).appendingPathComponent(filename) as NSObject?
        
        storageItem["filetype"] = cdir.fileName.hasSuffix("/") ? "Directory" as NSString : "File" as NSObject?
        
        return storageItem
    }
    
    func getDirectory(_ foldername: String) -> [String] {
        
        var foldername = foldername;
        
        if (foldername.last != "/")
        {
            foldername = foldername + "/";
        }
        
        let depth = (foldername as NSString).pathComponents.count + 1
        
        let items = self.files.filter({(item: String) -> Bool in
            return item.lowercased().hasPrefix(foldername.lowercased()) &&
                ((item as NSString).pathComponents.count == depth) &&
                (item.last == "/")
        })
        
        return items.map({(item: String) -> String in
            return (item as NSString).lastPathComponent
        })
        
    }
}


public extension NKArchive {
    
    subscript(file: String) -> Data? {
        
        return dataForFile(file)
        
    }
    
    subscript(file: String, withArchiveData data: Data) -> Data? {
        
        return dataForFileWithArchiveData(file, data: data)
        
    }
    
}
