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

extension Haneke {
    // It'd be better to define this in the Cache class but Swift doesn't allow to declare an enum in a generic type
    public enum CacheError : Int {
        case ObjectNotFound = -100
        case FormatNotFound = -101
    }
}

public let OriginalFormatName = "original"

public class Cache<T : DataConvertible where T.Result == T, T : DataRepresentable> {
    
    let name : String
    
    let memoryWarningObserver : NSObjectProtocol!
    
    public init(_ name : String) {
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
        
        var originalFormat = Format<T>(OriginalFormatName, diskCapacity : UINT64_MAX)
        self.addFormat(originalFormat)
    }
    
    deinit {
        let notifications = NSNotificationCenter.defaultCenter()
        notifications.removeObserver(memoryWarningObserver, name: UIApplicationDidReceiveMemoryWarningNotification, object: nil)
    }
    
    public func setValue (value : T, _ key: String, formatName : String = OriginalFormatName) {
        if let (format, memoryCache, diskCache) = self.formats[formatName] {
            let wrapper = ObjectWrapper(value: value)
            memoryCache.setObject(wrapper, forKey: key)
            // Value data is sent as @autoclosure to be executed in the disk cache queue.
            diskCache.setData(dataFromValue(value, format: format), key: key)
        } else {
            assertionFailure("Can't set value before adding format")
        }
    }
    
    func dataFromValue(value : T, format : Format<T>) -> NSData? {
        if let data = format.convertToData?(value) {
            return data
        }
        return value.asData()
    }
    
    public func fetch(#key : String, formatName : String = OriginalFormatName, failure doFailure : Fetch<T>.Failer? = nil, success doSuccess : Fetch<T>.Succeeder? = nil) -> Fetch<T> {
        let fetch = Cache.buildFetch(failure: doFailure, success: doSuccess)
        if let (format, memoryCache, diskCache) = self.formats[formatName] {
            if let wrapper = memoryCache.objectForKey(key) as? ObjectWrapper {
                if let result = wrapper.value as? T {
                    fetch.succeed(result)
                    diskCache.updateAccessDate(dataFromValue(result, format: format), key: key)
                    return fetch
                }
            }

            self.fetchFromDiskCache(diskCache, key: key, memoryCache: memoryCache, failure: { error in
                fetch.fail(error)
            }) { value in
                fetch.succeed(value)
            }

        } else {
            let localizedFormat = NSLocalizedString("Format %@ not found", comment: "Error description")
            let description = String(format:localizedFormat, formatName)
            let error = Haneke.errorWithCode(Haneke.CacheError.FormatNotFound.toRaw(), description: description)
            fetch.fail(error)
        }
        return fetch
    }
    
    public func fetch(#fetcher : Fetcher<T>, formatName : String = OriginalFormatName, failure doFailure : Fetch<T>.Failer? = nil, success doSuccess : Fetch<T>.Succeeder? = nil) -> Fetch<T> {
        let key = fetcher.key
        let fetch = Cache.buildFetch(failure: doFailure, success: doSuccess)
        self.fetch(key: key, formatName: formatName, failure: { error in
            if error?.code == Haneke.CacheError.FormatNotFound.toRaw() {
                fetch.fail(error)
            }
            
            if let (format, _, _) = self.formats[formatName] {
                self.fetchValueFromFetcher(fetcher, format: format, failure: {error in
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

    public func removeValue(key : String, formatName : String = OriginalFormatName) {
        if let (_, memoryCache, diskCache) = self.formats[formatName] {
            memoryCache.removeObjectForKey(key)
            diskCache.removeData(key)
        }
    }
    
    public func removeAllValues() {
        for (_, (_, memoryCache, diskCache)) in self.formats {
            memoryCache.removeAllObjects()
            diskCache.removeAllData()
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
        let name = self.name
        let memoryCache = NSCache()
        let diskCache = DiskCache(name, capacity : format.diskCapacity)
        self.formats[format.name] = (format, memoryCache, diskCache)
    }
    
    // MARK: Private
    
    private func fetchFromDiskCache(diskCache : DiskCache, key : String, memoryCache : NSCache, failure doFailure : ((NSError?) -> ())?, success doSuccess : (T) -> ()) {
        diskCache.fetchData(key, failure: { error in
            if let block = doFailure {
                if (error?.code == NSFileReadNoSuchFileError) {
                    let localizedFormat = NSLocalizedString("Object not found for key %@", comment: "Error description")
                    let description = String(format:localizedFormat, key)
                    let error = Haneke.errorWithCode(Haneke.CacheError.ObjectNotFound.toRaw(), description: description)
                    block(error)
                } else {
                    block(error)
                }
            }
        }) { data in
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                var value = T.convertFromData(data)
                if let value = value {
                    let descompressedValue = self.decompressedImageIfNeeded(value)
                    dispatch_async(dispatch_get_main_queue(), {
                        doSuccess(descompressedValue)
                        let wrapper = ObjectWrapper(value: descompressedValue)
                        memoryCache.setObject(wrapper, forKey: key)
                    })
                }
            })
        }
    }
    
    private func fetchValueFromFetcher(fetcher : Fetcher<T>, format : Format<T>, failure doFailure : ((NSError?) -> ())?, success doSuccess : (T) -> ()) {
        fetcher.fetch(failure: { error in
            let _ = doFailure?(error)
        }) { value in
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                var formatted = format.apply(value)
                
                if let formattedImage = formatted as? UIImage {
                    let originalImage = value as? UIImage
                    if formattedImage === originalImage {
                        formatted = self.decompressedImageIfNeeded(formatted)
                    }
                }

                dispatch_async(dispatch_get_main_queue()) {
                    doSuccess(formatted)
                    self.setValue(formatted, fetcher.key, formatName: format.name)
                }
            }
        }
    }
    
    // HACK: Ideally Cache shouldn't treat images differently but I can't think of any other way of doing this that doesn't complicate the API for other types.
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
    
}
