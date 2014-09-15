//
//  NetworkEntityTests.swift
//  Haneke
//
//  Created by Hermes Pique on 9/15/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import UIKit
import XCTest
import Haneke

class NetworkEntityTests: XCTestCase {

    let URL = NSURL(string: "http://haneke.io/image.jpg")
    var sut : NetworkEntity!
    
    override func setUp() {
        super.setUp()
        sut = NetworkEntity(URL: URL)
    }
    
    override func tearDown() {
        OHHTTPStubs.removeAllStubs()
        super.tearDown()
    }

    func testFetchImage_Success() {
        let image = UIImage.imageWithColor(UIColor.greenColor())
        OHHTTPStubs.stubRequestsPassingTest({ _ in
            return true
        }, withStubResponse: { _ in
            let data = UIImagePNGRepresentation(image)
            return OHHTTPStubsResponse(data: data, statusCode: 200, headers:nil)
        })
        let expectation = self.expectationWithDescription(self.name)
        
        sut.fetchImageWithSuccess(success: {
            XCTAssertTrue($0.isEqualPixelByPixel(image))
            expectation.fulfill()
        }) { _ in
            XCTFail("expected success")
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
}
