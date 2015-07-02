//
//  DiskCache.swift
//  Haneke
//
//  Created by Hermes Pique on 8/10/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import Foundation

public class DiskCache {
    
    public class func basePath() -> String {
        let cachesPath = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.CachesDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0] as! String
        let hanekePathComponent = HanekeGlobals.Domain
        let basePath = cachesPath.stringByAppendingPathComponent(hanekePathComponent)
        // TODO: Do not recaculate basePath value
        return basePath
    }
    
    public let path : String

    public var size : UInt64 = 0

    public var capacity : UInt64 = 0 {
        didSet {
            dispatch_async(self.cacheQueue, {
                self.controlCapacity()
            })
        }
    }

    public lazy var cacheQueue : dispatch_queue_t = {
        let queueName = HanekeGlobals.Domain + "." + self.path.lastPathComponent
        let cacheQueue = dispatch_queue_create(queueName, nil)
        return cacheQueue
    }()
    
    public init(path : String, capacity : UInt64 = UINT64_MAX) {
        self.path = path
        self.capacity = capacity
        dispatch_async(self.cacheQueue, {
            self.calculateSize()
            self.controlCapacity()
        })
    }
    
    public func setData(@autoclosure(escaping) getData : () -> NSData?, key : String) {
        dispatch_async(cacheQueue, {
            if let data = getData() {
                self.setDataSync(data, key: key)
            } else {
                Log.error("Failed to get data for key \(key)")
            }
        })
    }
    
    public func fetchData(key : String, failure fail : ((NSError?) -> ())? = nil, success succeed : (NSData) -> ()) {
        dispatch_async(cacheQueue, {
            let path = self.pathForKey(key)
            var error: NSError? = nil
            if let data = NSData(contentsOfFile: path, options: NSDataReadingOptions.allZeros, error: &error) {
                dispatch_async(dispatch_get_main_queue(), {
                   succeed(data)
                })
                self.updateDiskAccessDateAtPath(path)
            } else if let block = fail {
                dispatch_async(dispatch_get_main_queue(), {
                    block(error)
                })
            }
        })
    }

    public func containsKey(key : String) -> Bool {
        var result = false
        dispatch_sync(cacheQueue) {
            let path = self.pathForKey(key)
            let fileManager = NSFileManager.defaultManager()
            result = fileManager.fileExistsAtPath(path)
        }
        return result
    }

    public func removeData(key : String) {
        dispatch_async(cacheQueue, {
            let path = self.pathForKey(key)
            self.removeFileAtPath(path)
        })
    }
    
    public func removeAllData() {
        let fileManager = NSFileManager.defaultManager()
        let cachePath = self.path
        dispatch_async(cacheQueue, {
            var error: NSError? = nil
            if let contents = fileManager.contentsOfDirectoryAtPath(cachePath, error: &error) as? [String] {
                for pathComponent in contents {
                    let path = cachePath.stringByAppendingPathComponent(pathComponent)
                    if !fileManager.removeItemAtPath(path, error: &error) {
                        Log.error("Failed to remove path \(path)", error)
                    }
                }
                self.calculateSize()
            } else {
                Log.error("Failed to list directory", error)
            }
        })
    }

    public func updateAccessDate(@autoclosure(escaping) getData : () -> NSData?, key : String) {
        dispatch_async(cacheQueue, {
            let path = self.pathForKey(key)
            let fileManager = NSFileManager.defaultManager()
            if (!self.updateDiskAccessDateAtPath(path) && !fileManager.fileExistsAtPath(path)){
                if let data = getData() {
                    self.setDataSync(data, key: key)
                } else {
                    Log.error("Failed to get data for key \(key)")
                }
            }
        })
    }

    public func pathForKey(key : String) -> String {
        var escapedFilename = key.escapedFilename()
        let filename = count(escapedFilename) < Int(NAME_MAX) ? escapedFilename : key.MD5Filename()
        let keyPath = self.path.stringByAppendingPathComponent(filename)
        return keyPath
    }
    
    // MARK: Private
    
    private func calculateSize() {
        let fileManager = NSFileManager.defaultManager()
        size = 0
        let cachePath = self.path
        var error : NSError?
        if let contents = fileManager.contentsOfDirectoryAtPath(cachePath, error: &error) as? [String] {
            for pathComponent in contents {
                let path = cachePath.stringByAppendingPathComponent(pathComponent)
                if let attributes : NSDictionary = fileManager.attributesOfItemAtPath(path, error: &error) {
                    size += attributes.fileSize()
                } else {
                    Log.error("Failed to read file size of \(path)", error)
                }
            }
        } else {
            Log.error("Failed to list directory", error)
        }
    }
    
    private func controlCapacity() {
        if self.size <= self.capacity { return }
        
        let fileManager = NSFileManager.defaultManager()
        let cachePath = self.path
        fileManager.enumerateContentsOfDirectoryAtPath(cachePath, orderedByProperty: NSURLContentModificationDateKey, ascending: true) { (URL : NSURL, _, inout stop : Bool) -> Void in
            
            if let path = URL.path {
                self.removeFileAtPath(path)

                stop = self.size <= self.capacity
            }
        }
    }
    
    private func setDataSync(data: NSData, key : String) {
        let path = self.pathForKey(key)
        var error: NSError?
        let fileManager = NSFileManager.defaultManager()
        let previousAttributes : NSDictionary? = fileManager.attributesOfItemAtPath(path, error: nil)
        let success = data.writeToFile(path, options: NSDataWritingOptions.AtomicWrite, error:&error)
        if (!success) {
            Log.error("Failed to write key \(key)", error)
        }
        if let attributes = previousAttributes {
            self.size -= attributes.fileSize()
        }
        self.size += UInt64(data.length)
        self.controlCapacity()
    }
    
    private func updateDiskAccessDateAtPath(path : String) -> Bool {
        let fileManager = NSFileManager.defaultManager()
        let now = NSDate()
        var error : NSError?
        let success = fileManager.setAttributes([NSFileModificationDate : now], ofItemAtPath: path, error: &error)
        if !success {
            Log.error("Failed to update access date", error)
        }
        return success
    }
    
    private func removeFileAtPath(path:String) {
        var error : NSError?
        let fileManager = NSFileManager.defaultManager()
        if let attributes : NSDictionary = fileManager.attributesOfItemAtPath(path, error: &error) {
            let fileSize = attributes.fileSize()
            if fileManager.removeItemAtPath(path, error: &error) {
                self.size -= fileSize
            } else {
                Log.error("Failed to remove file", error)
            }
        } else if isNoSuchFileError(error) {
            Log.debug("File not found", error)
        } else {
            Log.error("Failed to remove file", error)
        }
    }
}

private func isNoSuchFileError(error : NSError?) -> Bool {
    if let error = error {
        return NSCocoaErrorDomain == error.domain && error.code == NSFileReadNoSuchFileError
    }
    return false
}
