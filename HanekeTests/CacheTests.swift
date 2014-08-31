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
        let key = "key"
        
        sut.setImage(image, key)
        
        let resultImage = sut.fetchImage(key, formatName: OriginalFormatName)
        XCTAssertTrue(resultImage!.isEqualPixelByPixel(image))
    }
    
    func testSetImageInFormat () {
        let sut = self.sut!
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let key = self.name
        let format = Format(self.name)
        sut.addFormat(format)
        
        sut.setImage(image, key, formatName : format.name)
        
        let resultImage = sut.fetchImage(key, formatName: format.name)
        XCTAssertTrue(resultImage!.isEqualPixelByPixel(image))
    }
    
    func testSetImageInInexistingFormat () {
        let sut = self.sut!
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let key = self.name
        
        // TODO: Swift doesn't support XCAssertThrows yet. 
        // See: http://stackoverflow.com/questions/25529625/testing-assertion-in-swift
        // XCAssertThrows(sut.setImage(image, key, formatName : self.name))
    }
    
    func testFetchImage () {
        let key = "key"
        
        XCTAssert(sut.fetchImage(key) == nil, "MemoryCache is empty")
        
        let image = UIImage()
        sut.setImage(image, key)
        
        XCTAssert(sut.fetchImage(key) != nil, "MemoryCache is not empty")
    }
    
    func testFetchImageEqualImage () {
        let image = UIImage.imageWithColor(UIColor.cyanColor(), CGSizeMake(30, 30), true)
        let key = "key"
        
        sut.setImage(image, key)
        XCTAssert(image.isEqualPixelByPixel(sut.fetchImage(key)), "Fetched image is equal to the original one.")
    }
    
    func testRemoveImageExisting() {
        let key = "key"
        sut.setImage(UIImage(), key)
        
        sut.removeImage(key)
        
        XCTAssertNil(sut.fetchImage(key))
    }
    
    func testRemoveImageExistingInFormat() {
        let sut = self.sut!
        let key = "key"
        let format = Format(self.name)
        sut.addFormat(format)
        sut.setImage(UIImage(), key, formatName: format.name)
        
        sut.removeImage(key, formatName: format.name)
        
        XCTAssertNil(sut.fetchImage(key))
    }
    
    func testRemoveImageExistingUsingAnotherFormat() {
        let sut = self.sut!
        let key = "key"
        let format = Format(self.name)
        sut.addFormat(format)
        sut.setImage(UIImage(), key)
        
        sut.removeImage(key, formatName: format.name)
        
        XCTAssertNotNil(sut.fetchImage(key))
    }
    
    func testRemoveImageExistingUsingInexistingFormat() {
        let sut = self.sut!
        let key = "key"
        sut.setImage(UIImage(), key)
        
        sut.removeImage(key, formatName: self.name)
        
        XCTAssertNotNil(sut.fetchImage(key))
    }
    
    func testRemoveImageInexisting() {
        sut.removeImage(self.name)
    }
    
    func testOnMemoryWarning() {
        let key = "key"
        sut.setImage(UIImage(), key)
        XCTAssertNotNil(sut.fetchImage(key))
        
        sut.onMemoryWarning()
        
        XCTAssertNil(sut.fetchImage(key))
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
