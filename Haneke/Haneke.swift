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
    
    public static var sharedImageCache : Cache<UIImage> {
        struct Static {
            static let name = "shared-images"
            static let cache = Cache<UIImage>(name: name)
        }
        return Static.cache
    }
    
    public static var sharedDataCache : Cache<NSData> {
        struct Static {
            static let name = "shared-data"
            static let cache = Cache<NSData>(name: name)
        }
        return Static.cache
    }
    
    public static var sharedStringCache : Cache<String> {
        struct Static {
            static let name = "shared-strings"
            static let cache = Cache<String>(name: name)
        }
        return Static.cache
    }
    
    public static var sharedJSONCache : Cache<JSON> {
    struct Static {
        static let name = "shared-json"
        static let cache = Cache<JSON>(name: name)
        }
        return Static.cache
    }
    
}

struct Log {
    
    private static let Tag = "[HANEKE]"
    
    private enum Level : String {
        case Debug = "[DEBUG]"
        case Error = "[ERROR]"
    }
    
    private static func log(level : Level, _ message : @autoclosure () -> String, _ error : NSError? = nil) {
        if let error = error {
            NSLog("%@%@ %@ with error %@", Tag, level.rawValue, message(), error);
        } else {
            NSLog("%@%@ %@", Tag, level.rawValue, message())
        }
    }
    
    static func debug(message : @autoclosure () -> String, _ error : NSError? = nil) {
        #if DEBUG
            log(.Debug, message, error)
        #endif
    }
    
    static func error(message : @autoclosure () -> String, _ error : NSError? = nil) {
        log(.Error, message, error)
    }
    
}
