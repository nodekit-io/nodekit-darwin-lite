/*
 * nodekit.io
 *
 * Copyright (c) 2016 OffGrid Networks. All Rights Reserved.
 * Portions Copyright (c) 2013 GitHub, Inc. under MIT License
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

import JavaScriptCore

@objc public protocol NKStorageExport: NKScriptExport {
    
    func getSourceSync(_ module: String) -> String
    
    func existsSync(_ module: String) -> Bool
    
    func statSync(_ module: String) -> Dictionary<String, AnyObject>
    
    func getDirectorySync(_ module: String) -> [String]

}

open class NKStorage: NSObject, NKNativePlugin {
    
    // PUBLIC METHODS NATIVE SIDE ONLY
    
    public let namespace = "io.nodekit.scripting.storage"
    public let sourceJS: String? = "lib-scripting.nkar/lib-scripting/native_module.js"
    
    public static var mainBundle = NKStorage.mainBundle_()

    open class func getResource(_ module: String, _ t: AnyClass? = nil) -> String? {
        
        if module.lowercased().range(of: ".nkar/") != nil {
            return getNKARResource_(module, t)
        }
        
        let bundle = (t != nil) ?  Bundle(for: t!) :  NKStorage.mainBundle
        
        guard let path = getPath_(bundle, module),
            
            let source = try? NSString(contentsOfFile: path, encoding: String.Encoding.utf8.rawValue) else {
                
                return nil
                
        }
        
        return source as String
        
    }
    
    fileprivate static let fileManager = FileManager.default
    
    open class func getResourceData(_ module: String, _ t: AnyClass? = nil) -> Data? {
        
        if module.lowercased().range(of: ".nkar/") != nil {
            return getDataNKAR_(module, t)
        }
        
        let bundle = (t != nil) ?  Bundle(for: t!) :  NKStorage.mainBundle
        
        guard let path = getPath_(bundle, module),
            
            let data = try? Data(
                contentsOf: URL(fileURLWithPath: path as String),
                options: NSData.ReadingOptions(rawValue: 0)
            )
            
            else { return nil }
        
        return data
        
    }
    
    open class func getPluginWithStub(_ stub: String, _ module: String, _ t: AnyClass? = nil) -> String {
        
        guard let appjs = NKStorage.getResource(module, t) else {
            
            NKLogging.die("Failed to read script")
            
        }
        
        return "function loadplugin(){\n" + appjs + "\n}\n" + stub + "\n" + "loadplugin();" + "\n"
    }
    
    open class func includeBundle(_ bundle: Bundle) -> Void {
        
       if !bundles.contains(where: { $0 === bundle })
       {
          bundles.append(bundle)
        }
    }
    
    open class func includeSearchPath(_ path: String) -> Void {
        
        if !searchPaths.contains(path)
        {
            searchPaths.append(path)
        }
    }
    
    open class func exists(_ module: String, _ t: AnyClass? = nil) -> Bool {
        
        if module.lowercased().range(of: ".nkar/") != nil {
            return existsNKAR_(module, t)
        }
        
        let bundle = (t != nil) ?  Bundle(for: t!) :  NKStorage.mainBundle
        
        if (getPath_(bundle, module) != nil) { return true } else { return false}
        

    }
    
    // PRIVATE METHODS
    
    fileprivate static var unzipper_ : NKArchiveReader? = nil
    
    fileprivate static var bundles : [Bundle] = [ Bundle(for: NKStorage.self) ]
    
    fileprivate static var searchPaths : [String] = [String]()
    
    fileprivate class func getNKARResource_(_ module: String, _ t: AnyClass? = nil) -> String? {
            
        guard let data = getDataNKAR_(module, t) else { return nil }
        
        return NSString(data: data, encoding: String.Encoding.utf8.rawValue) as String?
        
    }
    
    fileprivate class func existsNKAR_(_ module: String, _ t: AnyClass? = nil) -> Bool {
        
        let moduleArr = module.components(separatedBy: ".nkar/")
        
        let nkarModule: String = moduleArr[0] + ".nkar"
        
        var resource: String = moduleArr[1]
        
        let bundle = (t != nil) ?  Bundle(for: t!) :  NKStorage.mainBundle
        
        unzipper_ = unzipper_ ?? NKArchiveReader.create()
        
        let fileExtension = (resource as NSString).pathExtension
        
        if (fileExtension=="") {
            
            resource += ".js"
            
        }
        
        guard let nkarPath = getPath_(bundle, nkarModule)   else { return false }
        
        return  unzipper_!.exists(nkarPath, filename: resource)
        
    }
    
    fileprivate class func statNKAR_(_ module: String, _ t: AnyClass? = nil) -> Dictionary<String, AnyObject> {
        
        let moduleArr = module.components(separatedBy: ".nkar/")
        
        let nkarModule: String = moduleArr[0] + ".nkar"
        
        let resource: String = moduleArr[1]
        
        let bundle = (t != nil) ?  Bundle(for: t!) :  NKStorage.mainBundle
        
        unzipper_ = unzipper_ ?? NKArchiveReader.create()
        
        guard let nkarPath = getPath_(bundle, nkarModule) else { return Dictionary<String, AnyObject>() }
        
        return  unzipper_!.stat(nkarPath, filename: resource)
        
    }
    
    fileprivate class func getDirectoryNKAR_(_ module: String, _ t: AnyClass? = nil) -> [String] {
        
        let moduleArr = module.components(separatedBy: ".nkar/")
        
        let nkarModule: String = moduleArr[0] + ".nkar"
        
        let resource: String = moduleArr[1]
        
        let bundle = (t != nil) ?  Bundle(for: t!) :  NKStorage.mainBundle
        
        unzipper_ = unzipper_ ?? NKArchiveReader.create()
        
        guard let nkarPath = getPath_(bundle, nkarModule) else { return [String]() }
        
        return  unzipper_!.getDirectory(nkarPath, foldername: resource)
        
    }

    
    fileprivate class func getDataNKAR_(_ module: String, _ t: AnyClass? = nil) -> Data? {
        
        let moduleArr = module.components(separatedBy: ".nkar/")
        
        let nkarModule: String = moduleArr[0] + ".nkar"
        
        var resource: String = moduleArr[1]
        
        let bundle = (t != nil) ?  Bundle(for: t!) :  NKStorage.mainBundle
        
        unzipper_ = unzipper_ ?? NKArchiveReader.create()
        
        let fileExtension = (resource as NSString).pathExtension
        
        if (fileExtension=="") {
            
            resource += ".js"
            
        }
        
        guard let nkarPath = getPath_(bundle, nkarModule),
            
            let data = unzipper_?.dataForFile(nkarPath, filename: resource)
            
            else { return nil }
        
        return data
        
    }
    
    fileprivate class func getPath_(_ mainBundle: Bundle, _ module: String) -> String? {
     
        if module.hasPrefix("/")
        {
            return module
        }
        
        let directory = (module as NSString).deletingLastPathComponent
        
        var fileName = (module as NSString).lastPathComponent
        
        var fileExtension = (fileName as NSString).pathExtension
        
        fileName = (fileName as NSString).deletingPathExtension
        
        if (fileExtension=="") {
            
            fileExtension = "js"
            
        }
        
        var path: String?;
        
        for _searchPath in self.searchPaths {
            
            path = ((_searchPath as NSString).appendingPathComponent(directory) as NSString).appendingPathComponent(fileName + "." + fileExtension)
            
            if fileManager.fileExists(atPath: path!)
            { break; }
            
            path = nil
            
        }
        
        if (path == nil) {
            
            path = mainBundle.path(forResource: fileName, ofType: fileExtension, inDirectory: directory)
            
            if (path == nil) {
                
                for _nodeKitBundle in bundles {
                    
                    path = _nodeKitBundle.path(forResource: fileName, ofType: fileExtension, inDirectory: directory)
                    
                    if !(path == nil) { break; }
                    
                }
            }
        }
        
        if (path == nil) {
            
            path = module
            
            if ((path! as NSString).pathComponents.count < 3) || (!FileManager.default.fileExists(atPath: path!)) {
                
                NKLogging.log("!Error - source file not found: \(directory + "/" + fileName + "." + fileExtension)")
                
                return nil
                
            }
            
        }
    
        return path!
    
    }


    fileprivate class func mainBundle_() -> Bundle {
        
        #if swift(>=3)
            
            var bundle = Bundle.main
            
            if bundle.bundleURL.pathExtension == "appex" {
            
                // Peel off two directory levels - MY_APP.app/PlugIns/MY_APP_EXTENSION.appex
                
                let url = bundle.bundleURL.deletingLastPathComponent().deletingLastPathComponent()
                
                if let appBundle = Bundle(url: url) {
                    
                    bundle = appBundle
                    
                }
            }
            
            return bundle
            
        #else
            
            var bundle = Bundle.main
            
            if bundle.bundleURL.pathExtension == "appex" {
                
                // Peel off two directory levels - MY_APP.app/PlugIns/MY_APP_EXTENSION.appex
                
                if let url = (bundle.bundleURL as NSURL).URLByDeletingLastPathComponent?.deletingLastPathComponent() {
                    
                    if let appBundle = Bundle(url: url) {
                        
                        bundle = appBundle
                    }
                    
                }
                
            }
            
            return bundle
            
        #endif
    }
    
}

extension NKStorage:  NKStorageExport {
    
    // PUBLIC METHODS, ACCESSIBLE FROM JAVASCRIPT
    
   public func getSourceSync(_ module: String) -> String {
        
        guard let data = NKStorage.getResourceData(module) else { return "" }
        
        return (data.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)))
        
    }
    
   public func existsSync(_ module: String) -> Bool {
        
        return NKStorage.exists(module)
        
    }
    
   public func statSync(_ module: String) -> Dictionary<String, AnyObject> {
        
        if module.lowercased().range(of: ".nkar/") != nil {
            
            return NKStorage.statNKAR_(module)
            
        }
        
        var storageItem  = Dictionary<String, NSObject>()
        var path: String
        
        if module.hasPrefix("/")
        {
            path = module
        } else
        {
            path = (NKStorage.mainBundle.resourcePath! as NSString).appendingPathComponent(module)
        }
        
        let attr: [FileAttributeKey : Any]
        
        do {
            
            attr = try FileManager.default.attributesOfItem(atPath: path)
            
        } catch _ {
            
            return storageItem
            
        }
        
        storageItem["birthtime"] = attr[FileAttributeKey.creationDate] as! NSDate
        
        storageItem["size"] = attr[FileAttributeKey.size] as! NSNumber
        
        storageItem["mtime"] = attr[FileAttributeKey.modificationDate] as! NSDate
        
        storageItem["path"] = path as String as NSObject?
        
        switch attr[FileAttributeKey.type] as! FileAttributeType {
            
        case FileAttributeType.typeDirectory:
            
            storageItem["filetype"] = "Directory" as NSObject?
            
            break
            
        case FileAttributeType.typeRegular:
            
            storageItem["filetype"] = "File" as NSObject?
            
            break
            
        case FileAttributeType.typeSymbolicLink:
            
            storageItem["filetype"] = "SymbolicLink" as NSObject?
            
            break
            
        default:
            
            storageItem["filetype"] = "File" as NSObject?
            
            break
            
        }
        
        return storageItem
    }
    
   public func getDirectorySync(_ module: String) -> [String] {
        
        if module.lowercased().range(of: ".nkar/") != nil {
            
            return NKStorage.getDirectoryNKAR_(module)
            
        }
        
        var path: String
        
        if module.hasPrefix("/")
        {
            path = module
        } else
        {
            path = (NKStorage.mainBundle.resourcePath! as NSString).appendingPathComponent(module)
        }
        
        let dirContents = (try? FileManager.default.contentsOfDirectory(atPath: path)) ?? [String]()
        
        return dirContents
        
    }
    
    
    class func attachTo(_ context: NKScriptContext) {
        
        context.loadPlugin(NKStorage())
    }
}

