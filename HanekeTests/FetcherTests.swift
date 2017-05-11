//
//  FetcherTests.swift
//  Haneke
//
//  Created by Hermes Pique on 9/10/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import UIKit
import XCTest
@testable import Haneke

class FetcherTests: XCTestCase {
    
    func testSimpleFetcherInit() {
        let key = self.name!
        let image = UIImage.imageWithColor(UIColor.green)
        
        let fetcher = SimpleFetcher<UIImage>(key: key, value: image)

        XCTAssertEqual(fetcher.key, key)
        XCTAssertEqual(fetcher.getValue(), image)
    }
    
    func testSimpleFetcherFetch() {
        let key = self.name!
        let image = UIImage.imageWithColor(UIColor.green)
        let fetcher = SimpleFetcher<UIImage>(key: key, value: image)
        let expectation = self.expectation(description: key)
        
        fetcher.fetch(failure: { _ in
            XCTFail("expected success")
        }) {
            XCTAssertEqual($0, image)
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 0, handler: nil)
    }
    
    func testCacheFetch() {
        let data = Data.dataWithLength(1)
        let expectation = self.expectation(description: self.name!)
        let cache = Cache<Data>(name: self.name!)
        
        cache.fetch(key: self.name!, value: data) {
            XCTAssertEqual($0, data)
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 1, handler: nil)
        
        cache.removeAll()
    }
    
    func testCacheFetch_WithFormat() {
        let data = Data.dataWithLength(1)
        let expectation = self.expectation(description: self.name!)
        let cache = Cache<Data>(name: self.name!)
        let format = Format<Data>(name: self.name!)
        cache.addFormat(format)
        
        cache.fetch(key: self.name!, value: data, formatName: format.name) {
            XCTAssertEqual($0, data)
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 1, handler: nil)
        
        cache.removeAll()
    }
    
}
