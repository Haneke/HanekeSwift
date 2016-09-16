//
//  DiskCache.swift
//  Haneke
//
//  Created by Hermes Pique on 8/10/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import Foundation

open class DiskCache {
    
    open class func basePath() -> String {
        let cachesPath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.cachesDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]
        let hanekePathComponent = HanekeGlobals.Domain
        let basePath = (cachesPath as NSString).appendingPathComponent(hanekePathComponent)
        // TODO: Do not recaculate basePath value
        return basePath
    }
    
    open let path: String

    open var size : UInt64 = 0

    open var capacity : UInt64 = 0 {
        didSet {
            self.cacheQueue.async(execute: {
                self.controlCapacity()
            })
        }
    }

    open lazy var cacheQueue : DispatchQueue = {
        let queueName = HanekeGlobals.Domain + "." + (self.path as NSString).lastPathComponent
        let cacheQueue = DispatchQueue(label: queueName, attributes: [])
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
    
    open func setData( _ getData: @autoclosure @escaping () -> Data?, key: String) {
        cacheQueue.async(execute: {
            if let data = getData() {
                self.setDataSync(data, key: key)
            } else {
                Log.error(message: "Failed to get data for key \(key)")
            }
        })
    }
    
    open func fetchData(key: String, failure fail: ((Error?) -> ())? = nil, success succeed: @escaping (Data) -> ()) {
        cacheQueue.async {
            let path = self.path(forKey: key)
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: Data.ReadingOptions())
                DispatchQueue.main.async {
                    succeed(data)
                }
                self.updateDiskAccessDate(atPath: path)
            } catch {
                if let block = fail {
                    DispatchQueue.main.async {
                        block(error)
                    }
                }
            }
        }
    }

    open func removeData(with key: String) {
        cacheQueue.async(execute: {
            let path = self.path(forKey: key)
            self.removeFile(atPath: path)
        })
    }
    
    open func removeAllData(_ completion: (() -> ())? = nil) {
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
                        Log.error(message: "Failed to remove path \(path)", error: error)
                    }
                }
                self.calculateSize()
            } catch {
                Log.error(message: "Failed to list directory", error: error)
            }
            if let completion = completion {
                DispatchQueue.main.async {
                    completion()
                }
            }
        })
    }

    open func updateAccessDate( _ getData: @autoclosure @escaping () -> Data?, key: String) {
        cacheQueue.async(execute: {
            let path = self.path(forKey: key)
            let fileManager = FileManager.default
            if (!(fileManager.fileExists(atPath: path) && self.updateDiskAccessDate(atPath: path))){
                if let data = getData() {
                    self.setDataSync(data, key: key)
                } else {
                    Log.error(message: "Failed to get data for key \(key)")
                }
            }
        })
    }

    open func path(forKey key: String) -> String {
        let escapedFilename = key.escapedFilename()
        let filename = escapedFilename.characters.count < Int(NAME_MAX) ? escapedFilename : key.MD5Filename()
        let keyPath = (self.path as NSString).appendingPathComponent(filename)
        return keyPath
    }
    
    // MARK: Private
    
    fileprivate func calculateSize() {
        let fileManager = FileManager.default
        size = 0
        let cachePath = self.path
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: cachePath)
            for pathComponent in contents {
                let path = (cachePath as NSString).appendingPathComponent(pathComponent)
                do {
                    let attributes: [FileAttributeKey: Any] = try fileManager.attributesOfItem(atPath: path)
                    if let fileSize = attributes[FileAttributeKey.size] as? UInt64 {
                        size += fileSize
                    }
                } catch {
                    Log.error(message: "Failed to list directory", error: error)
                }
            }
            
        } catch {
            Log.error(message: "Failed to list directory", error: error)
        }
    }
    
    fileprivate func controlCapacity() {
        if self.size <= self.capacity { return }
        
        let fileManager = FileManager.default
        let cachePath = self.path
        fileManager.enumerateContentsOfDirectory(atPath: cachePath, orderedByProperty: URLResourceKey.contentModificationDateKey.rawValue, ascending: true) { (URL : URL, _, stop : inout Bool) -> Void in
            
            self.removeFile(atPath: URL.path)

            stop = self.size <= self.capacity
        }
    }
    
    fileprivate func setDataSync(_ data: Data, key: String) {
        let path = self.path(forKey: key)
        let fileManager = FileManager.default
        let previousAttributes : [FileAttributeKey: Any]? = try? fileManager.attributesOfItem(atPath: path)
        
        do {
            try data.write(to: URL(fileURLWithPath: path), options: Data.WritingOptions.atomicWrite)
        } catch {
            Log.error(message: "Failed to write key \(key)", error: error)
        }
        
        if let attributes = previousAttributes {
            if let fileSize = attributes[FileAttributeKey.size] as? UInt64 {
                substract(size: fileSize)
            }
        }
        self.size += UInt64(data.count)
        self.controlCapacity()
    }
    
    fileprivate func updateDiskAccessDate(atPath path: String) -> Bool {
        let fileManager = FileManager.default
        let now = Date()
        do {
            try fileManager.setAttributes([FileAttributeKey.modificationDate : now], ofItemAtPath: path)
            return true
        } catch {
            Log.error(message: "Failed to update access date", error: error)
            return false
        }
    }
    
    fileprivate func removeFile(atPath path: String) {
        let fileManager = FileManager.default
        do {
            let attributes: [FileAttributeKey: Any] = try fileManager.attributesOfItem(atPath: path)
            do {
                try fileManager.removeItem(atPath: path)
                if let fileSize = attributes[FileAttributeKey.size] as? UInt64 {
                    substract(size: fileSize)
                }
            } catch {
                Log.error(message: "Failed to remove file", error: error)
            }
        } catch {
            if isNoSuchFileError(error) {
                Log.debug(message: "File not found", error: error)
            } else {
                Log.error(message: "Failed to remove file", error: error)
            }
        }
    }

    fileprivate func substract(size : UInt64) {
        if (self.size >= size) {
            self.size -= size
        } else {
            Log.error(message: "Disk cache size (\(self.size)) is smaller than size to substract (\(size))")
            self.size = 0
        }
    }
}

private func isNoSuchFileError(_ error : Error?) -> Bool {
    if let error = error {
        return NSCocoaErrorDomain == (error as NSError).domain && (error as NSError).code == NSFileReadNoSuchFileError
    }
    return false
}
