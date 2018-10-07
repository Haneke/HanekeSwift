//
//  XCTestCase+Test.swift
//  Haneke
//
//  Created by Hermes Pique on 9/15/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import XCTest

extension XCTestCase {
    
    func waitFor(_ interval : TimeInterval) {
        let date = Date(timeIntervalSinceNow: interval)
        RunLoop.current.run(mode: RunLoop.Mode.default, before: date)
    }

    func wait(_ timeout : TimeInterval, condition: () -> Bool) {
        let timeoutDate = Date(timeIntervalSinceNow: timeout)
        var success = false
        while !success && (NSDate().laterDate(timeoutDate) == timeoutDate) {
            success = condition()
            if !success {
                RunLoop.current.run(mode: RunLoop.Mode.default, before: timeoutDate)
            }
        }
        if !success {
            XCTFail("Wait timed out.")
        }
    }

}
