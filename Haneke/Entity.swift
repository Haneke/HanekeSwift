//
//  Entity.swift
//  Haneke
//
//  Created by Hermes Pique on 9/9/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import UIKit

public protocol DataConvertible {
    
    class func convertFromData(data : NSData) -> DataConvertible?
    
}

public protocol Fetcher {

    var key : String { get }
    
    func fetchWithSuccess(success doSuccess : (DataConvertible) -> (), failure doFailure : ((NSError?) -> ()))
    
    func cancelFetch()
}

class SimpleEntity<T : DataConvertible> : Fetcher {
    
    let key : String
    
    let getThing : () -> T
    
    init(key : String, thing getThing : @autoclosure () -> T) {
        self.key = key
        self.getThing = getThing
    }
    
    func fetchWithSuccess(success doSuccess : (DataConvertible) -> (), failure doFailure : ((NSError?) -> ())) {
        let thing = getThing()
        doSuccess(thing)
    }
    
    func cancelFetch() {}
    
}
