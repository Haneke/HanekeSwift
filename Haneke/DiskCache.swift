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
        let cachesPath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.cachesDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]
        let hanekePathComponent = HanekeGlobals.Domain
        let basePath = (cachesPath as NSString).appendingPathComponent(hanekePathComponent)
        // TODO: Do not recaculate basePath value
        return basePath
    }
    
    public let path: String

    public var size : UInt64 = 0

    public var capacity : UInt64 = 0 {
        didSet {
            self.cacheQueue.async(execute: {
                self.controlCapacity()
            })
        }
    }

    public lazy var cacheQueue : DispatchQueue = {
        let queueName = HanekeGlobals.Domain + "." + (self.path as NSString).lastPathComponent
        let cacheQueue = DispatchQueue(label: queueName)
        return cacheQueue
    }()
    
    public init(path: String, capacity: UInt64 = UINT64_MAX) {
        self.path = path
        self.capacity = capacity
        self.cacheQueue.async(execute: {
            self.calculateSize()
            self.controlCapacity()
        })
    }
    
    public func setData( getData: @autoclosure @escaping () -> Data?, key: String) {
        self.cacheQueue.async(execute:{
            if let data = getData() {
                self.setDataSync(data: data, key: key)
            } else {
              Log.error(message: "Failed to get data for key \(key)")
            }
        })
    }
    
    public func fetchData(key: String, failure fail: ((Error?) -> ())? = nil, success succeed: @escaping(Data) -> ()) {
        self.cacheQueue.async {
            let path = self.pathForKey(key: key)
            do {
                let data = try Data(contentsOf: URL(string:path)!, options: Data.ReadingOptions())
                DispatchQueue.main.async {
                    succeed(data)
                }
                let _ = self.updateDiskAccessDateAtPath(path: path)
            } catch {
                if let block = fail {
                    DispatchQueue.main.async {
                        block(error as NSError)
                    }
                }
            }
        }
    }

    public func removeData(key: String) {
        cacheQueue.async(execute: {
            let path = self.pathForKey(key: key)
            self.removeFileAtPath(path: path)
        })
    }
    
    public func removeAllData() {
        let fileManager = FileManager.default
        let cachePath = self.path
        cacheQueue.async(execute: {
            do {
                let contents = try fileManager.contentsOfDirectory(atPath: cachePath)
                for pathComponent in contents {
                    let path = (cachePath as NSString).appendingPathComponent(pathComponent)
                    do {
                        try fileManager.removeItem(atPath: path)
                    } catch {
                       Log.error(message: "Failed to remove path \(path)", error: error as NSError)
                    }
                }
                self.calculateSize()
            } catch {
                Log.error(message: "Failed to list directory", error: error as NSError)
            }
        })
    }

    public func updateAccessDate( getData: @autoclosure @escaping () -> Data?, key: String) {
        cacheQueue.async(execute: {
            let path = self.pathForKey(key: key)
            let fileManager = FileManager.default
            if (!(fileManager.fileExists(atPath: path) && self.updateDiskAccessDateAtPath(path: path))){
                if let data = getData() {
                    self.setDataSync(data: data, key: key)
                } else {
                    Log.error(message: "Failed to get data for key \(key)")
                }
            }
        })
    }

    public func pathForKey(key: String) -> String {
        let escapedFilename = key.escapedFilename()
        let filename = escapedFilename.characters.count < Int(NAME_MAX) ? escapedFilename : key.MD5Filename()
        let keyPath = (self.path as NSString).appendingPathComponent(filename)
        return keyPath
    }
    
    // MARK: Private
    
    private func calculateSize() {
        let fileManager = FileManager.default
        size = 0
        let cachePath = self.path
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: cachePath)
            for pathComponent in contents {
                let path = (cachePath as NSString).appendingPathComponent(pathComponent)
                do {
                    let attributes = try fileManager.attributesOfItem(atPath: path) as? NSDictionary
                    size += (attributes?.fileSize())!
                } catch {
                    Log.error(message: "Failed to read file size of \(path)", error: error as NSError)
                }
            }

        } catch {
           Log.error(message: "Failed to list directory", error: error as NSError)
        }
    }
    
    private func controlCapacity() {
        if self.size <= self.capacity { return }
        
        let fileManager = FileManager.default
        let cachePath = self.path
        fileManager.enumerateContentsOfDirectoryAtPath(path: cachePath, orderedByProperty: URLResourceKey.contentModificationDateKey.rawValue, ascending: true) { (URL : NSURL, _, stop : inout Bool) -> Void in
            
            if let path = URL.path {
                self.removeFileAtPath(path: path)

                stop = self.size <= self.capacity
            }
        }
    }
    
    private func setDataSync(data: Data, key: String) {
        let path = self.pathForKey(key: key)
        let fileManager = FileManager.default
        let previousAttributes = try? fileManager.attributesOfItem(atPath: path) as NSDictionary

        do {
            try data.write(to: URL.init(fileURLWithPath: path)) // .write(toFile: path, options: NSData.WritingOptions.atomicWrite)
        } catch {
           Log.error(message: "Failed to write key \(key)", error: error as NSError)
        }
        
        if let attributes = previousAttributes {
            self.size -= (attributes.fileSize())
        }
        self.size += UInt64(data.count)
        self.controlCapacity()
    }
    
    private func updateDiskAccessDateAtPath(path: String) -> Bool {
        let fileManager = FileManager.default
        let now = Date()
        do {
            try fileManager.setAttributes([FileAttributeKey.modificationDate : now], ofItemAtPath: path)
            return true
        } catch {
            Log.error(message: "Failed to update access date", error: error )
            return false
        }
    }
    
    private func removeFileAtPath(path: String) {
        let fileManager = FileManager.default
        do {
            let attributes =  try fileManager.attributesOfItem(atPath: path) as NSDictionary
            let fileSize = attributes.fileSize()
            do {
                try fileManager.removeItem(atPath: path)
                self.size -= fileSize
            } catch {
                Log.error(message: "Failed to remove file", error: error )
            }
        } catch {
            let castedError = error as NSError
            if isNoSuchFileError(error: castedError) {
               Log.debug(message: "File not found", error: castedError)
            } else {
              Log.error(message: "Failed to remove file", error: castedError)
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
