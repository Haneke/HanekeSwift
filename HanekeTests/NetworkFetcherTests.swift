//
//  NetworkFetcherTests.swift
//  Haneke
//
//  Created by Hermes Pique on 9/15/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import UIKit
import XCTest

class NetworkFetcherTests: XCTestCase {

    let URL = NSURL(string: "http://haneke.io/image.jpg")!
    var sut : NetworkFetcher<UIImage>!
    
    override func setUp() {
        super.setUp()
        sut = NetworkFetcher(URL: URL)
    }
    
    override func tearDown() {
        OHHTTPStubs.removeAllStubs()
        super.tearDown()
    }
    
    func testInit() {
        XCTAssertEqual(sut.URL, URL)
    }

    func testKey() {
        XCTAssertEqual(sut.key, URL.absoluteString!)
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
        
        sut.fetch(failure: { _ in
            XCTFail("expected success")
            expectation.fulfill()
        }) {
            let result = $0 as UIImage
            XCTAssertTrue(result.isEqualPixelByPixel(image))
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testFetchImage_Success_AfterCancelFetch() {
        let image = UIImage.imageWithColor(UIColor.greenColor())
        OHHTTPStubs.stubRequestsPassingTest({ _ in
            return true
        }, withStubResponse: { _ in
            let data = UIImagePNGRepresentation(image)
            return OHHTTPStubsResponse(data: data, statusCode: 200, headers:nil)
        })
        let expectation = self.expectationWithDescription(self.name)
        sut.cancelFetch()
        
        sut.fetch(failure: { _ in
            XCTFail("expected success")
            expectation.fulfill()
        }) {
            let result = $0 as UIImage
            XCTAssertTrue(result.isEqualPixelByPixel(image))
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testFetchImage_Failure_InvalidStatusCode_401() {
        self.testFetchImageFailureWithInvalidStatusCode(401)
    }
    
    func testFetchImage_Failure_InvalidStatusCode_402() {
        self.testFetchImageFailureWithInvalidStatusCode(402)
    }
    
    func testFetchImage_Failure_InvalidStatusCode_403() {
        self.testFetchImageFailureWithInvalidStatusCode(403)
    }
    
    func testFetchImage_Failure_InvalidStatusCode_404() {
        self.testFetchImageFailureWithInvalidStatusCode(404)
    }

    func testFetchImage_Failure_InvalidData() {
        OHHTTPStubs.stubRequestsPassingTest({ _ in
            return true
        }, withStubResponse: { _ in
            let data = NSData()
            return OHHTTPStubsResponse(data: data, statusCode: 200, headers:nil)
        })
        let expectation = self.expectationWithDescription(self.name)
        
        sut.fetch(failure: {
            XCTAssertEqual($0!.domain, Haneke.Domain)
            XCTAssertEqual($0!.code, Haneke.NetworkFetcherGlobals.ErrorCode.InvalidData.rawValue)
            XCTAssertNotNil($0!.localizedDescription)
            expectation.fulfill()
        }) { _ in
            XCTFail("expected failure")
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(100000, handler: nil)
    }
    
    func testFetchImage_Failure_MissingData() {
        OHHTTPStubs.stubRequestsPassingTest({ _ in
            return true
        }, withStubResponse: { _ in
            let data = NSData.dataWithLength(100)
            return OHHTTPStubsResponse(data: data, statusCode: 200, headers:["Content-Length":String(data.length * 2)])
        })
        let expectation = self.expectationWithDescription(self.name)
        
        sut.fetch(failure: {
            XCTAssertEqual($0!.domain, Haneke.Domain)
            XCTAssertEqual($0!.code, Haneke.NetworkFetcherGlobals.ErrorCode.MissingData.rawValue)
            XCTAssertNotNil($0!.localizedDescription)
            expectation.fulfill()
        }) { _ in
            XCTFail("expected failure")
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testCancelFetch() {
        let image = UIImage.imageWithColor(UIColor.greenColor())
        OHHTTPStubs.stubRequestsPassingTest({ _ in
            return true
        }, withStubResponse: { _ in
            let data = UIImagePNGRepresentation(image)
            return OHHTTPStubsResponse(data: data, statusCode: 200, headers:nil)
        })
        sut.fetch(failure: {_ in
            XCTFail("unexpected failure")
        }) { _ in
            XCTFail("unexpected success")
        }
        
        sut.cancelFetch()
        
        self.waitFor(0.1)
    }
    
    func testCancelFetch_NoFetch() {
        sut.cancelFetch()
    }
    
    func testSession() {
        XCTAssertEqual(sut.session, NSURLSession.sharedSession())
    }
    
    // MARK: Private
    
    private func testFetchImageFailureWithInvalidStatusCode(statusCode : Int32) {
        OHHTTPStubs.stubRequestsPassingTest({ _ in
            return true
        }, withStubResponse: { _ in
            let data = NSData.dataWithLength(100)
            return OHHTTPStubsResponse(data: data, statusCode: statusCode, headers:nil)
        })
        let expectation = self.expectationWithDescription(self.name)
        
        sut.fetch(failure: {
            XCTAssertEqual($0!.domain, Haneke.Domain)
            XCTAssertEqual($0!.code, Haneke.NetworkFetcherGlobals.ErrorCode.InvalidStatusCode.rawValue)
            XCTAssertNotNil($0!.localizedDescription)
            expectation.fulfill()
        }) { _ in
            XCTFail("expected failure")
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1, handler: nil)        
    }
    
    // MARK: Cache extension
    
    func testCacheFetch_Success() {
        let data = NSData.dataWithLength(1)
        OHHTTPStubs.stubRequestsPassingTest({ _ in
            return true
            }, withStubResponse: { _ in
                return OHHTTPStubsResponse(data: data, statusCode: 200, headers:nil)
        })
        let expectation = self.expectationWithDescription(self.name)
        let cache = Cache<NSData>(name: self.name)

        cache.fetch(URL: URL, failure: {_ in
            XCTFail("expected success")
            expectation.fulfill()
        }) {
            XCTAssertEqual($0, data)
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1, handler: nil)
        
        cache.removeAll()
    }
    
    func testCacheFetch_Failure() {
        let data = NSData.dataWithLength(1)
        OHHTTPStubs.stubRequestsPassingTest({ _ in
            return true
            }, withStubResponse: { _ in
                return OHHTTPStubsResponse(data: data, statusCode: 404, headers:nil)
        })
        let expectation = self.expectationWithDescription(self.name)
        let cache = Cache<NSData>(name: self.name)
        
        cache.fetch(URL: URL, failure: {_ in
            expectation.fulfill()
        }) { _ in
            XCTFail("expected success")
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1, handler: nil)
        
        cache.removeAll()
    }
    
    func testCacheFetch_WithFormat() {
        let data = NSData.dataWithLength(1)
        OHHTTPStubs.stubRequestsPassingTest({ _ in
            return true
            }, withStubResponse: { _ in
                return OHHTTPStubsResponse(data: data, statusCode: 404, headers:nil)
        })
        let expectation = self.expectationWithDescription(self.name)
        let cache = Cache<NSData>(name: self.name)
        let format = Format<NSData>(name: self.name)
        cache.addFormat(format)

        cache.fetch(URL: URL, formatName: format.name, failure: {_ in
            expectation.fulfill()
        }) { _ in
            XCTFail("expected success")
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1, handler: nil)
        
        cache.removeAll()
    }
    
}
