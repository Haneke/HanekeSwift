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
    
}

public struct Shared {
    
    public static var imageCache : HanekeCache<UIImage> {
        struct Static {
            static let name = "shared-images"
            static let cache = HanekeCache<UIImage>(name: name)
        }
        return Static.cache
    }
    
    public static var dataCache : HanekeCache<Data> {
        struct Static {
            static let name = "shared-data"
            static let cache = HanekeCache<Data>(name: name)
        }
        return Static.cache
    }
    
    public static var stringCache : HanekeCache<String> {
        struct Static {
            static let name = "shared-strings"
            static let cache = HanekeCache<String>(name: name)
        }
        return Static.cache
    }
    
    public static var JSONCache : HanekeCache<JSON> {
        struct Static {
            static let name = "shared-json"
            static let cache = HanekeCache<JSON>(name: name)
        }
        return Static.cache
    }
}

func errorWithCode(_ code: Int, description: String) -> Error {
    let userInfo = [NSLocalizedDescriptionKey: description]
    return NSError(domain: HanekeGlobals.Domain, code: code, userInfo: userInfo) as Error
}
