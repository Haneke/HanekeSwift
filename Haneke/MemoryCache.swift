//
//  MemoryCache.swift
//  Haneke
//
//  Created by Luis Ascorbe on 23/07/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import Foundation
import UIKit

public class MemoryCache {
    
    let name : String
    
    let cache = NSCache()
    
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
        cache.setObject(image, forKey: key)
    }
    
    public func fetchImage (key : String?) -> UIImage! {
        return cache.objectForKey(key) as UIImage!
    }

    public func removeImage(key : String) {
        cache.removeObjectForKey(key)
    }
    
    // MARK: Notifications
    
    func onMemoryWarning() {
        cache.removeAllObjects()
    }
}
