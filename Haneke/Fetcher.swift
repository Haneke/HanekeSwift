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

    public let key: String
    
    public init(key: String) {
        self.key = key
    }
    
    public func fetch(failure fail: ((NSError?) -> ()), success succeed: (T.Result) -> ()) {}
    
    public func cancelFetch() {}
}

class SimpleFetcher<T : DataConvertible> : Fetcher<T> {
    
    let getValue : () -> T.Result
    
    init(key: String, @autoclosure(escaping) value getValue : () -> T.Result) {
        self.getValue = getValue
        super.init(key: key)
    }
    
    override func fetch(failure fail: ((NSError?) -> ()), success succeed: (T.Result) -> ()) {
        let value = getValue()
        succeed(value)
    }
    
    override func cancelFetch() {}
    
}
