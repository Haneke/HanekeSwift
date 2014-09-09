//
//  CacheTests.swift
//  Haneke
//
//  Created by Luis Ascorbe on 23/07/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import Foundation
import UIKit
import XCTest
import Haneke

class CacheTests: XCTestCase {
    
    var sut : Cache!
    
    override func setUp() {
        super.setUp()
        sut = Cache(self.name)
    }
    
    func testInit() {
        let name = "name"
        let sut = Cache(name)
        
        XCTAssertNotNil(sut.memoryWarningObserver)
        XCTAssertEqual(name, sut.name)
    }
    
    func testDeinit() {
        weak var sut = Cache("test")
    }
    
    func testAddFormat() {
        let format = Format(self.name)
        
        sut.addFormat(format)
    }
    
    func testAddFormat_DiskCapacityZero() {
        let sut = self.sut!
        let key = self.name
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let format = Format(self.name)

        sut.addFormat(format)

        sut.setImage(image, key, formatName: format.name)
        // TODO: Test that the image is not saved to the disk cache. Requires fetch method.
    }
    
    func testAddFormat_DiskCapacityNonZero() {
        let sut = self.sut!
        let key = self.name
        let image = UIImage.imageWithColor(UIColor.greenColor())
        var format = Format(self.name, diskCapacity: UINT64_MAX)

        sut.addFormat(format)

        sut.setImage(image, key, formatName: format.name)
        // TODO: Test that the image is saved to the disk cache. Requires fetch method.
    }
    
    func testSetImageInDefaultFormat () {
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let key = self.name
        let expectation = self.expectationWithDescription(self.name)
        
        sut.setImage(image, key)
        
        sut.fetchImageForKey(key, formatName: OriginalFormatName, {
            expectation.fulfill()
            XCTAssertTrue($0.isEqualPixelByPixel(image))
        })
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testSetImageInFormat () {
        let sut = self.sut!
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let key = self.name
        let format = Format(self.name)
        sut.addFormat(format)
        let expectation = self.expectationWithDescription(self.name)
        
        sut.setImage(image, key, formatName : format.name)
        
        sut.fetchImageForKey(key, formatName: format.name, {
            expectation.fulfill()
            XCTAssertTrue($0.isEqualPixelByPixel(image))
        })
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testSetImageInInexistingFormat () {
        let sut = self.sut!
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let key = self.name
        
        // TODO: Swift doesn't support XCAssertThrows yet. 
        // See: http://stackoverflow.com/questions/25529625/testing-assertion-in-swift
        // XCAssertThrows(sut.setImage(image, key, formatName : self.name))
    }
    
    func testFetchImageForKey_Inexisting () {
        let key = self.name
        let expectation = self.expectationWithDescription(self.name)
        
        sut.fetchImageForKey(key, formatName: OriginalFormatName, successBlock : { data in
            expectation.fulfill()
            XCTFail("Expected failure")
        }, failureBlock : { _ in
            expectation.fulfill()
        })
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testFetchImage_Existing () {
        let image = UIImage.imageWithColor(UIColor.cyanColor(), CGSizeMake(30, 30), true)
        let key = self.name
        let expectation = self.expectationWithDescription(self.name)
        
        sut.setImage(image, key)
        
        sut.fetchImageForKey(key, formatName: OriginalFormatName, {
            expectation.fulfill()
            XCTAssertTrue($0.isEqualPixelByPixel(image))
        })
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testRemoveImage_Existing() {
        let key = "key"
        sut.setImage(UIImage(), key)
        let expectation = self.expectationWithDescription("fetch image")

        sut.removeImage(key)
        
        sut.fetchImageForKey(key, successBlock : { _ in
            XCTFail("Expected failure")
            expectation.fulfill()
        }, failureBlock : { _ in
            expectation.fulfill()
        })
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testRemoveImage_ExistingInFormat() {
        let sut = self.sut!
        let key = "key"
        let format = Format(self.name)
        sut.addFormat(format)
        sut.setImage(UIImage(), key, formatName: format.name)
        let expectation = self.expectationWithDescription("fetch image")
        
        sut.removeImage(key, formatName: format.name)
        
        sut.fetchImageForKey(key, formatName: format.name, successBlock : { data in
            XCTFail("Expected failure")
            expectation.fulfill()
        }, failureBlock : { _ in
            expectation.fulfill()
        })
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testRemoveImageExistingUsingAnotherFormat() {
        let sut = self.sut!
        let key = "key"
        let format = Format(self.name)
        sut.addFormat(format)
        sut.setImage(UIImage(), key)
        let expectation = self.expectationWithDescription("fetch image")
        
        sut.removeImage(key, formatName: format.name)
        
        sut.fetchImageForKey(key, successBlock : { _ in
            expectation.fulfill()
        }, failureBlock : { _ in
            XCTFail("Expected success")
            expectation.fulfill()
        })
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testRemoveImageExistingUsingInexistingFormat() {
        let sut = self.sut!
        let key = "key"
        sut.setImage(UIImage(), key)
        let expectation = self.expectationWithDescription("fetch image")
        
        sut.removeImage(key, formatName: self.name)
        
        sut.fetchImageForKey(key, successBlock : { _ in
            expectation.fulfill()
        }, failureBlock : { _ in
            XCTFail("Expected success")
            expectation.fulfill()
        })
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testRemoveImageInexisting() {
        sut.removeImage(self.name)
    }
    
    func testOnMemoryWarning() {
        let key = "key"
        sut.setImage(UIImage(), key)
        let expectation = self.expectationWithDescription("fetch image")

        sut.onMemoryWarning()
        
        sut.fetchImageForKey(key, successBlock : { _ in
            XCTFail("Expected failure")
            expectation.fulfill()
        }, failureBlock : { _ in
            expectation.fulfill()
        })
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testUIApplicationDidReceiveMemoryWarningNotification() {
        let expectation = expectationWithDescription("onMemoryWarning")
        
        class CacheMock : Cache {
            
            var expectation : XCTestExpectation?
            
            override func onMemoryWarning() {
                super.onMemoryWarning()
                expectation!.fulfill()
            }
        }
        
        let sut = CacheMock("test")
        sut.expectation = expectation // XCode crashes if we use the original expectation directly
        
        NSNotificationCenter.defaultCenter().postNotificationName(UIApplicationDidReceiveMemoryWarningNotification, object: nil)
        
        waitForExpectationsWithTimeout(0, nil)
    }
}
