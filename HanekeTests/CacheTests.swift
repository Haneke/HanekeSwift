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

class CacheTests: XCTestCase {
    
    var sut : Cache<UIImage>!
    
    override func setUp() {
        super.setUp()
        sut = Cache<UIImage>(self.name)
    }
    
    override func tearDown() {
        sut.removeAll()
        super.tearDown()
    }
    
    func testInit() {
        let name = "name"
        let sut = Cache<UIImage>(name)
        
        XCTAssertNotNil(sut.memoryWarningObserver)
        XCTAssertEqual(name, sut.name)
    }
    
    func testDeinit() {
        weak var sut = Cache<UIImage>("test")
    }
    
    func testAddFormat() {
        let format = Format<UIImage>(self.name)
        
        sut.addFormat(format)
    }
    
    func testSet_WithDefaultFormat () {
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let key = self.name
        let expectation = self.expectationWithDescription(self.name)
        
        sut.set(value: image, key: key)
        
        sut.fetch(key: key, formatName: Haneke.CacheGlobals.OriginalFormatName, success: {
            XCTAssertTrue($0.isEqualPixelByPixel(image))
            expectation.fulfill()
        })
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testSet_WithFormat () {
        let sut = self.sut!
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let key = self.name
        let format = Format<UIImage>(self.name)
        sut.addFormat(format)
        let expectation = self.expectationWithDescription(self.name)
        
        sut.set(value: image, key: key, formatName : format.name)
        
        sut.fetch(key: key, formatName: format.name, success: {
            expectation.fulfill()
            XCTAssertTrue($0.isEqualPixelByPixel(image))
        })
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testSet_WithInexistingFormat () {
        let sut = self.sut!
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let key = self.name
        
        // TODO: Swift doesn't support XCAssertThrows yet. 
        // See: http://stackoverflow.com/questions/25529625/testing-assertion-in-swift
        // XCAssertThrows(sut.set(value: image, key: key, formatName : self.name))
    }
    
    func testSet_WithFormatWithouDiskCapacity() {
        let sut = self.sut!
        let key = self.name
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let format = Format<UIImage>(self.name)
        sut.addFormat(format)
        let expectation = self.expectationWithDescription("fetch image")
        
        sut.set(value: image, key: key, formatName: format.name)

        self.clearMemoryCache()
        sut.fetch(key: key, formatName: format.name, failure: {_ in
            expectation.fulfill()
        }) { _ in
            XCTFail("expected failure")
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testSet_WithFormatWithDiskCapacity() {
        let sut = self.sut!
        let key = self.name
        let image = UIImage.imageWithColor(UIColor.greenColor())
        var format = Format<UIImage>(self.name, diskCapacity: UINT64_MAX)
        sut.addFormat(format)
        let expectation = self.expectationWithDescription("fetch image")
        
        sut.set(value: image, key: key, formatName: format.name)
        
        self.clearMemoryCache()
        sut.fetch(key: key, formatName: format.name, failure : { _ in
            XCTFail("expected success")
            expectation.fulfill()
        }) { _ in
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testFetch_WithKey_OnSuccess () {
        let image = UIImage.imageWithColor(UIColor.cyanColor())
        let key = self.name
        let expectation = self.expectationWithDescription(self.name)
        sut.set(value: image, key: key)
        
        let fetch = sut.fetch(key: key).onSuccess {
            XCTAssertTrue($0.isEqualPixelByPixel(image))
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testFetch_WithKey_OnFailure () {
        let image = UIImage.imageWithColor(UIColor.cyanColor())
        let key = self.name
        let expectation = self.expectationWithDescription(self.name)
        
        let fetch = sut.fetch(key: key).onFailure { error in
            XCTAssertEqual(error!.domain, Haneke.Domain)
            XCTAssertEqual(error!.code, Haneke.CacheGlobals.ErrorCode.ObjectNotFound.toRaw())
            XCTAssertNotNil(error!.localizedDescription)
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testFetch_WithKey_MemoryHit () {
        let image = UIImage.imageWithColor(UIColor.cyanColor())
        let key = self.name
        let expectation = self.expectationWithDescription(self.name)
        
        sut.set(value: image, key: key)
        
        let fetch = sut.fetch(key: key,  success: {
            XCTAssertTrue($0.isEqualPixelByPixel(image))
            expectation.fulfill()
        })
        
        XCTAssertTrue(fetch.hasSucceeded)
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testFetch_WithKey_MemoryMiss_DiskHit () {
        let image = UIImage.imageWithColor(UIColor.redColor(), CGSize(width: 10, height: 20), false)
        let key = self.name
        let expectation = self.expectationWithDescription(self.name)
        sut.set(value: image, key: key)
        self.clearMemoryCache()
        
        let fetch = sut.fetch(key: key,  success: {
            XCTAssertTrue($0.isEqualPixelByPixel(image))
            expectation.fulfill()
        })
        
        XCTAssertFalse(fetch.hasSucceeded)
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testFetch_WithKey_MemoryMiss_DiskMiss () {
        let key = self.name
        let expectation = self.expectationWithDescription(self.name)
        
        let fetch = sut.fetch(key: key, failure : { error in
            XCTAssertEqual(error!.domain, Haneke.Domain)
            XCTAssertEqual(error!.code, Haneke.CacheGlobals.ErrorCode.ObjectNotFound.toRaw())
            XCTAssertNotNil(error!.localizedDescription)
            expectation.fulfill()
        }) { _ in
            XCTFail("expected failure")
            expectation.fulfill()
        }
        
        XCTAssertFalse(fetch.hasSucceeded)
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testFetch_WithKey_InexistingFormat () {
        let key = self.name
        let expectation = self.expectationWithDescription(self.name)
        
        let fetch = sut.fetch(key: key, formatName: self.name, failure : { error in
            XCTAssertEqual(error!.domain, Haneke.Domain)
            XCTAssertEqual(error!.code, Haneke.CacheGlobals.ErrorCode.FormatNotFound.toRaw())
            XCTAssertNotNil(error!.localizedDescription)
            expectation.fulfill()
        }) { _ in
            XCTFail("expected failure")
            expectation.fulfill()
        }
        
        XCTAssertFalse(fetch.hasSucceeded)
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testFetch_WithFetcher_OnSuccess () {
        let image = UIImage.imageWithColor(UIColor.cyanColor())
        let fetcher = SimpleFetcher<UIImage>(key: self.name, thing: image)
        let expectation = self.expectationWithDescription(self.name)
        
        let fetch = sut.fetch(fetcher: fetcher).onSuccess {
            XCTAssertTrue($0.isEqualPixelByPixel(image))
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testFetch_WithFetcher_OnFailure () {
        class FailFetcher<T : DataConvertible> : Fetcher<T> {
            
            var error : NSError!
            
            override init(key : String) {
                super.init(key: key)
            }
            
            override func fetch(failure fail : ((NSError?) -> ()), success succeed : (T.Result) -> ()) {
                fail(error)
            }
            
        }
        
        let fetcher = FailFetcher<UIImage>(key: self.name)
        fetcher.error = NSError(domain: "test", code: 376, userInfo: nil)
        let expectation = self.expectationWithDescription(self.name)
        
        let fetch = sut.fetch(fetcher: fetcher).onFailure { error in
            XCTAssertEqual(error!, fetcher.error)
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testFetch_WithFetcher_MemoryHit () {
        let image = UIImage.imageWithColor(UIColor.cyanColor())
        let key = self.name
        let fetcher = SimpleFetcher<UIImage>(key: key, thing: image)
        let expectation = self.expectationWithDescription(self.name)
        sut.set(value: image, key: key)
        
        let fetch = sut.fetch(fetcher: fetcher, success: {
            XCTAssertTrue($0.isEqualPixelByPixel(image))
            expectation.fulfill()
        })
        
        XCTAssertTrue(fetch.hasSucceeded)
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testFetch_WithFetcher_MemoryMiss_DiskHit () {
        let image = UIImage.imageWithColor(UIColor.redColor(), CGSize(width: 10, height: 20), false)
        let key = self.name
        let fetcher = SimpleFetcher<UIImage>(key: key, thing: image)
        let expectation = self.expectationWithDescription(self.name)
        sut.set(value: image, key: key)
        self.clearMemoryCache()
        
        let fetch = sut.fetch(fetcher: fetcher, success: {
            XCTAssertTrue($0.isEqualPixelByPixel(image))
            expectation.fulfill()
        })
        
        XCTAssertFalse(fetch.hasSucceeded)
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testFetch_WithFetcher_MemoryMiss_DiskMiss () {
        let key = self.name
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let fetcher = SimpleFetcher<UIImage>(key: key, thing: image)
        let expectation = self.expectationWithDescription(self.name)
        
        let fetch = sut.fetch(fetcher: fetcher, failure : { _ in
            XCTFail("expected success")
            expectation.fulfill()
        }) {
            XCTAssertTrue($0.isEqualPixelByPixel(image))
            expectation.fulfill()
        }
        
        XCTAssertFalse(fetch.hasSucceeded)
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testFetch_WithFetcher_ApplyFormat_ScaleModeFill () {
        let key = self.name
        let image = UIImage.imageWithColor(UIColor.greenColor(), CGSizeMake(3, 3))
        let fetcher = SimpleFetcher<UIImage>(key: key, thing: image)
        
        let resizer = ImageResizer(size : CGSizeMake(10, 20), scaleMode : .Fill)
        let format = Format<UIImage>(self.name, transform: {
            return resizer.resizeImage($0)
        })
        sut.addFormat(format)
        let formattedImage = resizer.resizeImage(image)
        let expectation = self.expectationWithDescription(self.name)
        
        let fetch = sut.fetch(fetcher: fetcher, formatName : format.name, failure : { _ in
            XCTFail("expected sucesss")
            expectation.fulfill()
        }) {
            XCTAssertTrue($0.isEqualPixelByPixel(formattedImage))
            expectation.fulfill()
        }
        
        XCTAssertFalse(fetch.hasSucceeded)
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testFetch_WithFetcher_InexistingFormat () {
        let expectation = self.expectationWithDescription(self.name)
        let image = UIImage.imageWithColor(UIColor.redColor())
        let fetcher = SimpleFetcher<UIImage>(key: self.name, thing: image)

        let fetch = sut.fetch(fetcher: fetcher, formatName: self.name, failure : { error in
            XCTAssertEqual(error!.domain, Haneke.Domain)
            XCTAssertEqual(error!.code, Haneke.CacheGlobals.ErrorCode.FormatNotFound.toRaw())
            XCTAssertNotNil(error!.localizedDescription)
            expectation.fulfill()
        }) { _ in
            XCTFail("expected failure")
            expectation.fulfill()
        }
        
        XCTAssertFalse(fetch.hasSucceeded)
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testRemove_Existing() {
        let key = self.name
        sut.set(value: UIImage.imageWithColor(UIColor.greenColor()), key: key)
        let expectation = self.expectationWithDescription("fetch image")

        sut.remove(key: key)
        
        sut.fetch(key: key, failure : { _ in
            expectation.fulfill()
        }) { _ in
            XCTFail("expected failure")
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testRemove_ExistingInFormat() {
        let sut = self.sut!
        let key = "key"
        let format = Format<UIImage>(self.name)
        sut.addFormat(format)
        sut.set(value: UIImage.imageWithColor(UIColor.greenColor()), key: key, formatName: format.name)
        let expectation = self.expectationWithDescription("fetch image")
        
        sut.remove(key: key, formatName: format.name)
        
        sut.fetch(key: key, formatName: format.name, failure : { _ in
            expectation.fulfill()
        }) { _ in
            XCTFail("expected failure")
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testRemoveExistingUsingAnotherFormat() {
        let sut = self.sut!
        let key = "key"
        let format = Format<UIImage>(self.name)
        sut.addFormat(format)
        sut.set(value: UIImage.imageWithColor(UIColor.greenColor()), key: key)
        let expectation = self.expectationWithDescription("fetch image")
        
        sut.remove(key: key, formatName: format.name)
        
        sut.fetch(key: key, failure : { _ in
            XCTFail("expected success")
            expectation.fulfill()
        }) { _ in
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testRemoveExistingUsingInexistingFormat() {
        let sut = self.sut!
        let key = self.name
        let image = UIImage.imageWithColor(UIColor.greenColor())
        sut.set(value: image, key: key)
        let expectation = self.expectationWithDescription("fetch image")
        
        sut.remove(key: key, formatName: self.name)
        
        sut.fetch(key: key, failure : { _ in
            XCTFail("expected success")
            expectation.fulfill()
        }) { _ in
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testRemove_WithInexistingKey() {
        sut.remove(key: self.name)
    }
    
    func testRemoveAll_One() {
        let key = self.name
        sut.set(value: UIImage.imageWithColor(UIColor.greenColor()), key: key)
        let expectation = self.expectationWithDescription("fetch image")
        
        sut.removeAll()
        
        sut.fetch(key: key, failure : { _ in
            expectation.fulfill()
        }) { _ in
            XCTFail("expected failure")
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testRemoveAll_None() {
        sut.removeAll()
    }
    
    func testOnMemoryWarning() {
        let key = self.name
        let image = UIImage.imageWithColor(UIColor.greenColor())
        sut.set(value: image, key: key)
        let expectation = self.expectationWithDescription("fetch image")

        sut.onMemoryWarning()
        
        let fetch = sut.fetch(key: key, failure : { _ in
            XCTFail("expected success")
            expectation.fulfill()
        }) { _ in
            expectation.fulfill()
        }
        XCTAssertFalse(fetch.hasSucceeded)
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testUIApplicationDidReceiveMemoryWarningNotification() {
        let expectation = expectationWithDescription("onMemoryWarning")
        
        class CacheMock<T : DataConvertible where T.Result == T, T : DataRepresentable> : Cache<T> {
            
            var expectation : XCTestExpectation?
            
            override init(_ name: String) {
                super.init(name)
            }
            
            override func onMemoryWarning() {
                super.onMemoryWarning()
                expectation!.fulfill()
            }
        }
        
        let sut = CacheMock<UIImage>("test")
        sut.expectation = expectation // XCode crashes if we use the original expectation directly
        
        NSNotificationCenter.defaultCenter().postNotificationName(UIApplicationDidReceiveMemoryWarningNotification, object: nil)
        
        waitForExpectationsWithTimeout(0, nil)
    }
    
    // MARK: Helpers
    
    func clearMemoryCache() {
        NSNotificationCenter.defaultCenter().postNotificationName(UIApplicationDidReceiveMemoryWarningNotification, object: nil)
    }
}
