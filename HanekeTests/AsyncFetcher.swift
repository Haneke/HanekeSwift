//
//  AsyncFetcher.swift
//  Haneke
//
//  Created by Hermes Pique on 1/2/16.
//  Copyright © 2016 Haneke. All rights reserved.
//

import Foundation
@testable import Haneke

class AsyncFetcher<T : DataConvertible> : Fetcher<T> {

    let getValue : () -> T.Result

    init(key: String, @autoclosure(escaping) value getValue : () -> T.Result) {
        self.getValue = getValue
        super.init(key: key)
    }

    override func fetch(failure fail: ((NSError?) -> ()), success succeed: (T.Result) -> ()) {
        let value = getValue()
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            dispatch_async(dispatch_get_main_queue()) {
                succeed(value)
            }
        }
    }

    override func cancelFetch() {}

}