//
//  Fetcher.swift
//  Haneke
//
//  Created by Hermes Pique on 9/9/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import UIKit

public class Fetcher<T : DataConvertible> {

    let key : String
    
    init(key : String) {
        self.key = key
    }
    
    func fetchWithSuccess(success doSuccess : (T.Result) -> (), failure doFailure : ((NSError?) -> ())) {}
    
    func cancelFetch() {}
}

class SimpleFetcher<T : DataConvertible> : Fetcher<T> {
    
    let getThing : () -> T.Result
    
    init(key : String, thing getThing : @autoclosure () -> T.Result) {
        self.getThing = getThing
        super.init(key: key)
    }
    
    override func fetchWithSuccess(success doSuccess : (T.Result) -> (), failure doFailure : ((NSError?) -> ())) {
        let thing = getThing()
        doSuccess(thing)
    }
    
    override func cancelFetch() {}
    
}
