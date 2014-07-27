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
    
    public init () {
        
    }
    
    public func setImage (image: UIImage, _ key: String) {
        cache.setObject(image, forKey: key)
    }
    
    public func fetchImage (key : String) -> UIImage! {
        return cache.objectForKey(key) as UIImage!
    }
}
