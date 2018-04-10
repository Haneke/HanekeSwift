//
//  Fetcher.swift
//  Haneke
//
//  Created by Hermes Pique on 9/9/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import UIKit

// See: http://stackoverflow.com/questions/25915306/generic-closure-in-protocol
open class Fetcher<T : DataConvertible> {

    open let key: String
    
    public init(key: String) {
        self.key = key
    }
    
    open func fetch(failure fail: @escaping ((Error?) -> ()), success succeed: @escaping (T.Result) -> ()) {}
    
    open func cancelFetch() {}
}

class SimpleFetcher<T : DataConvertible> : Fetcher<T> {
    
    let getValue : () -> T.Result
    
    init(key: String, value getValue : @autoclosure @escaping () -> T.Result) {
        self.getValue = getValue
        super.init(key: key)
    }
    
    override func fetch(failure fail: @escaping ((Error?) -> ()), success succeed: @escaping (T.Result) -> ()) {
        let value = getValue()
        succeed(value)
    }
    
    override func cancelFetch() {}
    
}
