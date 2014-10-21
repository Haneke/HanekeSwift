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
    
    var sut : Cache<NSData>!
    
    override func setUp() {
        super.setUp()
        sut = Cache<NSData>(name: self.name)
    }
    
    override func tearDown() {
        sut.removeAll()
        super.tearDown()
    }
    
    func testInit() {
        let name = "name"
        let sut = Cache<NSData>(name: name)
        
        XCTAssertNotNil(sut.memoryWarningObserver)
        XCTAssertEqual(name, sut.name)
    }
    
    func testDeinit() {
        weak var sut = Cache<UIImage>(name: self.name)
    }
    
    // MARK: cachePath
    
    func testCachePath() {
        let expectedCachePath = DiskCache.basePath().stringByAppendingPathComponent(sut.name)
        XCTAssertEqual(sut.cachePath, expectedCachePath)
    }
    
    // MARK: formatPath
    
    func testFormatPath() {
        let formatName = self.name
        let expectedFormatPath = sut.cachePath.stringByAppendingPathComponent(formatName)
        
        let formatPath = sut.formatPath(formatName: formatName)
        
        XCTAssertEqual(formatPath, expectedFormatPath)
    }
    
    func testFormatPath_WithEmptyName() {
        let formatName = ""
        let expectedFormatPath = sut.cachePath.stringByAppendingPathComponent(formatName)
        
        let formatPath = sut.formatPath(formatName: formatName)
        
        XCTAssertEqual(formatPath, expectedFormatPath)
    }

    // MARK: addFormat
    
    func testAddFormat() {
        let format = Format<NSData>(name: self.name)
        
        sut.addFormat(format)
    }

    // MARK: set
    
    func testSet_WithIdentityFormat_ExpectSyncSuccess() {
        let sut = Cache<NSData>(name: self.name)
        let data = NSData.dataWithLength(5)
        let key = self.name
        let expectation = self.expectationWithDescription(self.name)
        
        sut.set(value: data, key: key, success: {
            XCTAssertTrue($0 === data)
            expectation.fulfill()
        })
        
        self.waitForExpectationsWithTimeout(0, nil)
    }
    
    func testSet_WithCustomFormat_ExpectAsyncSuccess () {
        let data = NSData.dataWithLength(6)
        let expectedData = NSData.dataWithLength(7)
        let key = self.name
        let format = Format<NSData>(name: self.name, transform: { _ in return expectedData })
        sut.addFormat(format)
        let expectation = self.expectationWithDescription(self.name)
        
        var finished = false
        sut.set(value: data, key: key, formatName : format.name, success: {
            XCTAssertTrue($0 === expectedData)
            expectation.fulfill()
            finished = true
        })
        
        XCTAssertFalse(finished, "set completed in main queue")
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
    
    // MARK: fetch
    
    func testFetchOnSuccess_AfterSet_WithKey_ExpectSyncSuccess () {
        let data = NSData.dataWithLength(8)
        let key = self.name
        let expectation = self.expectationWithDescription(self.name)
        sut.set(value: data, key: key)

        let fetch = sut.fetch(key: key).onSuccess {
            XCTAssertTrue($0 === data)
            expectation.fulfill()
        }
        
        XCTAssertTrue(fetch.hasSucceeded)
        XCTAssertFalse(fetch.hasFailed)
        self.waitForExpectationsWithTimeout(0, nil)
    }
    
    func testFetchOnFailure_WithKey_ExpectAsyncFailure () {
        let key = self.name
        let expectation = self.expectationWithDescription(self.name)
        
        let fetch = sut.fetch(key: key).onFailure { error in
            XCTAssertEqual(error!.domain, Haneke.Domain)
            XCTAssertEqual(error!.code, Haneke.CacheGlobals.ErrorCode.ObjectNotFound.rawValue)
            XCTAssertNotNil(error!.localizedDescription)
            expectation.fulfill()
        }

        XCTAssertFalse(fetch.hasSucceeded)
        XCTAssertFalse(fetch.hasFailed)
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testFetch_AfterClearingMemoryCache_WithKey_ExpectAsyncSuccess () {
        let data = NSData.dataWithLength(9)
        let key = self.name
        let expectation = self.expectationWithDescription(self.name)
        sut.set(value: data, key: key)
        self.clearMemoryCache()
        
        let fetch = sut.fetch(key: key, failure: { _ in
            XCTFail("expected success")
            expectation.fulfill()
        }, success: {
            XCTAssertTrue($0 !== data)
            XCTAssertEqual($0, data)
            expectation.fulfill()
        })
        
        XCTAssertFalse(fetch.hasSucceeded)
        XCTAssertFalse(fetch.hasFailed)
        self.waitForExpectationsWithTimeout(1, nil)
        XCTAssertTrue(fetch.hasSucceeded)
        XCTAssertFalse(fetch.hasFailed)
    }
    
    func testFetch_WithKeyAndExistingFormat_ExpectAsyncFailure () {
        let key = self.name
        let expectation = self.expectationWithDescription(self.name)
        
        let fetch = sut.fetch(key: key, failure : { error in
            XCTAssertEqual(error!.domain, Haneke.Domain)
            XCTAssertEqual(error!.code, Haneke.CacheGlobals.ErrorCode.ObjectNotFound.rawValue)
            XCTAssertNotNil(error!.localizedDescription)
            expectation.fulfill()
        }) { _ in
            XCTFail("expected failure")
            expectation.fulfill()
        }
        
        XCTAssertFalse(fetch.hasSucceeded)
        XCTAssertFalse(fetch.hasFailed)
        self.waitForExpectationsWithTimeout(1, nil)
        XCTAssertFalse(fetch.hasSucceeded)
        XCTAssertTrue(fetch.hasFailed)
    }
    
    func testFetch_WithKeyAndInexistingFormat_ExpectSyncFailure () {
        let key = self.name
        let expectation = self.expectationWithDescription(self.name)
        
        let fetch = sut.fetch(key: key, formatName: self.name, failure : { error in
            XCTAssertEqual(error!.domain, Haneke.Domain)
            XCTAssertEqual(error!.code, Haneke.CacheGlobals.ErrorCode.FormatNotFound.rawValue)
            XCTAssertNotNil(error!.localizedDescription)
            expectation.fulfill()
        }) { _ in
            XCTFail("expected failure")
            expectation.fulfill()
        }
        
        XCTAssertFalse(fetch.hasSucceeded)
        XCTAssertTrue(fetch.hasFailed)
        self.waitForExpectationsWithTimeout(0, nil)
    }
    
    func testFetch_AfterClearingMemoryCache_WithKeyAndFormatWithoutDiskCapacity_ExpectFailure() {
        let key = self.name
        let data = NSData.dataWithLength(8)
        let format = Format<NSData>(name: self.name, diskCapacity: 0)
        sut.addFormat(format)
        let expectation = self.expectationWithDescription("fetch image")
        sut.set(value: data, key: key, formatName: format.name)
        self.clearMemoryCache()
        
        sut.fetch(key: key, formatName: format.name, failure: {_ in
            expectation.fulfill()
            }) { _ in
                XCTFail("expected failure")
                expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testFetch_AfterClearingMemoryCache_WithKeyAndFormatWithDiskCapacity_ExpectSuccess() {
        let key = self.name
        let data = NSData.dataWithLength(9)
        var format = Format<NSData>(name: self.name)
        sut.addFormat(format)
        let expectation = self.expectationWithDescription(self.name)
        sut.set(value: data, key: key, formatName: format.name)
        self.clearMemoryCache()
        
        self.sut.fetch(key: key, formatName: format.name, failure : { _ in
            XCTFail("expected success")
            expectation.fulfill()
            }) { _ in
                expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testFetchOnSuccess_WithSyncFetcher_ExpectAsyncSuccess () {
        let data = NSData.dataWithLength(10)
        let fetcher = SimpleFetcher<NSData>(key: self.name, value: data)
        let expectation = self.expectationWithDescription(self.name)
        
        let fetch = sut.fetch(fetcher: fetcher).onSuccess {
            XCTAssertTrue($0 === data)
            expectation.fulfill()
        }
        
        XCTAssertFalse(fetch.hasSucceeded)
        XCTAssertFalse(fetch.hasFailed)
        self.waitForExpectationsWithTimeout(1, nil)
        XCTAssertTrue(fetch.hasSucceeded)
        XCTAssertFalse(fetch.hasFailed)
    }
    
    func testFetchOnFailure_WithSyncFailingFetcher_ExpectAsyncFailure() {
        
        let fetcher = FailFetcher<NSData>(key: self.name)
        fetcher.error = NSError(domain: "test", code: 376, userInfo: nil)
        let expectation = self.expectationWithDescription(self.name)
        
        let fetch = sut.fetch(fetcher: fetcher).onFailure { error in
            XCTAssertEqual(error!, fetcher.error)
            expectation.fulfill()
        }
        
        XCTAssertFalse(fetch.hasSucceeded)
        XCTAssertFalse(fetch.hasFailed)
        self.waitForExpectationsWithTimeout(1, nil)
        XCTAssertFalse(fetch.hasSucceeded)
        XCTAssertTrue(fetch.hasFailed)
    }
    
    func testFetch_AfterSet_WithFetcher_ExpectSyncSuccess () {
        let data = NSData.dataWithLength(10)
        let key = self.name
        let fetcher = SimpleFetcher<NSData>(key: key, value: data)
        let expectation = self.expectationWithDescription(self.name)
        sut.set(value: data, key: key)
        
        let fetch = sut.fetch(fetcher: fetcher, success: {
            XCTAssertEqual($0, data)
            expectation.fulfill()
        })
        
        XCTAssertTrue(fetch.hasSucceeded)
        XCTAssertFalse(fetch.hasFailed)
        self.waitForExpectationsWithTimeout(0, nil)
    }
    
    func testFetch_AfterSetAndClearingMemoryCache_WithFetcher_ExpectAsyncSuccess () {
        let data = NSData.dataWithLength(10)
        let key = self.name
        let fetcher = SimpleFetcher<NSData>(key: key, value: data)
        let expectation = self.expectationWithDescription(self.name)
        sut.set(value: data, key: key)
        self.clearMemoryCache()
        
        let fetch = sut.fetch(fetcher: fetcher, success: {
            XCTAssertTrue($0 !== data)
            XCTAssertEqual($0, data)
            expectation.fulfill()
        })
        
        XCTAssertFalse(fetch.hasSucceeded)
        XCTAssertFalse(fetch.hasFailed)
        self.waitForExpectationsWithTimeout(1, nil)
        XCTAssertTrue(fetch.hasSucceeded)
        XCTAssertFalse(fetch.hasFailed)
    }
    
    func testFetch_WithSyncFetcher_ExpectAsyncSuccess () {
        let key = self.name
        let data = NSData.dataWithLength(11)
        let fetcher = SimpleFetcher<NSData>(key: key, value: data)
        let expectation = self.expectationWithDescription(self.name)
        
        let fetch = sut.fetch(fetcher: fetcher, failure : { _ in
            XCTFail("expected success")
            expectation.fulfill()
        }) {
            XCTAssertTrue($0 === data)
            expectation.fulfill()
        }
        
        XCTAssertFalse(fetch.hasSucceeded)
        XCTAssertFalse(fetch.hasFailed)
        self.waitForExpectationsWithTimeout(1, nil)
        XCTAssertTrue(fetch.hasSucceeded)
        XCTAssertFalse(fetch.hasFailed)
    }
    
    func testFetch_WithFetcherAndCustomFormat_ExpectAsyncSuccess () {
        let key = self.name
        let data = NSData.dataWithLength(12)
        let formattedData = NSData.dataWithLength(13)
        let fetcher = SimpleFetcher<NSData>(key: key, value: data)
        let format = Format<NSData>(name: self.name, transform: { _ in
            return formattedData
        })
        sut.addFormat(format)
        let expectation = self.expectationWithDescription(self.name)
        
        let fetch = sut.fetch(fetcher: fetcher, formatName : format.name, failure : { _ in
            XCTFail("expected sucesss")
            expectation.fulfill()
        }) {
            XCTAssertTrue($0 === formattedData)
            expectation.fulfill()
        }
        
        XCTAssertFalse(fetch.hasSucceeded)
        XCTAssertFalse(fetch.hasFailed)
        self.waitForExpectationsWithTimeout(1, nil)
        XCTAssertTrue(fetch.hasSucceeded)
        XCTAssertFalse(fetch.hasFailed)
    }
    
    func testFetch_WithFetcherAndInexistingFormat_ExpectSyncFailure () {
        let expectation = self.expectationWithDescription(self.name)
        let data = NSData.dataWithLength(14)
        let fetcher = SimpleFetcher<NSData>(key: self.name, value: data)

        let fetch = sut.fetch(fetcher: fetcher, formatName: self.name, failure : { error in
            XCTAssertEqual(error!.domain, Haneke.Domain)
            XCTAssertEqual(error!.code, Haneke.CacheGlobals.ErrorCode.FormatNotFound.rawValue)
            XCTAssertNotNil(error!.localizedDescription)
            expectation.fulfill()
        }) { _ in
            XCTFail("expected failure")
            expectation.fulfill()
        }
        
        XCTAssertFalse(fetch.hasSucceeded)
        XCTAssertTrue(fetch.hasFailed)
        self.waitForExpectationsWithTimeout(0, nil)
    }
    
    // MARK: remove
    
    func testRemove_WithExistingKey() {
        let key = self.name
        sut.set(value: NSData.dataWithLength(14), key: key)
        let expectation = self.expectationWithDescription("fetch")

        sut.remove(key: key)
        
        sut.fetch(key: key, failure : { _ in
            expectation.fulfill()
        }) { _ in
            XCTFail("expected failure")
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testRemove_WithExistingKeyInFormat() {
        let key = self.name
        let format = Format<NSData>(name: self.name)
        sut.addFormat(format)
        sut.set(value:  NSData.dataWithLength(15), key: key, formatName: format.name)
        let expectation = self.expectationWithDescription("fetch")
        
        sut.remove(key: key, formatName: format.name)
        
        sut.fetch(key: key, formatName: format.name, failure : { _ in
            expectation.fulfill()
        }) { _ in
            XCTFail("expected failure")
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testRemove_WithExistingKeyInAnotherFormat() {
        let key = self.name
        let format = Format<NSData>(name: self.name)
        sut.addFormat(format)
        sut.set(value: NSData.dataWithLength(16), key: key)
        let expectation = self.expectationWithDescription("fetch")
        
        sut.remove(key: key, formatName: format.name)
        
        sut.fetch(key: key, failure : { _ in
            XCTFail("expected success")
            expectation.fulfill()
        }) { _ in
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testRemove_WithExistingKeyAndInexistingFormat() {
        let key = self.name
        sut.set(value: NSData.dataWithLength(17), key: key)
        let expectation = self.expectationWithDescription("fetch")
        
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
    
    // MARK: removeAll
    
    func testRemoveAll_AfterOne() {
        let key = self.name
        sut.set(value: NSData.dataWithLength(18), key: key)
        let expectation = self.expectationWithDescription("fetch")
        
        sut.removeAll()
        
        sut.fetch(key: key, failure : { _ in
            expectation.fulfill()
        }) { _ in
            XCTFail("expected failure")
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testRemoveAll_AfterNone() {
        sut.removeAll()
    }
    
    func testOnMemoryWarning() {
        let key = self.name
        let data = NSData.dataWithLength(18)
        sut.set(value: data, key: key)
        let expectation = self.expectationWithDescription("fetch")

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
        
        let sut = CacheMock<UIImage>(name: self.name)
        sut.expectation = expectation // XCode crashes if we use the original expectation directly
        
        NSNotificationCenter.defaultCenter().postNotificationName(UIApplicationDidReceiveMemoryWarningNotification, object: nil)
        
        waitForExpectationsWithTimeout(0, nil)
    }
    
    // MARK: Helpers
    
    func clearMemoryCache() {
        NSNotificationCenter.defaultCenter().postNotificationName(UIApplicationDidReceiveMemoryWarningNotification, object: nil)
    }
}

class ImageCacheTests: XCTestCase {

    var sut : Cache<UIImage>!
    
    override func setUp() {
        super.setUp()
        sut = Cache<UIImage>(name: self.name)
    }
    
    override func tearDown() {
        sut.removeAll()
        super.tearDown()
    }
    
    func testSet_ExpectAsyncDecompressedImage() {
        sut = Cache<UIImage>(name: self.name)
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let key = self.name
        let expectation = self.expectationWithDescription(self.name)
        
        var finished = false
        sut.set(value: image, key: key, success: {
            finished = true
            XCTAssertTrue($0 !== image)
            XCTAssertTrue($0.isEqualPixelByPixel(image))
            expectation.fulfill()
        })
        
        XCTAssertFalse(finished, "set completed in main queue")
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
    func testFetchOnSuccess_AfterSet_WithKey_ExpectSyncDecompressedImage () {
        let image = UIImage.imageWithColor(UIColor.cyanColor())
        let key = self.name
        let expectation = self.expectationWithDescription(self.name)
        sut.set(value: image, key: key, success: { decompressedImage in
            
            self.sut.fetch(key: key).onSuccess {
                XCTAssertTrue($0 === decompressedImage)
                XCTAssertTrue($0.isEqualPixelByPixel(image))
                expectation.fulfill()
            }
            
            self.waitForExpectationsWithTimeout(0, nil)
        })
        
        self.waitForExpectationsWithTimeout(1, nil)
    }
    
}

class FailFetcher<T : DataConvertible> : Fetcher<T> {
    
    var error : NSError!
    
    override init(key : String) {
        super.init(key: key)
    }
    
    override func fetch(failure fail : ((NSError?) -> ()), success succeed : (T.Result) -> ()) {
        fail(error)
    }
    
}

class CacheMock<T : DataConvertible where T.Result == T, T : DataRepresentable> : Cache<T> {
    
    var expectation : XCTestExpectation?
    
    override init(name: String) {
        super.init(name: name)
    }
    
    override func onMemoryWarning() {
        super.onMemoryWarning()
        expectation!.fulfill()
    }
}
