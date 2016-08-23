//
//  NetworkFetcherTests.swift
//  Haneke
//
//  Created by Hermes Pique on 9/15/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import UIKit
import XCTest
import OHHTTPStubs
@testable import Haneke

class NetworkFetcherTests: XCTestCase {

    let URL = Foundation.URL(string: "http://haneke.io/image.jpg")!
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
        XCTAssertEqual(sut.key, URL.absoluteString)
    }
    
    func testFetchImage_Success() {
        let image = UIImage.imageWithColor(UIColor.green)
        OHHTTPStubs.stubRequestsPassingTest({ _ in
            return true
        }, withStubResponse: { _ in
            let data = UIImagePNGRepresentation(image)
            return OHHTTPStubsResponse(data: data!, statusCode: 200, headers:nil)
        })
        let expectation = self.expectation(description: self.name!)
        
        sut.fetch(failure: { _ in
            XCTFail("expected success")
            expectation.fulfill()
        }) {
            let result = $0 as UIImage
            XCTAssertTrue(result.isEqualPixelByPixel(image))
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testFetchImage_Success_StatusCode200() {
        self.testFetchImageSuccessWithStatusCode(200)
    }

    func testFetchImage_Success_StatusCode201() {
        self.testFetchImageSuccessWithStatusCode(201)
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
            let data = Data()
            return OHHTTPStubsResponse(data: data, statusCode: 200, headers:nil)
        })
        let expectation = self.expectation(description: self.name!)
        
        sut.fetch(failure: {
            XCTAssertEqual($0!.domain, HanekeGlobals.Domain)
            XCTAssertEqual($0!.code, HanekeGlobals.NetworkFetcher.ErrorCode.invalidData.rawValue)
            XCTAssertNotNil($0!.localizedDescription)
            expectation.fulfill()
        }) { _ in
            XCTFail("expected failure")
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 100000, handler: nil)
    }
    
    func testFetchImage_Failure_MissingData() {
        OHHTTPStubs.stubRequestsPassingTest({ _ in
            return true
        }, withStubResponse: { _ in
            let data = Data.dataWithLength(100)
            return OHHTTPStubsResponse(data: data, statusCode: 200, headers:["Content-Length":String(data.length * 2)])
        })
        let expectation = self.expectation(description: self.name!)
        
        sut.fetch(failure: {
            XCTAssertEqual($0!.domain, HanekeGlobals.Domain)
            XCTAssertEqual($0!.code, HanekeGlobals.NetworkFetcher.ErrorCode.missingData.rawValue)
            XCTAssertNotNil($0!.localizedDescription)
            expectation.fulfill()
        }) { _ in
            XCTFail("expected failure")
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testCancelFetch() {
        let image = UIImage.imageWithColor(UIColor.green)
        OHHTTPStubs.stubRequestsPassingTest({ _ in
            return true
        }, withStubResponse: { _ in
            let data = UIImagePNGRepresentation(image)
            return OHHTTPStubsResponse(data: data!, statusCode: 200, headers:nil)
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
        XCTAssertEqual(sut.session, URLSession.shared)
    }
    
    // MARK: Private

    fileprivate func testFetchImageSuccessWithStatusCode(_ statusCode : Int32) {
        let image = UIImage.imageWithColor(UIColor.green)
        OHHTTPStubs.stubRequestsPassingTest({ _ in
            return true
            }, withStubResponse: { _ in
                let data = UIImagePNGRepresentation(image)
                return OHHTTPStubsResponse(data: data!, statusCode: statusCode, headers:nil)
        })
        let expectation = self.expectation(description: self.name!)
        sut.cancelFetch()

        sut.fetch(failure: { _ in
            XCTFail("expected success")
            expectation.fulfill()
            }) {
                let result = $0 as UIImage
                XCTAssertTrue(result.isEqualPixelByPixel(image))
                expectation.fulfill()
        }

        self.waitForExpectations(timeout: 1, handler: nil)
    }

    fileprivate func testFetchImageFailureWithInvalidStatusCode(_ statusCode : Int32) {
        OHHTTPStubs.stubRequestsPassingTest({ _ in
            return true
        }, withStubResponse: { _ in
            let data = Data.dataWithLength(100)
            return OHHTTPStubsResponse(data: data, statusCode: statusCode, headers:nil)
        })
        let expectation = self.expectation(description: self.name!)
        
        sut.fetch(failure: {
            XCTAssertEqual($0!.domain, HanekeGlobals.Domain)
            XCTAssertEqual($0!.code, HanekeGlobals.NetworkFetcher.ErrorCode.invalidStatusCode.rawValue)
            XCTAssertNotNil($0!.localizedDescription)
            expectation.fulfill()
        }) { _ in
            XCTFail("expected failure")
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 1, handler: nil)        
    }
    
    // MARK: Cache extension
    
    func testCacheFetch_Success() {
        let data = Data.dataWithLength(1)
        OHHTTPStubs.stubRequestsPassingTest({ _ in
            return true
            }, withStubResponse: { _ in
                return OHHTTPStubsResponse(data: data, statusCode: 200, headers:nil)
        })
        let expectation = self.expectation(description: self.name!)
        let cache = Cache<Data>(name: self.name!)

        cache.fetch(URL: URL, failure: {_ in
            XCTFail("expected success")
            expectation.fulfill()
        }) {
            XCTAssertEqual($0, data)
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 1, handler: nil)
        
        cache.removeAll()
    }
    
    func testCacheFetch_Failure() {
        let data = Data.dataWithLength(1)
        OHHTTPStubs.stubRequestsPassingTest({ _ in
            return true
            }, withStubResponse: { _ in
                return OHHTTPStubsResponse(data: data, statusCode: 404, headers:nil)
        })
        let expectation = self.expectation(description: self.name!)
        let cache = Cache<Data>(name: self.name!)
        
        cache.fetch(URL: URL, failure: {_ in
            expectation.fulfill()
        }) { _ in
            XCTFail("expected success")
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 1, handler: nil)
        
        cache.removeAll()
    }
    
    func testCacheFetch_WithFormat() {
        let data = Data.dataWithLength(1)
        OHHTTPStubs.stubRequestsPassingTest({ _ in
            return true
            }, withStubResponse: { _ in
                return OHHTTPStubsResponse(data: data, statusCode: 404, headers:nil)
        })
        let expectation = self.expectation(description: self.name!)
        let cache = Cache<Data>(name: self.name!)
        let format = Format<Data>(name: self.name!)
        cache.addFormat(format)

        cache.fetch(URL: URL, formatName: format.name, failure: {_ in
            expectation.fulfill()
        }) { _ in
            XCTFail("expected success")
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 1, handler: nil)
        
        cache.removeAll()
    }
    
}
