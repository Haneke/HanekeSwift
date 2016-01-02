//
//  XCTestCase+Test.swift
//  Haneke
//
//  Created by Hermes Pique on 9/15/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import XCTest

extension XCTestCase {
    
    func waitFor(interval : NSTimeInterval) {
        let date = NSDate(timeIntervalSinceNow: interval)
        NSRunLoop.currentRunLoop().runMode(NSDefaultRunLoopMode, beforeDate: date)
    }

    func wait(timeout : NSTimeInterval, condition: () -> Bool) {
        let timeoutDate = NSDate(timeIntervalSinceNow: timeout)
        var success = false
        while !success && NSDate().laterDate(timeoutDate).isEqualToDate(timeoutDate) {
            success = condition()
            if !success {
                NSRunLoop.currentRunLoop().runMode(NSDefaultRunLoopMode, beforeDate: timeoutDate)
            }
        }
        if !success {
            XCTFail("Wait timed out.")
        }
    }

}
