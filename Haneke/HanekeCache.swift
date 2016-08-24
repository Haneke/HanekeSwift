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
    let hnk_value: Any
    
    init(value: Any) {
        self.hnk_value = value
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

// In order to not conflict with upcoming `Cache` naming convention for Swift3, name changed to HanekeCache
open class HanekeCache<T: DataConvertible> where T.Result == T, T : DataRepresentable {
    
    let name: String
    
    var memoryWarningObserver : NSObjectProtocol!
    
    public init(name: String) {
        self.name = name
        
        let notifications = NotificationCenter.default
        // Using block-based observer to avoid subclassing NSObject
        memoryWarningObserver = notifications.addObserver(forName: Notification.Name.UIApplicationDidReceiveMemoryWarning,
            object: nil,
            queue: OperationQueue.main,
            using: { [unowned self] (notification : Notification!) -> Void in
                self.onMemoryWarning()
            }
        )
        
        let originalFormat = Format<T>(name: HanekeGlobals.Cache.OriginalFormatName)
        self.addFormat(originalFormat)
    }
    
    deinit {
        let notifications = NotificationCenter.default
        notifications.removeObserver(memoryWarningObserver, name: Notification.Name.UIApplicationDidReceiveMemoryWarning, object: nil)
    }
    
    open func set(value: T, key: String, formatName: String = HanekeGlobals.Cache.OriginalFormatName, success succeed: ((T) -> ())? = nil) {
        if let (format, memoryCache, diskCache) = self.formats[formatName] {
            self.format(value: value, format: format) { formattedValue in
                let wrapper = ObjectWrapper(value: formattedValue)
                memoryCache.setObject(wrapper, forKey: key as AnyObject)
                // Value data is sent as @autoclosure to be executed in the disk cache queue.
                diskCache.setData(self.dataFromValue(formattedValue, format: format), key: key)
                succeed?(formattedValue)
            }
        } else {
            assertionFailure("Can't set value before adding format")
        }
    }
    
    open func fetch(key: String, formatName: String = HanekeGlobals.Cache.OriginalFormatName, failure fail : Fetch<T>.Failer? = nil, success succeed : Fetch<T>.Succeeder? = nil) -> Fetch<T> {
        let fetch = HanekeCache.buildFetch(failure: fail, success: succeed)
        if let (format, memoryCache, diskCache) = self.formats[formatName] {
            if let wrapper = memoryCache.object(forKey: key as AnyObject) as? ObjectWrapper, let result = wrapper.hnk_value as? T {
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
            let error = errorWithCode(HanekeGlobals.Cache.ErrorCode.formatNotFound.rawValue, description: description)
            fetch.fail(error)
        }
        return fetch
    }
    
    open func fetch(fetcher : Fetcher<T>, formatName: String = HanekeGlobals.Cache.OriginalFormatName, failure fail : Fetch<T>.Failer? = nil, success succeed : Fetch<T>.Succeeder? = nil) -> Fetch<T> {
        let key = fetcher.key
        let fetch = HanekeCache.buildFetch(failure: fail, success: succeed)
        self.fetch(key: key, formatName: formatName, failure: { error in
            if (error as? NSError)?.code == HanekeGlobals.Cache.ErrorCode.formatNotFound.rawValue {
                fetch.fail(error)
            }
            
            if let (format, _, _) = self.formats[formatName] {
                self.fetchAndSet(fetcher, format: format, failure: { error in
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

    open func remove(key: String, formatName: String = HanekeGlobals.Cache.OriginalFormatName) {
        if let (_, memoryCache, diskCache) = self.formats[formatName] {
            memoryCache.removeObject(forKey: key as AnyObject)
            diskCache.removeData(with: key)
        }
    }
    
    open func removeAll(_ completion: (() -> ())? = nil) {
        let group = DispatchGroup()
        for (_, (_, memoryCache, diskCache)) in self.formats {
            memoryCache.removeAllObjects()
            group.enter()
            diskCache.removeAllData {
                group.leave()
            }
        }
        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
            let timeout = DispatchTime.now() + Double(Int64(60 * NSEC_PER_SEC)) / Double(NSEC_PER_SEC)
            if group.wait(timeout: timeout) != .success {
                Log.error(message: "removeAll timed out waiting for disk caches")
            }
            let path = self.cachePath
            do {
                try FileManager.default.removeItem(atPath: path)
            } catch {
                Log.error(message: "Failed to remove path \(path)", error: error)
            }
            if let completion = completion {
                DispatchQueue.main.async {
                    completion()
                }
            }
        }
    }

    // MARK: Size

    open var size: UInt64 {
        var size: UInt64 = 0
        for (_, (_, _, diskCache)) in self.formats {
            diskCache.cacheQueue.sync { size += diskCache.size }
        }
        return size
    }

    // MARK: Notifications
    
    func onMemoryWarning() {
        for (_, (_, memoryCache, _)) in self.formats {
            memoryCache.removeAllObjects()
        }
    }
    
    // MARK: Formats

    var formats : [String : (Format<T>, NSCache<AnyObject, AnyObject>, DiskCache)] = [:]
    
    open func addFormat(_ format : Format<T>) {
        let name = format.name
        let formatPath = self.formatPath(withFormatName: name)
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
    
    func formatPath(withFormatName formatName: String) -> String {
        let formatPath = (self.cachePath as NSString).appendingPathComponent(formatName)
        do {
            try FileManager.default.createDirectory(atPath: formatPath, withIntermediateDirectories: true, attributes: nil)
        } catch {
            Log.error(message: "Failed to create directory \(formatPath)", error: error)
        }
        return formatPath
    }
    
    // MARK: Private
    
    func dataFromValue(_ value : T, format : Format<T>) -> Data? {
        if let data = format.convertToData?(value) {
            return data as Data
        }
        return value.asData()
    }
    
    fileprivate func fetchFromDiskCache(_ diskCache : DiskCache, key: String, memoryCache : NSCache<AnyObject, AnyObject>, failure fail : ((Error?) -> ())?, success succeed : @escaping (T) -> ()) {
        diskCache.fetchData(key: key, failure: { error in
            if let block = fail {
                if (error as? NSError)?.code == NSFileReadNoSuchFileError {
                    let localizedFormat = NSLocalizedString("Object not found for key %@", comment: "Error description")
                    let description = String(format:localizedFormat, key)
                    let error = errorWithCode(HanekeGlobals.Cache.ErrorCode.objectNotFound.rawValue, description: description)
                    block(error)
                } else {
                    block(error)
                }
            }
        }) { data in
            DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async(execute: {
                let value = T.convertFromData(data)
                if let value = value {
                    let descompressedValue = self.decompressedImageIfNeeded(value)
                    DispatchQueue.main.async(execute: {
                        succeed(descompressedValue)
                        let wrapper = ObjectWrapper(value: descompressedValue)
                        memoryCache.setObject(wrapper, forKey: key as AnyObject)
                    })
                }
            })
        }
    }
    
    fileprivate func fetchAndSet(_ fetcher : Fetcher<T>, format : Format<T>, failure fail : ((Error?) -> ())?, success succeed : @escaping (T) -> ()) {
        fetcher.fetch(failure: { error in
            let _ = fail?(error)
        }) { value in
            self.set(value: value, key: fetcher.key, formatName: format.name, success: succeed)
        }
    }
    
    fileprivate func format(value : T, format : Format<T>, success succeed : @escaping (T) -> ()) {
        // HACK: Ideally Cache shouldn't treat images differently but I can't think of any other way of doing this that doesn't complicate the API for other types.
        if format.isIdentity && !(value is UIImage) {
            succeed(value)
        } else {
            DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
                var formatted = format.apply(value)
                
                if let formattedImage = formatted as? UIImage {
                    let originalImage = value as? UIImage
                    if formattedImage === originalImage {
                        formatted = self.decompressedImageIfNeeded(formatted)
                    }
                }
                
                DispatchQueue.main.async {
                    succeed(formatted)
                }
            }
        }
    }
    
    fileprivate func decompressedImageIfNeeded(_ value : T) -> T {
        if let image = value as? UIImage {
            let decompressedImage = image.hnk_decompressedImage() as? T
            return decompressedImage!
        }
        return value
    }
    
    fileprivate class func buildFetch(failure fail : Fetch<T>.Failer? = nil, success succeed : Fetch<T>.Succeeder? = nil) -> Fetch<T> {
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
    
    open func fetch(key: String, value getValue : @autoclosure @escaping () -> T.Result, formatName: String = HanekeGlobals.Cache.OriginalFormatName, success succeed : Fetch<T>.Succeeder? = nil) -> Fetch<T> {
        let fetcher = SimpleFetcher<T>(key: key, value: getValue)
        return self.fetch(fetcher: fetcher, formatName: formatName, success: succeed)
    }
    
    open func fetch(path: String, formatName: String = HanekeGlobals.Cache.OriginalFormatName,  failure fail : Fetch<T>.Failer? = nil, success succeed : Fetch<T>.Succeeder? = nil) -> Fetch<T> {
        let fetcher = DiskFetcher<T>(path: path)
        return self.fetch(fetcher: fetcher, formatName: formatName, failure: fail, success: succeed)
    }
    
    open func fetch(URL : Foundation.URL, formatName: String = HanekeGlobals.Cache.OriginalFormatName,  failure fail : Fetch<T>.Failer? = nil, success succeed : Fetch<T>.Succeeder? = nil) -> Fetch<T> {
        let fetcher = NetworkFetcher<T>(URL: URL)
        return self.fetch(fetcher: fetcher, formatName: formatName, failure: fail, success: succeed)
    }
    
}
