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
        let cachesPath = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.CachesDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0]
        let hanekePathComponent = HanekeGlobals.Domain
        let basePath = (cachesPath as NSString).stringByAppendingPathComponent(hanekePathComponent)
        // TODO: Do not recaculate basePath value
        return basePath
    }
    
    public let path: String

    public var size : UInt64 = 0

    public var capacity : UInt64 = 0 {
        didSet {
            dispatch_async(self.cacheQueue, {
                self.controlCapacity()
            })
        }
    }

    public lazy var cacheQueue : dispatch_queue_t = {
        let queueName = HanekeGlobals.Domain + "." + (self.path as NSString).lastPathComponent
        let cacheQueue = dispatch_queue_create(queueName, nil)
        return cacheQueue
    }()
    
    public init(path: String, capacity: UInt64 = UINT64_MAX) {
        self.path = path
        self.capacity = capacity
        dispatch_async(self.cacheQueue, {
            self.calculateSize()
            self.controlCapacity()
        })
    }
    
    public func setData(@autoclosure(escaping) getData: () -> NSData?, key: String) {
        dispatch_async(cacheQueue, {
            if let data = getData() {
                self.setDataSync(data, key: key)
            } else {
                Log.error("Failed to get data for key \(key)")
            }
        })
    }
    
    public func fetchData(key key: String, failure fail: ((NSError?) -> ())? = nil, success succeed: (NSData) -> ()) {
        dispatch_async(cacheQueue) {
            let path = self.pathForKey(key)
            do {
                let data = try NSData(contentsOfFile: path, options: NSDataReadingOptions())
                dispatch_async(dispatch_get_main_queue()) {
                    succeed(data)
                }
                self.updateDiskAccessDateAtPath(path)
            } catch {
                if let block = fail {
                    dispatch_async(dispatch_get_main_queue()) {
                        block(error as NSError)
                    }
                }
            }
        }
    }

    public func removeData(key: String) {
        dispatch_async(cacheQueue, {
            let path = self.pathForKey(key)
            self.removeFileAtPath(path)
        })
    }
    
    public func removeAllData() {
        let fileManager = NSFileManager.defaultManager()
        let cachePath = self.path
        dispatch_async(cacheQueue, {
            do {
                let contents = try fileManager.contentsOfDirectoryAtPath(cachePath)
                for pathComponent in contents {
                    let path = (cachePath as NSString).stringByAppendingPathComponent(pathComponent)
                    do {
                        try fileManager.removeItemAtPath(path)
                    } catch {
                        Log.error("Failed to remove path \(path)", error as NSError)
                    }
                }
                self.calculateSize()
            } catch {
                Log.error("Failed to list directory", error as NSError)
            }
        })
    }

    public func updateAccessDate(@autoclosure(escaping) getData: () -> NSData?, key: String) {
        dispatch_async(cacheQueue, {
            let path = self.pathForKey(key)
            let fileManager = NSFileManager.defaultManager()
            if (!(fileManager.fileExistsAtPath(path) && self.updateDiskAccessDateAtPath(path))){
                if let data = getData() {
                    self.setDataSync(data, key: key)
                } else {
                    Log.error("Failed to get data for key \(key)")
                }
            }
        })
    }

    public func pathForKey(key: String) -> String {
        let escapedFilename = key.escapedFilename()
        let filename = escapedFilename.characters.count < Int(NAME_MAX) ? escapedFilename : key.MD5Filename()
        let keyPath = (self.path as NSString).stringByAppendingPathComponent(filename)
        return keyPath
    }
    
    // MARK: Private
    
    private func calculateSize() {
        let fileManager = NSFileManager.defaultManager()
        size = 0
        let cachePath = self.path
        do {
            let contents = try fileManager.contentsOfDirectoryAtPath(cachePath)
            for pathComponent in contents {
                let path = (cachePath as NSString).stringByAppendingPathComponent(pathComponent)
                do {
                    let attributes : NSDictionary = try fileManager.attributesOfItemAtPath(path)
                    size += attributes.fileSize()
                } catch {
                    Log.error("Failed to read file size of \(path)", error as NSError)
                }
            }

        } catch {
            Log.error("Failed to list directory", error as NSError)
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
    
    private func setDataSync(data: NSData, key: String) {
        let path = self.pathForKey(key)
        let fileManager = NSFileManager.defaultManager()
        let previousAttributes : NSDictionary? = try? fileManager.attributesOfItemAtPath(path)
        
        do {
            try data.writeToFile(path, options: NSDataWritingOptions.AtomicWrite)
        } catch {
            Log.error("Failed to write key \(key)", error as NSError)
        }
        
        if let attributes = previousAttributes {
            self.size -= attributes.fileSize()
        }
        self.size += UInt64(data.length)
        self.controlCapacity()
    }
    
    private func updateDiskAccessDateAtPath(path: String) -> Bool {
        let fileManager = NSFileManager.defaultManager()
        let now = NSDate()
        do {
            try fileManager.setAttributes([NSFileModificationDate : now], ofItemAtPath: path)
            return true
        } catch {
            Log.error("Failed to update access date", error as NSError)
            return false
        }
    }
    
    private func removeFileAtPath(path: String) {
        let fileManager = NSFileManager.defaultManager()
        do {
            let attributes : NSDictionary =  try fileManager.attributesOfItemAtPath(path)
            let fileSize = attributes.fileSize()
            do {
                try fileManager.removeItemAtPath(path)
                self.size -= fileSize
            } catch {
                Log.error("Failed to remove file", error as NSError)
            }
        } catch {
            let castedError = error as NSError
            if isNoSuchFileError(castedError) {
                Log.debug("File not found", castedError)
            } else {
                Log.error("Failed to remove file", castedError)
            }
        }
    }
}

private func isNoSuchFileError(error : NSError?) -> Bool {
    if let error = error {
        return NSCocoaErrorDomain == error.domain && error.code == NSFileReadNoSuchFileError
    }
    return false
}
