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
        
        let fetcher = SimpleFetcher<UIImage>(key: key, thing: image)

        XCTAssertEqual(fetcher.key, key)
        XCTAssertEqual(fetcher.getThing(), image)
    }
    
    func testSimpleFetcherFetch() {
        let key = self.name
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let fetcher = SimpleFetcher<UIImage>(key: key, thing: image)
        let expectation = self.expectationWithDescription(self.name)
        
        fetcher.fetchWithSuccess(success: {
            XCTAssertEqual($0, image)
            expectation.fulfill()
        }, failure: { _ in
            XCTFail("expected success")
        })
        
        self.waitForExpectationsWithTimeout(0, handler: nil)
    }
    
}
