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

public class Cache {
    
    let name : String
    
    let memoryCache = NSCache()
    
    let diskCache : DiskCache
    
    let memoryWarningObserver : NSObjectProtocol?
    
    lazy var path : String = {
        let cachesPath = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.CachesDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0] as String
        let hanekePathComponent = "io.haneke";
        let hanekePath = cachesPath.stringByAppendingPathComponent(hanekePathComponent)
        let path = hanekePath.stringByAppendingPathComponent(self.name)
        return path
    }()
    
    public init(_ name : String) {
        self.name = name
        self.diskCache = DiskCache(self.name)

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
        notifications.removeObserver(memoryWarningObserver, name: UIApplicationDidReceiveMemoryWarningNotification, object: nil)
    }
    
    public func setImage (image: UIImage, _ key: String) {
        memoryCache.setObject(image, forKey: key)
        // Image data is sent as @autoclosure to be executed in the disk cache queue.
        diskCache.setData(image.hnk_data(), key: key)
    }
    
    public func fetchImage (key : String?) -> UIImage! {
        var image = memoryCache.objectForKey(key) as UIImage!
        if !image {
            let imageData = diskCache.getData(key)
            image = UIImage(data: imageData)
            memoryCache.setObject(image, forKey: key)
        }
        return image;
    }

    public func removeImage(key : String) {
        memoryCache.removeObjectForKey(key)
        diskCache.removeData(key)
    }
    
    // MARK: Notifications
    
    func onMemoryWarning() {
        memoryCache.removeAllObjects()
    }

    // MARK: Utils

    func pathForKey(key : String) -> String {
        return path.stringByAppendingPathComponent(key);
    }
}
