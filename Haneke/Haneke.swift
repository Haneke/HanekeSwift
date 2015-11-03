//
//  Haneke.swift
//  Haneke
//
//  Created by Hermes Pique on 9/9/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import UIKit

public struct HanekeGlobals {
    
    public static let Domain = "io.haneke"
    
    public static let Queue: dispatch_queue_t = {
        return dispatch_queue_create("io.haneke.callback_queue",  DISPATCH_QUEUE_SERIAL)
    }()
    
}

public struct Shared {
    
    public static var imageCache : Cache<UIImage> {
        struct Static {
            static let name = "shared-images"
            static let cache = Cache<UIImage>(name: name)
        }
        return Static.cache
    }
    
    public static var dataCache : Cache<NSData> {
        struct Static {
            static let name = "shared-data"
            static let cache = Cache<NSData>(name: name)
        }
        return Static.cache
    }
    
    public static var stringCache : Cache<String> {
        struct Static {
            static let name = "shared-strings"
            static let cache = Cache<String>(name: name)
        }
        return Static.cache
    }
    
    public static var JSONCache : Cache<JSON> {
        struct Static {
            static let name = "shared-json"
            static let cache = Cache<JSON>(name: name)
        }
        return Static.cache
    }
}

func errorWithCode(code: Int, description: String) -> NSError {
    let userInfo = [NSLocalizedDescriptionKey: description]
    return NSError(domain: HanekeGlobals.Domain, code: code, userInfo: userInfo)
}
