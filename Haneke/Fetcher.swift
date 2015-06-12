//
//  Fetcher.swift
//  Haneke
//
//  Created by Hermes Pique on 9/9/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import UIKit

// See: http://stackoverflow.com/questions/25915306/generic-closure-in-protocol
public class Fetcher<T : DataLiteralConvertable> {

    public let key : String
    
    init(key : String) {
        self.key = key
    }
    
    func fetch(failure fail : ((NSError?) -> ()), success succeed : (T) -> ()) {}
    
    func cancelFetch() {}
}

class SimpleFetcher<T : DataLiteralConvertable> : Fetcher<T> {
    
    let getValue : () -> T
    
    init(key : String, @autoclosure(escaping) value getValue : () -> T) {
        self.getValue = getValue
        super.init(key: key)
    }
    
    override func fetch(failure fail : ((NSError?) -> ()), success succeed : (T) -> ()) {
        let value = getValue()
        succeed(value)
    }
    
    override func cancelFetch() {}
    
}
