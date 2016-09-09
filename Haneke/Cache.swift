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
    let h_value: Any
    
    init(value: Any) {
        self.h_value = value
    }
}

extension HanekeGlobals {
    
    // It'd be better to define this in the Cache class but Swift doesn't allow statics in a generic type
    public struct Cache {
        
        public static let OriginalFormatName = "original"

        public enum ErrorCode : Int {
            case objectNotFound = -100
            case formatNotFound = -101
        }
        
    }
    
}

public class Cache<T: DataConvertible where T.Result == T, T : DataRepresentable> {
    
    let name: String
    
    var memoryWarningObserver : NSObjectProtocol!
    
    public init(name: String) {
        self.name = name
        
        let notifications = NotificationCenter.default
        // Using block-based observer to avoid subclassing NSObject
        memoryWarningObserver = notifications.addObserver(forName: NSNotification.Name.UIApplicationDidReceiveMemoryWarning,
                                                          object: nil,
                                                          queue: OperationQueue.main,
                                                          using: { [unowned self] (notification : Notification!) -> Void in
                self.onMemoryWarning()
            }
        )
        
        let originalFormat = Format<T>(name: HanekeGlobals.Cache.OriginalFormatName)
        self.addFormat(format: originalFormat)
    }
    
    deinit {
        let notifications = NotificationCenter.default
        notifications.removeObserver(memoryWarningObserver, name: NSNotification.Name.UIApplicationDidReceiveMemoryWarning, object: nil)
    }
    
    public func set(value: T, key: String, formatName: String = HanekeGlobals.Cache.OriginalFormatName, success succeed: ((T) -> ())? = nil) {
        if let (format, memoryCache, diskCache) = self.formats[formatName] {
            self.format(value: value, format: format) { formattedValue in
                let wrapper = ObjectWrapper(value: formattedValue)
                memoryCache.setObject(wrapper, forKey: key as AnyObject)
                // Value data is sent as @autoclosure to be executed in the disk cache queue.
                var dataFromValue = self.dataFromValue(value: formattedValue, format: format)
                diskCache.setData(getData: dataFromValue, key: key)
                succeed?(formattedValue)
            }
        } else {
            assertionFailure("Can't set value before adding format")
        }
    }
    
    public func fetch(key: String, formatName: String = HanekeGlobals.Cache.OriginalFormatName, failure fail : Fetch<T>.Failer? = nil, success succeed : Fetch<T>.Succeeder? = nil) -> Fetch<T> {
        let fetch = Cache.buildFetch(failure: fail, success: succeed)
        if let (format, memoryCache, diskCache) = self.formats[formatName] {
            if let wrapper = memoryCache.object(forKey: key as AnyObject) as? ObjectWrapper, let result = wrapper.h_value as? T {
                fetch.succeed(value: result)
                var dataFromValue = self.dataFromValue(value: result, format: format)
                diskCache.updateAccessDate(getData: dataFromValue, key: key)
                return fetch
            }

            self.fetchFromDiskCache(diskCache: diskCache, key: key, memoryCache: memoryCache, failure: { error in
                fetch.fail(error: error)
            }) { value in
                fetch.succeed(value: value)
            }

        } else {
            let localizedFormat = NSLocalizedString("Format %@ not found", comment: "Error description")
            let description = String(format:localizedFormat, formatName)
            let error = errorWithCode(code: HanekeGlobals.Cache.ErrorCode.formatNotFound.rawValue, description: description)
            fetch.fail(error: error)
        }
        return fetch
    }
    
    public func fetch(fetcher : Fetcher<T>, formatName: String = HanekeGlobals.Cache.OriginalFormatName, failure fail : Fetch<T>.Failer? = nil, success succeed : Fetch<T>.Succeeder? = nil) -> Fetch<T> {
        let key = fetcher.key
        let fetch = Cache.buildFetch(failure: fail, success: succeed)
        self.fetch(key: key, formatName: formatName, failure: { error in
            if error?.code == HanekeGlobals.Cache.ErrorCode.formatNotFound.rawValue {
                fetch.fail(error: error)
            }
            
            if let (format, _, _) = self.formats[formatName] {
                self.fetchAndSet(fetcher: fetcher, format: format, failure: {error in
                    fetch.fail(error: error)
                }) {value in
                    fetch.succeed(value: value)
                }
            }
            
            // Unreachable code. Formats can't be removed from Cache.
        }) { value in
            fetch.succeed(value: value)
        }
        return fetch
    }

    public func remove(key: String, formatName: String = HanekeGlobals.Cache.OriginalFormatName) {
        if let (_, memoryCache, diskCache) = self.formats[formatName] {
            memoryCache.removeObject(forKey: key as AnyObject)
            diskCache.removeData(key: key)
        }
    }
    
    public func removeAll() {
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

    var formats : [String : (Format<T>, NSCache<AnyObject, AnyObject>, DiskCache)] = [:]
    
    public func addFormat(format : Format<T>) {
        let name = format.name
        let formatPath = self.formatPath(formatName: name)
        let memoryCache = NSCache<AnyObject, AnyObject>()
        let diskCache = DiskCache(path: formatPath, capacity : format.diskCapacity)
        self.formats[name] = (format, memoryCache, diskCache)
    }
    
    // MARK: Internal
    
    lazy var cachePath: String = {
        let basePath = DiskCache.basePath()
        let cachePath = (basePath as NSString).appendingPathComponent(self.name)
        return cachePath
    }()
    
    func formatPath(formatName: String) -> String {
        let formatPath = (self.cachePath as NSString).appendingPathComponent(formatName)
        do {
            try FileManager.default.createDirectory(atPath: formatPath, withIntermediateDirectories: true, attributes: nil)
        } catch {
            Log.error(message: "Failed to create directory \(formatPath)", error: error as NSError)
        }
        return formatPath
    }
    
    // MARK: Private
    
    func dataFromValue(value : T, format : Format<T>) -> Data? {
        if let data = format.convertToData?(value) {
            return data 
        }
        return value.asData()
    }
    
    private func fetchFromDiskCache(diskCache : DiskCache, key: String, memoryCache : NSCache<AnyObject, AnyObject>, failure fail : ((NSError?) -> ())?, success succeed : @escaping (T) -> ()) {
        diskCache.fetchData(key: key, failure: { error in
            if let block = fail {
                if (error?.code == NSFileReadNoSuchFileError) {
                    let localizedFormat = NSLocalizedString("Object not found for key %@", comment: "Error description")
                    let description = String(format:localizedFormat, key)
                    let error = errorWithCode(code: HanekeGlobals.Cache.ErrorCode.objectNotFound.rawValue, description: description)
                    block(error)
                } else {
                    block(error)
                }
            }
        }) { data in
            DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
                let value = T.convertFromData(data: data)
                if let value = value {
                    let descompressedValue = self.decompressedImageIfNeeded(value: value)
                    DispatchQueue.main.async(execute: {
                        succeed(descompressedValue)
                        let wrapper = ObjectWrapper(value: descompressedValue)
                        memoryCache.setObject(wrapper, forKey: key as AnyObject)
                    })
                }
            }
        }
    }
    
    private func fetchAndSet(fetcher : Fetcher<T>, format : Format<T>, failure fail : ((NSError?) -> ())?, success succeed : @escaping (T) -> ()) {
        fetcher.fetch(failure: { error in
            let _ = fail?(error)
        }) { value in
            self.set(value: value, key: fetcher.key, formatName: format.name, success: succeed)
        }
    }
    
    private func format(value : T, format : Format<T>, success succeed : @escaping (T) -> ()) {
        // HACK: Ideally Cache shouldn't treat images differently but I can't think of any other way of doing this that doesn't complicate the API for other types.
        if format.isIdentity && !(value is UIImage) {
            succeed(value)
        } else {
            
            DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
                var formatted = format.apply(value: value)
                
                if let formattedImage = formatted as? UIImage {
                    let originalImage = value as? UIImage
                    if formattedImage === originalImage {
                        formatted = self.decompressedImageIfNeeded(value: formatted)
                    }
                }
                
                DispatchQueue.main.async {
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
            fetch.onSuccess(onSuccess: succeed)
        }
        if let fail = fail {
            fetch.onFailure(onFailure: fail)
        }
        return fetch
    }
    
    // MARK: Convenience fetch
    // Ideally we would put each of these in the respective fetcher file as a Cache extension. Unfortunately, this fails to link when using the framework in a project as of Xcode 6.1.
    
    public func fetch(key: String, value getValue : @autoclosure(escaping) () -> T.Result, formatName: String = HanekeGlobals.Cache.OriginalFormatName, success succeed : Fetch<T>.Succeeder? = nil) -> Fetch<T> {
        let fetcher = SimpleFetcher<T>(key: key, value: getValue)
        return self.fetch(fetcher: fetcher, formatName: formatName, success: succeed)
    }
    
    public func fetch(path: String, formatName: String = HanekeGlobals.Cache.OriginalFormatName,  failure fail : Fetch<T>.Failer? = nil, success succeed : Fetch<T>.Succeeder? = nil) -> Fetch<T> {
        let fetcher = DiskFetcher<T>(path: path)
        return self.fetch(fetcher: fetcher, formatName: formatName, failure: fail, success: succeed)
    }
    
    public func fetch(URL : NSURL, formatName: String = HanekeGlobals.Cache.OriginalFormatName,  failure fail : Fetch<T>.Failer? = nil, success succeed : Fetch<T>.Succeeder? = nil) -> Fetch<T> {
        let fetcher = NetworkFetcher<T>(URL: URL)
        return self.fetch(fetcher: fetcher, formatName: formatName, failure: fail, success: succeed)
    }
    
}
