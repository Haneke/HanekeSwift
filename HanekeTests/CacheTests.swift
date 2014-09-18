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

class CacheTests: DiskTestCase {
    
    var sut : Cache!
    
    override func setUp() {
        super.setUp()
        sut = Cache(self.name)
    }
    
    override func tearDown() {
        sut.removeAllImages()
        super.tearDown()
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
        let format = Format<UIImage>(self.name)
        
        sut.addFormat(format)
    }
    
    func testSetImageInDefaultFormat () {
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let key = self.name
        let expectation = self.expectationWithDescription(self.name)
        
        sut.setImage(image, key)
        
        sut.fetchImageForKey(key, formatName: OriginalFormatName, {
            XCTAssertTrue($0.isEqualPixelByPixel(image))
            expectation.fulfill()
        })
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testSetImageInFormat () {
        let sut = self.sut!
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let key = self.name
        let format = Format<UIImage>(self.name)
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
    
    func testSetImage_FormatWithouDiskCapacity() {
        let sut = self.sut!
        let key = self.name
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let format = Format<UIImage>(self.name)
        sut.addFormat(format)
        let expectation = self.expectationWithDescription("fetch image")
        
        sut.setImage(image, key, formatName: format.name)

        self.clearMemoryCache()
        sut.fetchImageForKey(key, formatName: format.name,  success: {_ in
            XCTFail("expected failure")
            expectation.fulfill()
            }, failure: {_ in
                expectation.fulfill()
        })
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testSetImage_FormatWithDiskCapacity() {
        let sut = self.sut!
        let key = self.name
        let image = UIImage.imageWithColor(UIColor.greenColor())
        var format = Format<UIImage>(self.name, diskCapacity: UINT64_MAX)
        sut.addFormat(format)
        let expectation = self.expectationWithDescription("fetch image")
        
        sut.setImage(image, key, formatName: format.name)
        
        self.clearMemoryCache()
        sut.fetchImageForKey(key, formatName: format.name,  success: {_ in
            expectation.fulfill()
        }, failure : {_ in
            XCTFail("expected success")
            expectation.fulfill()
        })
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testFetchImageForKey_MemoryHit () {
        let image = UIImage.imageWithColor(UIColor.cyanColor())
        let key = self.name
        let expectation = self.expectationWithDescription(self.name)
        
        sut.setImage(image, key)
        
        let didSuccess = sut.fetchImageForKey(key,  success: {
            XCTAssertTrue($0.isEqualPixelByPixel(image))
            expectation.fulfill()
        })
        
        XCTAssertTrue(didSuccess)
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testFetchImageForKey_MemoryMiss_DiskHit () {
        let image = UIImage.imageWithColor(UIColor.redColor(), CGSize(width: 10, height: 20), false)
        let key = self.name
        let expectation = self.expectationWithDescription(self.name)
        sut.setImage(image, key)
        self.clearMemoryCache()
        
        let didSuccess = sut.fetchImageForKey(key,  success: {
            XCTAssertTrue($0.isEqualPixelByPixel(image))
            expectation.fulfill()
        })
        
        XCTAssertFalse(didSuccess)
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testFetchImageForKey_MemoryMiss_DiskMiss () {
        let key = self.name
        let expectation = self.expectationWithDescription(self.name)
        
        let didSuccess = sut.fetchImageForKey(key,  success : { data in
            XCTFail("expected failure")
            expectation.fulfill()
        }, failure : { error in
            XCTAssertEqual(error!.domain, Haneke.Domain)
            XCTAssertEqual(error!.code, Cache.ErrorCode.ObjectNotFound.toRaw())
            XCTAssertNotNil(error!.localizedDescription)
            expectation.fulfill()
        })
        
        XCTAssertFalse(didSuccess)
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testFetchImageForKey_InexistingFormat () {
        let key = self.name
        let expectation = self.expectationWithDescription(self.name)
        
        let didSuccess = sut.fetchImageForKey(key, formatName: self.name,  success : { data in
            XCTFail("expected failure")
            expectation.fulfill()
        }, failure : { error in
            XCTAssertEqual(error!.domain, Haneke.Domain)
            XCTAssertEqual(error!.code, Cache.ErrorCode.FormatNotFound.toRaw())
            XCTAssertNotNil(error!.localizedDescription)
            expectation.fulfill()
        })
        
        XCTAssertFalse(didSuccess)
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testFetchImageForEntity_MemoryHit () {
        let image = UIImage.imageWithColor(UIColor.cyanColor())
        let key = self.name
        let entity = SimpleEntity(key: key, thing: image)
        let expectation = self.expectationWithDescription(self.name)
        sut.setImage(image, key)
        
        let didSuccess = sut.fetchImageForEntity(entity, success: {
            XCTAssertTrue($0.isEqualPixelByPixel(image))
            expectation.fulfill()
        })
        
        XCTAssertTrue(didSuccess)
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testFetchImageForEntity_MemoryMiss_DiskHit () {
        let image = UIImage.imageWithColor(UIColor.redColor(), CGSize(width: 10, height: 20), false)
        let key = self.name
        let entity = SimpleEntity(key: key, thing: image)
        let expectation = self.expectationWithDescription(self.name)
        sut.setImage(image, key)
        self.clearMemoryCache()
        
        let didSuccess = sut.fetchImageForEntity(entity, success: {
            XCTAssertTrue($0.isEqualPixelByPixel(image))
            expectation.fulfill()
        })
        
        XCTAssertFalse(didSuccess)
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testFetchImageForEntity_MemoryMiss_DiskMiss () {
        let key = self.name
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let entity = SimpleEntity(key: key, thing: image)
        let expectation = self.expectationWithDescription(self.name)
        
        let didSuccess = sut.fetchImageForEntity(entity, success : {
            XCTAssertTrue($0.isEqualPixelByPixel(image))
            expectation.fulfill()
        }, failure : { _ in
            XCTFail("expected success")
            expectation.fulfill()
        })
        
        XCTAssertFalse(didSuccess)
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testFetchImageForEntity_ApplyFormat_ScaleModeFill () {
        let key = self.name
        let image = UIImage.imageWithColor(UIColor.greenColor(), CGSizeMake(3, 3))
        let entity = SimpleEntity(key: key, thing: image)
        
        let resizer = ImageResizer(size : CGSizeMake(10, 20), scaleMode : .Fill)
        let format = Format<UIImage>(self.name, transform: {
            return resizer.resizeImage($0)
        })
        sut.addFormat(format)
        let formattedImage = resizer.resizeImage(image)
        let expectation = self.expectationWithDescription(self.name)
        
        let didSuccess = sut.fetchImageForEntity(entity, formatName : format.name, success : {
            XCTAssertTrue($0.isEqualPixelByPixel(formattedImage))
            expectation.fulfill()
        }, failure : { _ in
            XCTFail("expected sucesss")
            expectation.fulfill()
        })
        
        XCTAssertFalse(didSuccess)
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testFetchImageForEntity_InexistingFormat () {
        let expectation = self.expectationWithDescription(self.name)
        let image = UIImage.imageWithColor(UIColor.redColor())
        let entity = SimpleEntity(key: self.name, thing: image)

        let didSuccess = sut.fetchImageForEntity(entity, formatName: self.name, success : { data in
            XCTFail("expected failure")
            expectation.fulfill()
        }, failure : { error in
            XCTAssertEqual(error!.domain, Haneke.Domain)
            XCTAssertEqual(error!.code, Cache.ErrorCode.FormatNotFound.toRaw())
            XCTAssertNotNil(error!.localizedDescription)
            expectation.fulfill()
        })
        
        XCTAssertFalse(didSuccess)
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testRemoveImage_Existing() {
        let key = "key"
        sut.setImage(UIImage(), key)
        let expectation = self.expectationWithDescription("fetch image")

        sut.removeImage(key)
        
        sut.fetchImageForKey(key,  success : { _ in
            XCTFail("expected failure")
            expectation.fulfill()
        }, failure : { _ in
            expectation.fulfill()
        })
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testRemoveImage_ExistingInFormat() {
        let sut = self.sut!
        let key = "key"
        let format = Format<UIImage>(self.name)
        sut.addFormat(format)
        sut.setImage(UIImage(), key, formatName: format.name)
        let expectation = self.expectationWithDescription("fetch image")
        
        sut.removeImage(key, formatName: format.name)
        
        sut.fetchImageForKey(key, formatName: format.name,  success : { data in
            XCTFail("expected failure")
            expectation.fulfill()
        }, failure : { _ in
            expectation.fulfill()
        })
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testRemoveImageExistingUsingAnotherFormat() {
        let sut = self.sut!
        let key = "key"
        let format = Format<UIImage>(self.name)
        sut.addFormat(format)
        sut.setImage(UIImage(), key)
        let expectation = self.expectationWithDescription("fetch image")
        
        sut.removeImage(key, formatName: format.name)
        
        sut.fetchImageForKey(key,  success : { _ in
            expectation.fulfill()
        }, failure : { _ in
            XCTFail("expected success")
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
        
        sut.fetchImageForKey(key,  success : { _ in
            expectation.fulfill()
        }, failure : { _ in
            XCTFail("expected success")
            expectation.fulfill()
        })
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testRemoveImageInexisting() {
        sut.removeImage(self.name)
    }
    
    func testRemoveAllImages_One() {
        let key = "key"
        sut.setImage(UIImage(), key)
        let expectation = self.expectationWithDescription("fetch image")
        
        sut.removeAllImages()
        
        sut.fetchImageForKey(key,  success : { _ in
            XCTFail("expected failure")
            expectation.fulfill()
            }, failure : { _ in
                expectation.fulfill()
        })
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testRemoveAllImages_None() {
        sut.removeAllImages()
    }
    
    func testOnMemoryWarning() {
        let key = "key"
        sut.setImage(UIImage(), key)
        let expectation = self.expectationWithDescription("fetch image")

        sut.onMemoryWarning()
        
        sut.fetchImageForKey(key,  success : { _ in
            XCTFail("expected failure")
            expectation.fulfill()
        }, failure : { _ in
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
    
    // MARK: Helpers
    
    func clearMemoryCache() {
        NSNotificationCenter.defaultCenter().postNotificationName(UIApplicationDidReceiveMemoryWarningNotification, object: nil)
    }
}
