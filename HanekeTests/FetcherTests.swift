//
//  FetcherTests.swift
//  Haneke
//
//  Created by Hermes Pique on 9/10/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import UIKit
import XCTest

class FetcherTests: XCTestCase {
    
    func testSimpleFetcherInit() {
        let key = self.name
        let image = UIImage.imageWithColor(UIColor.greenColor())
        
        let fetcher = SimpleFetcher<UIImage>(key: key, value: image)

        XCTAssertEqual(fetcher.key, key)
        XCTAssertEqual(fetcher.getValue(), image)
    }
    
    func testSimpleFetcherFetch() {
        let key = self.name
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let fetcher = SimpleFetcher<UIImage>(key: key, value: image)
        let expectation = self.expectationWithDescription(self.name)
        
        fetcher.fetch(failure: { _ in
            XCTFail("expected success")
        }) {
            XCTAssertEqual($0, image)
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(0, handler: nil)
    }
    
    func testCacheFetch() {
        let data = NSData.dataWithLength(1)
        let expectation = self.expectationWithDescription(self.name)
        let cache = Cache<NSData>(name: self.name)
        
        cache.fetch(key: self.name, value: data) {
            XCTAssertEqual($0, data)
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1, handler: nil)
        
        cache.removeAll()
    }
    
    func testCacheFetch_WithFormat() {
        let data = NSData.dataWithLength(1)
        let expectation = self.expectationWithDescription(self.name)
        let cache = Cache<NSData>(name: self.name)
        let format = Format<NSData>(name: self.name)
        cache.addFormat(format)
        
        cache.fetch(key: self.name, value: data, formatName: format.name) {
            XCTAssertEqual($0, data)
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1, handler: nil)
        
        cache.removeAll()
    }
    
    func testCacheMultiFetch() {
        let dictionary = ["a" : "1", "b" : "2", "c" : "3"]
        var dataDictionary = [String:NSData]()
        for (key, value) in dictionary {
            dataDictionary[key] = value.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)!
        }

        let setExpectation = self.expectationWithDescription("set values")
        let getExpectation = self.expectationWithDescription("received result dictionary")

        let cache = Cache<NSData>(name: self.name)
        let format = Format<NSData>(name: self.name)
        cache.addFormat(format)
        
        cache.set(values: dataDictionary, formatName: format.name) {
            _ in
            setExpectation.fulfill()
            let keys = Array(dictionary.keys)
            cache.fetch(keys: keys, formatName: format.name){
                (result:[String : NSData]) in
                for (key, value) in dictionary {
                    let storedValueData = result[key]
                    XCTAssertNotNil(storedValueData)
                    let storedValue = NSString(data: storedValueData!, encoding: NSUTF8StringEncoding) as? String
                    XCTAssertNotNil(storedValue)
                    XCTAssertEqual(value, storedValue!)
                }
                getExpectation.fulfill()
            }
        }
        self.waitForExpectationsWithTimeout(1, handler: nil)
        cache.removeAll()
    }
    
}
