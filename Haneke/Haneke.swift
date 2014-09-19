//
//  Haneke.swift
//  Haneke
//
//  Created by Hermes Pique on 9/9/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import UIKit

public struct Haneke {
    
    public static let Domain = "io.haneke"
 
    public static func errorWithCode(code : Int, description : String) -> NSError {
        let userInfo = [NSLocalizedDescriptionKey: description]
        return NSError(domain: Haneke.Domain, code: code, userInfo: userInfo)
    }
    
    public static var sharedCache : Cache<UIImage> {
        struct Static {
            static let name = "shared"
            static let cache = Cache<UIImage>(name)
        }
        return Static.cache
    }
    
}
