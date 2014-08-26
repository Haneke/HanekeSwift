//
//  Cache.swift
//  Haneke
//
//  Created by Luis Ascorbe on 23/07/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import Foundation
import UIKit
import Haneke

let OriginalFormatName = "original"

public class Cache {
    
    let name : String
    
    let memoryWarningObserver : NSObjectProtocol?
    
    public init(_ name : String) {
        self.name = name

        self.registerFormat(Format(OriginalFormatName))
        
        let notifications = NSNotificationCenter.defaultCenter()
        // Using block-based observer to avoid subclassing NSObject
        memoryWarningObserver = notifications.addObserverForName(UIApplicationDidReceiveMemoryWarningNotification,
            object: nil,
            queue: NSOperationQueue.mainQueue(),
            usingBlock: { [unowned self] (notification : NSNotification!) -> Void in
                self.onMemoryWarning()
            }
        )
    }
    
    deinit {
        let notifications = NSNotificationCenter.defaultCenter()
        notifications.removeObserver(memoryWarningObserver!, name: UIApplicationDidReceiveMemoryWarningNotification, object: nil)
    }
    
    public func setImage (image: UIImage, _ key: String, formatName : String = OriginalFormatName) {
        if let (_, memoryCache, diskCache) = self.formats[formatName] {
            memoryCache.setObject(image, forKey: key)
            // Image data is sent as @autoclosure to be executed in the disk cache queue.
            diskCache.setData(image.hnk_data(), key: key)
        }
    }
    
    public func fetchImage (key : String, formatName : String = OriginalFormatName) -> UIImage? {
        if let (_, memoryCache, diskCache) = self.formats[formatName] {
            return memoryCache.objectForKey(key) as UIImage!
        }
        return nil
    }

    public func removeImage(key : String, formatName : String = OriginalFormatName) {
        if let (_, memoryCache, diskCache) = self.formats[formatName] {
            memoryCache.removeObjectForKey(key)
            diskCache.removeData(key)
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
    
    public func registerFormat(format : Format) {
        let name = self.name
        let memoryCache = NSCache()
        let diskCache = DiskCache(name)
        self.formats[format.name] = (format, memoryCache, diskCache)
    }
    
}
