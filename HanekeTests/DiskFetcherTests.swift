//
//  DiskFetcherTests.swift
//  Haneke
//
//  Created by Joan Romano on 21/09/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import UIKit
import XCTest

class DiskFetcherTests: DiskTestCase {
    
    var sut : DiskFetcher<UIImage>!
    var path : String!

    override func setUp() {
        super.setUp()
        path = self.uniquePath()
        sut = DiskFetcher(path: path)
    }
    
    func testInit() {
        XCTAssertEqual(sut.path, path)
    }
    
    func testKey() {
        XCTAssertEqual(sut.key, path)
    }
    
    func testFetchImage_Success() {
        let image = UIImage.imageWithColor(UIColor.greenColor(), CGSizeMake(10, 20))
        let data = UIImagePNGRepresentation(image)
        data.writeToFile(sut.path, atomically: true)
        
        let expectation = self.expectationWithDescription(self.name)
        
        sut.fetch(failure: { _ in
            XCTFail("Expected to succeed")
            expectation.fulfill()
        }) {
            let result = $0 as UIImage
            XCTAssertTrue(result.isEqualPixelByPixel(image))
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testFetchImage_Failure_NSFileReadNoSuchFileError() {
        let expectation = self.expectationWithDescription(self.name)
        
        sut.fetch(failure: {
            XCTAssertEqual($0!.code, NSFileReadNoSuchFileError)
            XCTAssertNotNil($0!.localizedDescription)
            expectation.fulfill()
        }) { _ in
            XCTFail("Expected to fail")
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testFetchImage_Failure_HNKDiskEntityInvalidDataError() {
        let data = NSData()
        data.writeToFile(sut.path, atomically: true)
        
        let expectation = self.expectationWithDescription(self.name)
        
        sut.fetch(failure: {
            XCTAssertEqual($0!.domain, Haneke.Domain)
            XCTAssertEqual($0!.code, Haneke.DiskFetcherGlobals.ErrorCode.InvalidData.rawValue)
            XCTAssertNotNil($0!.localizedDescription)
            expectation.fulfill()
        }) { _ in
            XCTFail("Expected to fail")
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testCancelFetch() {
        let image = UIImage.imageWithColor(UIColor.greenColor(), CGSizeMake(10, 20))
        let data = UIImagePNGRepresentation(image)
        data.writeToFile(directoryPath, atomically: true)
        sut.fetch(failure: { _ in
            XCTFail("Unexpected failure")
        }) { _ in
            XCTFail("Unexpected success")
        }
        
        sut.cancelFetch()
        
        self.waitFor(0.1)
    }
    
    func testCancelFetch_NoFetch() {
        sut.cancelFetch()
    }
    
    // MARK: Cache extension
    
    func testCacheFetch_Success() {
        let data = NSData.dataWithLength(1)
        let path = self.writeData(data)
        let expectation = self.expectationWithDescription(self.name)
        let cache = Cache<NSData>(name: self.name)
        
        cache.fetch(path: path, failure: {_ in
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
        let path = self.directoryPath.stringByAppendingPathComponent(self.name)
        let expectation = self.expectationWithDescription(self.name)
        let cache = Cache<NSData>(name: self.name)
        
        cache.fetch(path: path, failure: {_ in
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
        let path = self.writeData(data)
        let expectation = self.expectationWithDescription(self.name)
        let cache = Cache<NSData>(name: self.name)
        let format = Format<NSData>(name: self.name)
        cache.addFormat(format)
        
        cache.fetch(path: path, formatName: format.name, failure: {_ in
            XCTFail("expected success")
            expectation.fulfill()
        }) {
            XCTAssertEqual($0, data)
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1, handler: nil)
        
        cache.removeAll()
    }
}
