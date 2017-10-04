/*
 * nodekit.io
 *
 * Copyright (c) 2016-7 OffGrid Networks. All Rights Reserved.
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
import Compression

struct NKAR_Uncompressor {
    
    static func uncompressWithArchiveData(_ cdir: NKAR_CentralDirectory, data: Data) -> Data? {
        
            let bytes = unsafeBitCast((data as NSData).bytes, to: UnsafePointer<UInt8>.self)
            let offsetBytes = bytes.advanced(by: Int(cdir.dataOffset))
            return uncompressWithFileBytes(cdir, fromBytes: offsetBytes)
    }
    
    
    func unzip_(_ compressedData:Data) -> Data? {
        let streamPtr = UnsafeMutablePointer<compression_stream>.allocate(capacity: 1)
        var stream = streamPtr.pointee
        var status: compression_status
        
        status = compression_stream_init(&stream, COMPRESSION_STREAM_DECODE, COMPRESSION_ZLIB)
        stream.src_ptr = (compressedData as NSData).bytes.bindMemory(to: UInt8.self, capacity: compressedData.count)
        stream.src_size = compressedData.count
        
        let dstBufferSize: size_t = 4096
        let dstBufferPtr = UnsafeMutablePointer<UInt8>.allocate(capacity: dstBufferSize)
        stream.dst_ptr = dstBufferPtr
        stream.dst_size = dstBufferSize
        
        let decompressedData = NSMutableData()
        
        repeat {
            status = compression_stream_process(&stream, 0)
            switch status {
            case COMPRESSION_STATUS_OK:
                if stream.dst_size == 0 {
                    decompressedData.append(dstBufferPtr, length: dstBufferSize)
                    stream.dst_ptr = dstBufferPtr
                    stream.dst_size = dstBufferSize
                }
            case COMPRESSION_STATUS_END:
                if stream.dst_ptr > dstBufferPtr {
                    decompressedData.append(dstBufferPtr, length: stream.dst_ptr - dstBufferPtr)
                }
            default:
                break
            }
        }
            while status == COMPRESSION_STATUS_OK
        
        compression_stream_destroy(&stream)
        
        if status == COMPRESSION_STATUS_END {
            return decompressedData as Data
        } else {
            print("Unzipping failed")
            return nil
        }
    }

    
    static func uncompressWithFileBytes(_ cdir: NKAR_CentralDirectory, fromBytes bytes: UnsafePointer<UInt8>) -> Data? {
        
            let len = Int(cdir.uncompressedSize)
            
            let out = UnsafeMutablePointer<UInt8>.allocate(capacity: len)
            
            switch cdir.compressionMethod {
            
            case .none:
            
                out.assign(from: UnsafeMutablePointer<UInt8>(mutating: bytes), count: len)
           
            case .deflate:
                
                let streamPtr = UnsafeMutablePointer<compression_stream>.allocate(capacity: 1)
                
                var stream = streamPtr.pointee
                
                var status : compression_status
                
                let op : compression_stream_operation = COMPRESSION_STREAM_DECODE
                
                let flags : Int32 = 0
                
                let algorithm : compression_algorithm = Compression.COMPRESSION_ZLIB
                
                
                status = compression_stream_init(&stream, op, algorithm)
           
                guard status != COMPRESSION_STATUS_ERROR else {
                    // an error occurred
                    return nil
                }
                
                // setup the stream's source
                stream.src_ptr = bytes
                
                stream.src_size = Int(cdir.compressedSize)
                
                stream.dst_ptr = out
                
                stream.dst_size = len
                
                repeat {
                    status = compression_stream_process(&stream, flags)
                    switch status {
                    case COMPRESSION_STATUS_OK:
                       // do nothing
                        break
                    case COMPRESSION_STATUS_END:
                        break
                    case COMPRESSION_STATUS_ERROR:
                        print("Unexpected error in stream when uncompressing nkar")
                    default:
                        break
                    }
                }
                    while status == COMPRESSION_STATUS_OK
                
                compression_stream_destroy(&stream)
            }
            
            return Data(bytesNoCopy: UnsafeMutablePointer<UInt8>(out), count: len, deallocator: .free)
            
     
    }
    
    
    static func uncompressWithCentralDirectory(_ cdir: NKAR_CentralDirectory, fromBytes bytes: UnsafePointer<UInt8>) -> Data? {
        
            let offsetBytes = bytes.advanced(by: Int(cdir.dataOffset))
            
            let offsetMBytes = UnsafeMutablePointer<UInt8>(mutating: offsetBytes)
            
            let len = Int(cdir.uncompressedSize)
            
            let out = UnsafeMutablePointer<UInt8>.allocate(capacity: len)
            
            switch cdir.compressionMethod {
                
            case .none:
                
                out.assign(from: offsetMBytes, count: len)
                
            case .deflate:
                
                let streamPtr = UnsafeMutablePointer<compression_stream>.allocate(capacity: 1)
                
                var stream = streamPtr.pointee
                
                var status : compression_status
                
                let op : compression_stream_operation = COMPRESSION_STREAM_DECODE
                
                let flags : Int32 = 0
                
                let algorithm : compression_algorithm = Compression.COMPRESSION_ZLIB
                
                status = compression_stream_init(&stream, op, algorithm)
                
                guard status != COMPRESSION_STATUS_ERROR else {
                    // an error occurred
                    return nil
                }
                
                // setup the stream's source
                stream.src_ptr = UnsafePointer<UInt8>(offsetMBytes)
                
                stream.src_size = Int(cdir.compressedSize)
                
                stream.dst_ptr = out
                
                stream.dst_size = len
                
                status = compression_stream_process(&stream, flags)
                
                switch status.rawValue {
                    
                case COMPRESSION_STATUS_END.rawValue:
                    // OK
                    break
                    
                case COMPRESSION_STATUS_OK.rawValue:
                    
                    print("Unexpected end of stream")
                    
                    return nil
                    
                case COMPRESSION_STATUS_ERROR.rawValue:
                    
                    print("Unexpected error in stream")
                    
                    return nil
                    
                default:
                    
                    break
                }
                
                compression_stream_destroy(&stream)
            }
            
            return Data(bytesNoCopy: UnsafeMutablePointer<UInt8>(out), count: len, deallocator: .free)
            
    }

}
