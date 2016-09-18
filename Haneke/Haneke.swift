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
    
    public static var imageCache : Cache<UIImage> {
        struct Static {
            static let name = "shared-images"
            static let cache = Cache<UIImage>(name: name)
        }
        return Static.cache
    }
    

    public static var dataCache : Cache<Data> {
        struct Static {
            static let name = "shared-data"
            static let cache = Cache<Data>(name: name)
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

public class HanekeError:Error{
    public let code:Int
    public let description:String
    public var localizedDescription: String{
        return description
    }
    init(code:Int,description:String){
        
        self.code = code
        self.description = description
    }
}

func errorWithCode(code: Int, description: String) -> HanekeError {
    return HanekeError(code:code,description:description)
}
