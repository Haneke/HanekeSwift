//
//  Cache.swift
//  Haneke
//
//  Created by Luis Ascorbe on 23/07/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import Foundation
import UIKit

public let OriginalFormatName = "original"

public class Cache {
    
    public enum ErrorCode : Int {
        case ObjectNotFound = -100
        case FormatNotFound = -101
    }
    
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
        
        var originalFormat = Format(OriginalFormatName, diskCapacity : UINT64_MAX)
        self.addFormat(originalFormat)
    }
    
    deinit {
        let notifications = NSNotificationCenter.defaultCenter()
        notifications.removeObserver(memoryWarningObserver, name: UIApplicationDidReceiveMemoryWarningNotification, object: nil)
    }
    
    public func setImage (image: UIImage, _ key: String, formatName : String = OriginalFormatName) {
        if let (format, memoryCache, diskCache) = self.formats[formatName] {
            memoryCache.setObject(image, forKey: key)
            // Image data is sent as @autoclosure to be executed in the disk cache queue.
            diskCache.setData(image.hnk_data(compressionQuality: format.compressionQuality), key: key)
        } else {
            assertionFailure("Can't set image before adding format")
        }
    }
    
    public func fetchImageForKey(key : String, formatName : String = OriginalFormatName,  success doSuccess : (UIImage) -> (), failure doFailure : ((NSError?) -> ())? = nil) -> Bool {
        if let (_, memoryCache, diskCache) = self.formats[formatName] {
            if let image = memoryCache.objectForKey(key) as? UIImage {
                doSuccess(image)
                return true
                // TODO: Update disk cache access date
            } else {
                self.fetchFromDiskCache(diskCache, key: key, memoryCache: memoryCache,  success: doSuccess, failure: doFailure)
            }
        } else if let block = doFailure {
            let localizedFormat = NSLocalizedString("Format %@ not found", comment: "Error description")
            let description = String(format:localizedFormat, formatName)
            let error = Haneke.errorWithCode(ErrorCode.FormatNotFound.toRaw(), description: description)
            block(error)
        }
        return false
    }
    
    public func fetchImageForEntity(entity : Fetcher, formatName : String = OriginalFormatName, success doSuccess : (UIImage) -> (), failure doFailure : ((NSError?) -> ())? = nil) -> Bool {
        let key = entity.key
        let didSuccess = self.fetchImageForKey(key, formatName: formatName,  success: doSuccess, failure: { error in
            if error?.code == ErrorCode.FormatNotFound.toRaw() {
                doFailure?(error)
                return
            }
            
            if let (format, _, _) = self.formats[formatName] {
                self.fetchImageFromEntity(entity, format: format, success: doSuccess, failure: doFailure)
            }
            
            // Unreachable code. Formats can't be removed from Cache.
        })
        return didSuccess
    }

    public func removeImage(key : String, formatName : String = OriginalFormatName) {
        if let (_, memoryCache, diskCache) = self.formats[formatName] {
            memoryCache.removeObjectForKey(key)
            diskCache.removeData(key)
        }
    }
    
    public func removeAllImages() {
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

    var formats : [String : (Format, NSCache, DiskCache)] = [:]
    
    public func addFormat(format : Format) {
        let name = self.name
        let memoryCache = NSCache()
        let diskCache = DiskCache(name, capacity : format.diskCapacity)
        self.formats[format.name] = (format, memoryCache, diskCache)
    }
    
    // MARK: Private
    
    private func fetchFromDiskCache(diskCache : DiskCache, key : String, memoryCache : NSCache,  success doSuccess : (UIImage) -> (), failure doFailure : ((NSError?) -> ())?) {
        diskCache.fetchData(key, success: { data in
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                let image = UIImage(data : data)
                let decompressedImage = image.hnk_decompressedImage()
                dispatch_async(dispatch_get_main_queue(), {
                    doSuccess(image)
                    memoryCache.setObject(decompressedImage, forKey: key)
                })
            })
        }, failure: { error in
            if let block = doFailure {
                if (error?.code == NSFileReadNoSuchFileError) {
                    let localizedFormat = NSLocalizedString("Object not found for key %@", comment: "Error description")
                    let description = String(format:localizedFormat, key)
                    let error = Haneke.errorWithCode(ErrorCode.ObjectNotFound.toRaw(), description: description)
                    block(error)
                } else {
                    block(error)
                }
            }
        })
    }
    
    private func fetchImageFromEntity(entity : Fetcher, format : Format, success doSuccess : (UIImage) -> (), failure doFailure : ((NSError?) -> ())?) {
        entity.fetchWithSuccess(success: { result in
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
                let image = result as UIImage
                var formattedImage = format.apply(image)
                if (formattedImage == image) {
                    // TODO: formattedImage = image.hnk_decompressedImage()
                }
                dispatch_async(dispatch_get_main_queue(), {
                    doSuccess(formattedImage)
                    self.setImage(formattedImage, entity.key, formatName: format.name)
                })
            })
        }, failure: { error in
            let _ = doFailure?(error)
        })
    }
    
}
