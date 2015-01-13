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
    
    public init(key : String) {
        self.key = key
    }
    
    public func fetch(failure fail : ((NSError?) -> ()), success succeed : (T.Result) -> ()) {}
    
    public func cancelFetch() {}
}

public class SimpleFetcher<T : DataConvertible> : Fetcher<T> {
    
    let getValue : () -> T.Result
    
    public init(key : String, value getValue : @autoclosure () -> T.Result) {
        self.getValue = getValue
        super.init(key: key)
    }
    
    public override func fetch(failure fail : ((NSError?) -> ()), success succeed : (T.Result) -> ()) {
        let value = getValue()
        succeed(value)
    }
    
    public override func cancelFetch() {}
    
}
