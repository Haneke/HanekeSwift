//
//  Fetcher.swift
//  Haneke
//
//  Created by Hermes Pique on 9/9/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import UIKit

// See: http://stackoverflow.com/questions/25915306/generic-closure-in-protocol
public class Fetcher<T : DataConvertible> {

    let key : String
    
    init(key : String) {
        self.key = key
    }
    
    func fetch(failure fail : ((NSError?) -> ()), success succeed : (T.Result) -> ()) {}
    
    func cancelFetch() {}
}

class SimpleFetcher<T : DataConvertible> : Fetcher<T> {
    
    let getThing : () -> T.Result
    
    init(key : String, thing getThing : @autoclosure () -> T.Result) {
        self.getThing = getThing
        super.init(key: key)
    }
    
    override func fetch(failure fail : ((NSError?) -> ()), success succeed : (T.Result) -> ()) {
        let thing = getThing()
        succeed(thing)
    }
    
    override func cancelFetch() {}
    
}

public extension Cache {
    
    public func fetch(#key : String, value getValue : @autoclosure () -> T.Result, formatName : String = OriginalFormatName, success succeed : Fetch<T>.Succeeder? = nil) -> Fetch<T> {
        let fetcher = SimpleFetcher<T>(key: key, thing: getValue)
        return self.fetch(fetcher: fetcher, formatName: formatName, success: succeed)
    }
    
}
