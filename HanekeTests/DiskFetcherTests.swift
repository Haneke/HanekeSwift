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

    override func setUp() {
        super.setUp()
        directoryPath = directoryPath.stringByAppendingPathComponent(self.name)
        sut = DiskFetcher(path: directoryPath)
    }
    
    func testInit() {
        XCTAssertEqual(sut.path, directoryPath)
    }
    
    func testKey() {
        XCTAssertEqual(sut.key, directoryPath)
    }
    
    func testFetchImage_Success() {
        let image = UIImage.imageWithColor(UIColor.greenColor(), CGSizeMake(10, 20))
        let data = UIImagePNGRepresentation(image)
        data.writeToFile(directoryPath, atomically: true)
        
        let expectation = self.expectationWithDescription(self.name)
        
        sut.fetchWithSuccess(success: {
            let result = $0 as UIImage
            XCTAssertTrue(result.isEqualPixelByPixel(image))
            expectation.fulfill()
        }) { _ in
            XCTFail("Expected to succeed")
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testFetchImage_Failure_NSFileReadNoSuchFileError() {
        let expectation = self.expectationWithDescription(self.name)
        
        sut.fetchWithSuccess(success: { _ in
            XCTFail("Expected to fail")
            expectation.fulfill()
        }) {
            XCTAssertEqual($0!.code, NSFileReadNoSuchFileError)
            XCTAssertNotNil($0!.localizedDescription)
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testFetchImage_Failure_HNKDiskEntityInvalidDataError() {
        let data = NSData.data()
        data.writeToFile(directoryPath, atomically: true)
        
        let expectation = self.expectationWithDescription(self.name)
        
        sut.fetchWithSuccess(success: { _ in
            XCTFail("Expected to fail")
            expectation.fulfill()
        }) {
            XCTAssertEqual($0!.domain, Haneke.Domain)
            XCTAssertEqual($0!.code, Haneke.DiskFetcher.ErrorCode.InvalidData.toRaw())
            XCTAssertNotNil($0!.localizedDescription)
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testCancelFetch() {
        let image = UIImage.imageWithColor(UIColor.greenColor(), CGSizeMake(10, 20))
        let data = UIImagePNGRepresentation(image)
        data.writeToFile(directoryPath, atomically: true)
        
        sut.fetchWithSuccess(success: { _ in
            XCTFail("Unexpected success")
        }) { _ in
            XCTFail("Unexpected failure")
        }
        
        sut.cancelFetch()
        
        self.waitFor(0.1)
    }
    
    func testCancelFetch_NoFetch() {
        sut.cancelFetch()
    }
}
