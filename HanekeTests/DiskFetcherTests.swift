//
//  DiskFetcherTests.swift
//  Haneke
//
//  Created by Joan Romano on 21/09/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import UIKit
import XCTest
@testable import Haneke

class DiskFetcherTests: DiskTestCase {
    
    var sut : DiskFetcher<UIImage>!
    var path: String!

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
        let image = UIImage.imageWithColor(UIColor.green, CGSize(width: 10, height: 20))
        let data = UIImagePNGRepresentation(image)!
        try? data.write(to: URL(fileURLWithPath: sut.path), options: [.atomic])
        
        let expectation = self.expectation(description: self.name!)
        
        sut.fetch(failure: { _ in
            XCTFail("Expected to succeed")
            expectation.fulfill()
        }) {
            let result = $0 as UIImage
            XCTAssertTrue(result.isEqualPixelByPixel(image))
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testFetchImage_Failure_NSFileReadNoSuchFileError() {
        let expectation = self.expectation(description: self.name!)
        
        sut.fetch(failure: {
            XCTAssertEqual($0!.code, NSFileReadNoSuchFileError)
            XCTAssertNotNil($0!.localizedDescription)
            expectation.fulfill()
        }) { _ in
            XCTFail("Expected to fail")
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testFetchImage_Failure_HNKDiskEntityInvalidDataError() {
        let data = Data()
        try? data.write(to: URL(fileURLWithPath: sut.path), options: [.atomic])
        
        let expectation = self.expectation(description: self.name!)
        
        sut.fetch(failure: {
            XCTAssertEqual($0!.domain, HanekeGlobals.Domain)
            XCTAssertEqual($0!.code, HanekeGlobals.DiskFetcher.ErrorCode.invalidData.rawValue)
            XCTAssertNotNil($0!.localizedDescription)
            expectation.fulfill()
        }) { _ in
            XCTFail("Expected to fail")
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 1, handler: nil)
    }

    func testCancelFetch() {
        let image = UIImage.imageWithColor(UIColor.green)
        let data = UIImagePNGRepresentation(image)!
        try? data.write(to: URL(fileURLWithPath: directoryPath), options: [.atomic])
        sut.fetch(failure: { error in
            XCTFail("Unexpected failure with error \(error)")
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
        let data = Data.dataWithLength(1)
        let path = self.writeData(data)
        let expectation = self.expectation(description: self.name!)
        let cache = Cache<Data>(name: self.name!)
        
        cache.fetch(path: path, failure: {_ in
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
        let path = (self.directoryPath as NSString).appendingPathComponent(self.name!)
        let expectation = self.expectation(description: self.name!)
        let cache = Cache<Data>(name: self.name!)
        
        cache.fetch(path: path, failure: {_ in
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
        let path = self.writeData(data)
        let expectation = self.expectation(description: self.name!)
        let cache = Cache<Data>(name: self.name!)
        let format = Format<Data>(name: self.name!)
        cache.addFormat(format)
        
        cache.fetch(path: path, formatName: format.name, failure: {_ in
            XCTFail("expected success")
            expectation.fulfill()
        }) {
            XCTAssertEqual($0, data)
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 1, handler: nil)
        
        cache.removeAll()
    }
}
