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
    
    let cache = NSCache()
    
    let memoryWarningObserver : NSObjectProtocol?
    
    public init () {
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
    
    // Notifications
    
    func onMemoryWarning() {
        cache.removeAllObjects()
    }
}
