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
        // It'd be better to define this in the NetworkFetcher class but Swift doesn't allow to declare an enum in a generic type
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
    
    public func fetchValueForKey(key : String, formatName : String = OriginalFormatName,  success doSuccess : (T) -> (), failure doFailure : ((NSError?) -> ())? = nil) -> Bool {
        if let (format, memoryCache, diskCache) = self.formats[formatName] {
            if let wrapper = memoryCache.objectForKey(key) as? ObjectWrapper {
                if let result = wrapper.value as? T {
                    doSuccess(result)
                    diskCache.updateAccessDate(dataFromValue(result, format: format), key: key)
                    return true
                }
            }

            self.fetchFromDiskCache(diskCache, key: key, memoryCache: memoryCache, success: doSuccess, failure: doFailure)

        } else if let block = doFailure {
            let localizedFormat = NSLocalizedString("Format %@ not found", comment: "Error description")
            let description = String(format:localizedFormat, formatName)
            let error = Haneke.errorWithCode(Haneke.CacheError.FormatNotFound.toRaw(), description: description)
            block(error)
        }
        return false
    }
    
    public func fetchValueForFetcher(fetcher : Fetcher<T>, formatName : String = OriginalFormatName, success doSuccess : (T) -> (), failure doFailure : ((NSError?) -> ())? = nil) -> Bool {
        let key = fetcher.key
        let didSuccess = self.fetchValueForKey(key, formatName: formatName,  success: doSuccess, failure: { error in
            if error?.code == Haneke.CacheError.FormatNotFound.toRaw() {
                doFailure?(error)
                return
            }
            
            if let (format, _, _) = self.formats[formatName] {
                self.fetchValueFromFetcher(fetcher, format: format, success: doSuccess, failure: doFailure)
            }
            
            // Unreachable code. Formats can't be removed from Cache.
        })
        return didSuccess
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
    
    private func fetchFromDiskCache(diskCache : DiskCache, key : String, memoryCache : NSCache,  success doSuccess : (T) -> (), failure doFailure : ((NSError?) -> ())?) {
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
    
    private func fetchValueFromFetcher(fetcher : Fetcher<T>, format : Format<T>, success doSuccess : (T) -> (), failure doFailure : ((NSError?) -> ())?) {
        fetcher.fetch(failure: { error in
            let _ = doFailure?(error)
        }) { value in
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                var formatted = format.apply(value)
                
                if let formattedImage = formatted as? UIImage {
                    let originalImage = value as? UIImage
                    if formattedImage === originalImage {
                        formatted = self.decompressedImageIfNeeded(formatted)
                    }
                }

                dispatch_async(dispatch_get_main_queue(), {
                    doSuccess(formatted)
                    self.setValue(formatted, fetcher.key, formatName: format.name)
                })
            })
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
    
}
