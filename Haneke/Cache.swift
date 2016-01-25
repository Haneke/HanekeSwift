//
//  Cache.swift
//  Haneke
//
//  Created by Luis Ascorbe on 23/07/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import UIKit

// Used to add T to NSCache
class ObjectWrapper : NSObject {
    let value: Any
    
    init(value: Any) {
        self.value = value
    }
}

extension HanekeGlobals {
    
    // It'd be better to define this in the Cache class but Swift doesn't allow statics in a generic type
    public struct Cache {
        
        public static let OriginalFormatName = "original"

        public enum ErrorCode : Int {
            case ObjectNotFound = -100
            case FormatNotFound = -101
        }
        
    }
    
}

public class Cache<T: DataConvertible where T.Result == T, T : DataRepresentable> {
    
    let name: String
    
    var memoryWarningObserver : NSObjectProtocol!
    
    public init(name: String) {
        self.name = name
        
        let notifications = NSNotificationCenter.defaultCenter()
        // Using block-based observer to avoid subclassing NSObject
        memoryWarningObserver = notifications.addObserverForName(UIApplicationDidReceiveMemoryWarningNotification,
            object: nil,
            queue: NSOperationQueue.mainQueue(),
            usingBlock: { [unowned self] (notification : NSNotification!) -> Void in
                self.onMemoryWarning()
            }
        )
        
        let originalFormat = Format<T>(name: HanekeGlobals.Cache.OriginalFormatName)
        self.addFormat(originalFormat)
    }
    
    deinit {
        let notifications = NSNotificationCenter.defaultCenter()
        notifications.removeObserver(memoryWarningObserver, name: UIApplicationDidReceiveMemoryWarningNotification, object: nil)
    }
    
    public func set(value value: T, key: String, formatName: String = HanekeGlobals.Cache.OriginalFormatName, success succeed: ((T) -> ())? = nil) {
        if let (format, memoryCache, diskCache) = self.formats[formatName] {
            self.format(value: value, format: format) { formattedValue in
                let wrapper = ObjectWrapper(value: formattedValue)
                memoryCache.setObject(wrapper, forKey: key)
                // Value data is sent as @autoclosure to be executed in the disk cache queue.
                diskCache.setData(self.dataFromValue(formattedValue, format: format), key: key)
                succeed?(formattedValue)
            }
        } else {
            assertionFailure("Can't set value before adding format")
        }
    }
    
    public func fetch(key key: String, formatName: String = HanekeGlobals.Cache.OriginalFormatName, failure fail : Fetch<T>.Failer? = nil, success succeed : Fetch<T>.Succeeder? = nil) -> Fetch<T> {
        let fetch = Cache.buildFetch(failure: fail, success: succeed)
        if let (format, memoryCache, diskCache) = self.formats[formatName] {
            if let wrapper = memoryCache.objectForKey(key) as? ObjectWrapper, let result = wrapper.value as? T {
                fetch.succeed(result)
                diskCache.updateAccessDate(self.dataFromValue(result, format: format), key: key)
                return fetch
            }

            self.fetchFromDiskCache(diskCache, key: key, memoryCache: memoryCache, failure: { error in
                fetch.fail(error)
            }) { value in
                fetch.succeed(value)
            }

        } else {
            let localizedFormat = NSLocalizedString("Format %@ not found", comment: "Error description")
            let description = String(format:localizedFormat, formatName)
            let error = errorWithCode(HanekeGlobals.Cache.ErrorCode.FormatNotFound.rawValue, description: description)
            fetch.fail(error)
        }
        return fetch
    }
    
    public func fetch(fetcher fetcher : Fetcher<T>, formatName: String = HanekeGlobals.Cache.OriginalFormatName, failure fail : Fetch<T>.Failer? = nil, success succeed : Fetch<T>.Succeeder? = nil) -> Fetch<T> {
        let key = fetcher.key
        let fetch = Cache.buildFetch(failure: fail, success: succeed)
        self.fetch(key: key, formatName: formatName, failure: { error in
            if error?.code == HanekeGlobals.Cache.ErrorCode.FormatNotFound.rawValue {
                fetch.fail(error)
            }
            
            if let (format, _, _) = self.formats[formatName] {
                self.fetchAndSet(fetcher, format: format, failure: {error in
                    fetch.fail(error)
                }) {value in
                    fetch.succeed(value)
                }
            }
            
            // Unreachable code. Formats can't be removed from Cache.
        }) { value in
            fetch.succeed(value)
        }
        return fetch
    }

    public func remove(key key: String, formatName: String = HanekeGlobals.Cache.OriginalFormatName) {
        if let (_, memoryCache, diskCache) = self.formats[formatName] {
            memoryCache.removeObjectForKey(key)
            diskCache.removeData(key)
        }
    }
    
    public func removeAllForKey(key: String) {
        let group = dispatch_group_create()
        for (_, (_, memoryCache, diskCache)) in self.formats {
            memoryCache.removeObjectForKey(key)
            dispatch_group_enter(group)
            diskCache.removeData(key) {
                dispatch_group_leave(group)
            }
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            let timeout = dispatch_time(DISPATCH_TIME_NOW, Int64(60 * NSEC_PER_SEC))
            if dispatch_group_wait(group, timeout) != 0 {
                Log.error("removeData timed out waiting for disk caches")
            }
            let fileManager = NSFileManager.defaultManager()
            let cachePath = self.cachePath
            do {
                let formatDirsNames = try fileManager.contentsOfDirectoryAtPath(cachePath)
                for formatDirName in formatDirsNames {
                    let formatPath = (cachePath as NSString).stringByAppendingPathComponent(formatDirName)
                    var isDirectory: ObjCBool = false
                    fileManager.fileExistsAtPath(formatPath, isDirectory: &isDirectory)
                    if isDirectory.boolValue {
                        let filenames = try fileManager.contentsOfDirectoryAtPath(formatPath)
                        for filename in filenames {
                            if key == filename {
                                do{
                                    let filePath = (formatPath as NSString).stringByAppendingPathComponent(filename)
                                    Log.debug("Removing cache file: \(filePath)")
                                    try fileManager.removeItemAtPath(filePath)
                                }
                                catch let error as NSError {
                                    Log.error("Failed to delete cached file with key \(key)", error as NSError)
                                }
                            }
                        }
                    }
                }
            } catch {
                Log.error("Failed to list directory",error as NSError)
            }
        }
    }
    
    public func removeAll(completion: (() -> ())? = nil) {
        let group = dispatch_group_create();
        for (_, (_, memoryCache, diskCache)) in self.formats {
            memoryCache.removeAllObjects()
            dispatch_group_enter(group)
            diskCache.removeAllData {
                dispatch_group_leave(group)
            }
        }
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            let timeout = dispatch_time(DISPATCH_TIME_NOW, Int64(60 * NSEC_PER_SEC))
            if dispatch_group_wait(group, timeout) != 0 {
                Log.error("removeAll timed out waiting for disk caches")
            }
            let path = self.cachePath
            do {
                try NSFileManager.defaultManager().removeItemAtPath(path)
            } catch {
                Log.error("Failed to remove path \(path)", error as NSError)
            }
            if let completion = completion {
                dispatch_async(dispatch_get_main_queue()) {
                    completion()
                }
            }
        }
    }

    // MARK: Notifications
    
    func onMemoryWarning() {
        for (_, (_, memoryCache, _)) in self.formats {
            memoryCache.removeAllObjects()
        }
    }
    
    // MARK: Formats

    var formats : [String : (Format<T>, NSCache, DiskCache)] = [:]
    
    public func addFormat(format : Format<T>) {
        let name = format.name
        let formatPath = self.formatPath(formatName: name)
        let memoryCache = NSCache()
        let diskCache = DiskCache(path: formatPath, capacity : format.diskCapacity)
        self.formats[name] = (format, memoryCache, diskCache)
    }
    
    // MARK: Internal
    
    lazy var cachePath: String = {
        let basePath = DiskCache.basePath()
        let cachePath = (basePath as NSString).stringByAppendingPathComponent(self.name)
        return cachePath
    }()
    
    func formatPath(formatName formatName: String) -> String {
        let formatPath = (self.cachePath as NSString).stringByAppendingPathComponent(formatName)
        do {
            try NSFileManager.defaultManager().createDirectoryAtPath(formatPath, withIntermediateDirectories: true, attributes: nil)
        } catch {
            Log.error("Failed to create directory \(formatPath)", error as NSError)
        }
        return formatPath
    }
    
    // MARK: Private
    
    func dataFromValue(value : T, format : Format<T>) -> NSData? {
        if let data = format.convertToData?(value) {
            return data
        }
        return value.asData()
    }
    
    private func fetchFromDiskCache(diskCache : DiskCache, key: String, memoryCache : NSCache, failure fail : ((NSError?) -> ())?, success succeed : (T) -> ()) {
        diskCache.fetchData(key: key, failure: { error in
            if let block = fail {
                if (error?.code == NSFileReadNoSuchFileError) {
                    let localizedFormat = NSLocalizedString("Object not found for key %@", comment: "Error description")
                    let description = String(format:localizedFormat, key)
                    let error = errorWithCode(HanekeGlobals.Cache.ErrorCode.ObjectNotFound.rawValue, description: description)
                    block(error)
                } else {
                    block(error)
                }
            }
        }) { data in
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                let value = T.convertFromData(data)
                if let value = value {
                    let descompressedValue = self.decompressedImageIfNeeded(value)
                    dispatch_async(dispatch_get_main_queue(), {
                        succeed(descompressedValue)
                        let wrapper = ObjectWrapper(value: descompressedValue)
                        memoryCache.setObject(wrapper, forKey: key)
                    })
                }
            })
        }
    }
    
    private func fetchAndSet(fetcher : Fetcher<T>, format : Format<T>, failure fail : ((NSError?) -> ())?, success succeed : (T) -> ()) {
        fetcher.fetch(failure: { error in
            let _ = fail?(error)
        }) { value in
            self.set(value: value, key: fetcher.key, formatName: format.name, success: succeed)
        }
    }
    
    private func format(value value : T, format : Format<T>, success succeed : (T) -> ()) {
        // HACK: Ideally Cache shouldn't treat images differently but I can't think of any other way of doing this that doesn't complicate the API for other types.
        if format.isIdentity && !(value is UIImage) {
            succeed(value)
        } else {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                var formatted = format.apply(value)
                
                if let formattedImage = formatted as? UIImage {
                    let originalImage = value as? UIImage
                    if formattedImage === originalImage {
                        formatted = self.decompressedImageIfNeeded(formatted)
                    }
                }
                
                dispatch_async(dispatch_get_main_queue()) {
                    succeed(formatted)
                }
            }
        }
    }
    
    private func decompressedImageIfNeeded(value : T) -> T {
        if let image = value as? UIImage {
            let decompressedImage = image.hnk_decompressedImage() as? T
            return decompressedImage!
        }
        return value
    }
    
    private class func buildFetch(failure fail : Fetch<T>.Failer? = nil, success succeed : Fetch<T>.Succeeder? = nil) -> Fetch<T> {
        let fetch = Fetch<T>()
        if let succeed = succeed {
            fetch.onSuccess(succeed)
        }
        if let fail = fail {
            fetch.onFailure(fail)
        }
        return fetch
    }
    
    // MARK: Convenience fetch
    // Ideally we would put each of these in the respective fetcher file as a Cache extension. Unfortunately, this fails to link when using the framework in a project as of Xcode 6.1.
    
    public func fetch(key key: String, @autoclosure(escaping) value getValue : () -> T.Result, formatName: String = HanekeGlobals.Cache.OriginalFormatName, success succeed : Fetch<T>.Succeeder? = nil) -> Fetch<T> {
        let fetcher = SimpleFetcher<T>(key: key, value: getValue)
        return self.fetch(fetcher: fetcher, formatName: formatName, success: succeed)
    }
    
    public func fetch(path path: String, formatName: String = HanekeGlobals.Cache.OriginalFormatName,  failure fail : Fetch<T>.Failer? = nil, success succeed : Fetch<T>.Succeeder? = nil) -> Fetch<T> {
        let fetcher = DiskFetcher<T>(path: path)
        return self.fetch(fetcher: fetcher, formatName: formatName, failure: fail, success: succeed)
    }
    
    public func fetch(URL URL : NSURL, formatName: String = HanekeGlobals.Cache.OriginalFormatName,  failure fail : Fetch<T>.Failer? = nil, success succeed : Fetch<T>.Succeeder? = nil) -> Fetch<T> {
        let fetcher = NetworkFetcher<T>(URL: URL)
        return self.fetch(fetcher: fetcher, formatName: formatName, failure: fail, success: succeed)
    }
    
}
