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
        sut.removeAllValues()
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
    
    func testSetValueInDefaultFormat () {
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let key = self.name
        let expectation = self.expectationWithDescription(self.name)
        
        sut.setValue(image, key)
        
        sut.fetch(key: key, formatName: OriginalFormatName, success: {
            XCTAssertTrue($0.isEqualPixelByPixel(image))
            expectation.fulfill()
        })
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testSetValueInFormat () {
        let sut = self.sut!
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let key = self.name
        let format = Format<UIImage>(self.name)
        sut.addFormat(format)
        let expectation = self.expectationWithDescription(self.name)
        
        sut.setValue(image, key, formatName : format.name)
        
        sut.fetch(key: key, formatName: format.name, success: {
            expectation.fulfill()
            XCTAssertTrue($0.isEqualPixelByPixel(image))
        })
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testSetValueInInexistingFormat () {
        let sut = self.sut!
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let key = self.name
        
        // TODO: Swift doesn't support XCAssertThrows yet. 
        // See: http://stackoverflow.com/questions/25529625/testing-assertion-in-swift
        // XCAssertThrows(sut.setValue(image, key, formatName : self.name))
    }
    
    func testSetValue_FormatWithouDiskCapacity() {
        let sut = self.sut!
        let key = self.name
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let format = Format<UIImage>(self.name)
        sut.addFormat(format)
        let expectation = self.expectationWithDescription("fetch image")
        
        sut.setValue(image, key, formatName: format.name)

        self.clearMemoryCache()
        sut.fetch(key: key, formatName: format.name, failure: {_ in
            expectation.fulfill()
        }) { _ in
            XCTFail("expected failure")
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testSetValue_FormatWithDiskCapacity() {
        let sut = self.sut!
        let key = self.name
        let image = UIImage.imageWithColor(UIColor.greenColor())
        var format = Format<UIImage>(self.name, diskCapacity: UINT64_MAX)
        sut.addFormat(format)
        let expectation = self.expectationWithDescription("fetch image")
        
        sut.setValue(image, key, formatName: format.name)
        
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
        sut.setValue(image, key)
        
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
            XCTAssertEqual(error!.code, Haneke.CacheError.ObjectNotFound.toRaw())
            XCTAssertNotNil(error!.localizedDescription)
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testFetch_WithKey_MemoryHit () {
        let image = UIImage.imageWithColor(UIColor.cyanColor())
        let key = self.name
        let expectation = self.expectationWithDescription(self.name)
        
        sut.setValue(image, key)
        
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
        sut.setValue(image, key)
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
            XCTAssertEqual(error!.code, Haneke.CacheError.ObjectNotFound.toRaw())
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
            XCTAssertEqual(error!.code, Haneke.CacheError.FormatNotFound.toRaw())
            XCTAssertNotNil(error!.localizedDescription)
            expectation.fulfill()
        }) { _ in
            XCTFail("expected failure")
            expectation.fulfill()
        }
        
        XCTAssertFalse(fetch.hasSucceeded)
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testFetchValueForFetcher_OnSuccess () {
        let image = UIImage.imageWithColor(UIColor.cyanColor())
        let fetcher = SimpleFetcher<UIImage>(key: self.name, thing: image)
        let expectation = self.expectationWithDescription(self.name)
        
        let fetch = sut.fetchValueForFetcher(fetcher).onSuccess {
            XCTAssertTrue($0.isEqualPixelByPixel(image))
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testFetchValueForFetcher_OnFailure () {
        class FailFetcher<T : DataConvertible> : Fetcher<T> {
            
            var error : NSError!
            
            override init(key : String) {
                super.init(key: key)
            }
            
            override func fetch(failure doFailure : ((NSError?) -> ()), success doSuccess : (T.Result) -> ()) {
                doFailure(error)
            }
            
        }
        
        let fetcher = FailFetcher<UIImage>(key: self.name)
        fetcher.error = NSError(domain: "test", code: 376, userInfo: nil)
        let expectation = self.expectationWithDescription(self.name)
        
        let fetch = sut.fetchValueForFetcher(fetcher).onFailure { error in
            XCTAssertEqual(error!, fetcher.error)
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testFetchValueForFetcher_MemoryHit () {
        let image = UIImage.imageWithColor(UIColor.cyanColor())
        let key = self.name
        let fetcher = SimpleFetcher<UIImage>(key: key, thing: image)
        let expectation = self.expectationWithDescription(self.name)
        sut.setValue(image, key)
        
        let fetch = sut.fetchValueForFetcher(fetcher, success: {
            XCTAssertTrue($0.isEqualPixelByPixel(image))
            expectation.fulfill()
        })
        
        XCTAssertTrue(fetch.hasSucceeded)
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testFetchValueForFetcher_MemoryMiss_DiskHit () {
        let image = UIImage.imageWithColor(UIColor.redColor(), CGSize(width: 10, height: 20), false)
        let key = self.name
        let fetcher = SimpleFetcher<UIImage>(key: key, thing: image)
        let expectation = self.expectationWithDescription(self.name)
        sut.setValue(image, key)
        self.clearMemoryCache()
        
        let fetch = sut.fetchValueForFetcher(fetcher, success: {
            XCTAssertTrue($0.isEqualPixelByPixel(image))
            expectation.fulfill()
        })
        
        XCTAssertFalse(fetch.hasSucceeded)
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testFetchValueForFetcher_MemoryMiss_DiskMiss () {
        let key = self.name
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let fetcher = SimpleFetcher<UIImage>(key: key, thing: image)
        let expectation = self.expectationWithDescription(self.name)
        
        let fetch = sut.fetchValueForFetcher(fetcher, failure : { _ in
            XCTFail("expected success")
            expectation.fulfill()
        }) {
            XCTAssertTrue($0.isEqualPixelByPixel(image))
            expectation.fulfill()
        }
        
        XCTAssertFalse(fetch.hasSucceeded)
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testFetchValueForFetcher_ApplyFormat_ScaleModeFill () {
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
        
        let fetch = sut.fetchValueForFetcher(fetcher, formatName : format.name, failure : { _ in
            XCTFail("expected sucesss")
            expectation.fulfill()
        }) {
            XCTAssertTrue($0.isEqualPixelByPixel(formattedImage))
            expectation.fulfill()
        }
        
        XCTAssertFalse(fetch.hasSucceeded)
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testFetchValueForFetcher_InexistingFormat () {
        let expectation = self.expectationWithDescription(self.name)
        let image = UIImage.imageWithColor(UIColor.redColor())
        let fetcher = SimpleFetcher<UIImage>(key: self.name, thing: image)

        let fetch = sut.fetchValueForFetcher(fetcher, formatName: self.name, failure : { error in
            XCTAssertEqual(error!.domain, Haneke.Domain)
            XCTAssertEqual(error!.code, Haneke.CacheError.FormatNotFound.toRaw())
            XCTAssertNotNil(error!.localizedDescription)
            expectation.fulfill()
        }) { _ in
            XCTFail("expected failure")
            expectation.fulfill()
        }
        
        XCTAssertFalse(fetch.hasSucceeded)
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testRemoveValue_Existing() {
        let key = self.name
        sut.setValue(UIImage.imageWithColor(UIColor.greenColor()), key)
        let expectation = self.expectationWithDescription("fetch image")

        sut.removeValue(key)
        
        sut.fetch(key: key, failure : { _ in
            expectation.fulfill()
        }) { _ in
            XCTFail("expected failure")
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testRemoveValue_ExistingInFormat() {
        let sut = self.sut!
        let key = "key"
        let format = Format<UIImage>(self.name)
        sut.addFormat(format)
        sut.setValue(UIImage.imageWithColor(UIColor.greenColor()), key, formatName: format.name)
        let expectation = self.expectationWithDescription("fetch image")
        
        sut.removeValue(key, formatName: format.name)
        
        sut.fetch(key: key, formatName: format.name, failure : { _ in
            expectation.fulfill()
        }) { _ in
            XCTFail("expected failure")
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testRemoveValueExistingUsingAnotherFormat() {
        let sut = self.sut!
        let key = "key"
        let format = Format<UIImage>(self.name)
        sut.addFormat(format)
        sut.setValue(UIImage.imageWithColor(UIColor.greenColor()), key)
        let expectation = self.expectationWithDescription("fetch image")
        
        sut.removeValue(key, formatName: format.name)
        
        sut.fetch(key: key, failure : { _ in
            XCTFail("expected success")
            expectation.fulfill()
        }) { _ in
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testRemoveValueExistingUsingInexistingFormat() {
        let sut = self.sut!
        let key = self.name
        let image = UIImage.imageWithColor(UIColor.greenColor())
        sut.setValue(image, key)
        let expectation = self.expectationWithDescription("fetch image")
        
        sut.removeValue(key, formatName: self.name)
        
        sut.fetch(key: key, failure : { _ in
            XCTFail("expected success")
            expectation.fulfill()
        }) { _ in
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testRemoveValueInexisting() {
        sut.removeValue(self.name)
    }
    
    func testRemoveAllValues_One() {
        let key = self.name
        sut.setValue(UIImage.imageWithColor(UIColor.greenColor()), key)
        let expectation = self.expectationWithDescription("fetch image")
        
        sut.removeAllValues()
        
        sut.fetch(key: key, failure : { _ in
            expectation.fulfill()
        }) { _ in
            XCTFail("expected failure")
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testRemoveAllValues_None() {
        sut.removeAllValues()
    }
    
    func testOnMemoryWarning() {
        let key = self.name
        let image = UIImage.imageWithColor(UIColor.greenColor())
        sut.setValue(image, key)
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
