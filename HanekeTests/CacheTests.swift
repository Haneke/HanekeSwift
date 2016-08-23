//
//  HanekeCacheTests.swift
//  Haneke
//
//  Created by Luis Ascorbe on 23/07/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import Foundation
import UIKit
import XCTest
@testable import Haneke

class HanekeCacheTests: XCTestCase {
    
    var sut : HanekeCache<Data>!
    
    override func setUp() {
        super.setUp()
        sut = HanekeCache<Data>(name: self.name!)
    }
    
    override func tearDown() {
        var completed = false
        sut.removeAll {
            completed = true
        }
        self.wait(5) {
            return completed
        }
        super.tearDown()
    }
    
    func testInit() {
        let name = "name"
        let sut = HanekeCache<Data>(name: name)
        
        XCTAssertNotNil(sut.memoryWarningObserver)
        XCTAssertEqual(name, sut.name)
        XCTAssertEqual(Int(sut.size), 0)
    }
    
    func testDeinit() {
        weak var _ = HanekeCache<UIImage>(name: self.name!)
    }
    
    // MARK: HanekeCachePath
    
    func testHanekeCachePath() {
        let expectedHanekeCachePath = (DiskHanekeCache.basePath() as NSString).appendingPathComponent(sut.name)
        XCTAssertEqual(sut.HanekeCachePath, expectedHanekeCachePath)
    }
    
    // MARK: formatPath
    
    func testFormatPath() {
        let formatName = self.name!
        let expectedFormatPath = (sut.HanekeCachePath as NSString).appendingPathComponent(formatName)
        
        let formatPath = sut.formatPath(formatName: formatName)
        
        XCTAssertEqual(formatPath, expectedFormatPath)
    }
    
    func testFormatPath_WithEmptyName() {
        let formatName = ""
        let expectedFormatPath = (sut.HanekeCachePath as NSString).appendingPathComponent(formatName)
        
        let formatPath = sut.formatPath(formatName: formatName)
        
        XCTAssertEqual(formatPath, expectedFormatPath)
    }

    // MARK: addFormat
    
    func testAddFormat() {
        let format = Format<Data>(name: self.name!)
        
        sut.addFormat(format)
    }

    // size

    func testSize_WithOneFormat() {
        let data = Data.dataWithLength(6)
        let key = self.name
        let format = Format<Data>(name: self.name)
        sut.addFormat(format)

        var finished = false
        sut.set(value: data, key: key, formatName : format.name, success: { _ in
            finished = true
        })

        XCTAssert(finished, "set completed not in main queue")
        XCTAssertEqual(sut.size, UInt64(data.count))
    }

    func testSize_WithTwoFormats() {
        let lengths = [4, 7]
        let formats = (0..<lengths.count).map { (index: Int) -> Format<Data> in
            let formatName = self.name! + String(index)
            return Format<Data>(name: formatName)
        }
        formats.forEach(sut.addFormat)
        let lenghtsByFormats = zip(lengths, formats)

        lenghtsByFormats.forEach { (length: Int, format: Format<Data>) in
            let data = Data.dataWithLength(length)
            let key = self.name

            var finished = false
            sut.set(value: data, key: key, formatName : format.name, success: { _ in
                finished = true
            })

            XCTAssert(finished, "set completed not in main queue")
        }

        XCTAssertEqual(sut.size, UInt64(lengths.reduce(0, +)))
    }

    // MARK: set
    
    func testSet_WithIdentityFormat_ExpectSyncSuccess() {
        let sut = HanekeCache<Data>(name: self.name!)
        let data = Data.dataWithLength(5)
        let key = self.name!
        let expectation = self.expectation(description: self.name!)
        
        sut.set(value: data, key: key, success: {
            XCTAssertTrue($0 === data)
            expectation.fulfill()
        })
        
        self.waitForExpectations(timeout: 0, handler: nil)
    }
    
    func testSet_WithCustomFormat_ExpectAsyncSuccess () {
        let data = Data.dataWithLength(6)
        let expectedData = Data.dataWithLength(7)
        let key = self.name!
        let format = Format<Data>(name: self.name!, transform: { _ in return expectedData })
        sut.addFormat(format)
        let expectation = self.expectation(description: self.name!)
        
        var finished = false
        sut.set(value: data, key: key, formatName : format.name, success: {
            XCTAssertTrue($0 === expectedData)
            expectation.fulfill()
            finished = true
        })
        
        XCTAssertFalse(finished, "set completed in main queue")
        self.waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testSet_WithInexistingFormat () {
        // TODO: Swift doesn't support XCAssertThrows yet.
        // See: http://stackoverflow.com/questions/25529625/testing-assertion-in-swift

        // let sut = self.sut!
        // let image = UIImage.imageWithColor(UIColor.greenColor())
        // let key = self.name
        // XCAssertThrows(sut.set(value: image, key: key, formatName : self.name))
    }
    
    // MARK: fetch
    
    func testFetchOnSuccess_AfterSet_WithKey_ExpectSyncSuccess () {
        let data = Data.dataWithLength(8)
        let key = self.name!
        let expectation = self.expectation(description: key)
        sut.set(value: data, key: key)

        let fetch = sut.fetch(key: key).onSuccess {
            XCTAssertTrue($0 === data)
            expectation.fulfill()
        }
        
        XCTAssertTrue(fetch.hasSucceeded)
        XCTAssertFalse(fetch.hasFailed)
        self.waitForExpectations(timeout: 0, handler: nil)
    }
    
    func testFetchOnFailure_WithKey_ExpectAsyncFailure () {
        let key = self.name!
        let expectation = self.expectation(description: key)
        
        let fetch = sut.fetch(key: key).onFailure { error in
            XCTAssertEqual(error!.domain, HanekeGlobals.Domain)
            XCTAssertEqual(error!.code, HanekeGlobals.HanekeCache.ErrorCode.objectNotFound.rawValue)
            XCTAssertNotNil(error!.localizedDescription)
            expectation.fulfill()
        }

        XCTAssertFalse(fetch.hasSucceeded)
        XCTAssertFalse(fetch.hasFailed)
        self.waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testFetch_AfterClearingMemoryHanekeCache_WithKey_ExpectAsyncSuccess () {
        let data = Data.dataWithLength(9)
        let key = self.name!
        let expectation = self.expectation(description: key)
        sut.set(value: data, key: key)
        self.clearMemoryHanekeCache()
        
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
        self.waitForExpectations(timeout: 1, handler: nil)
        XCTAssertTrue(fetch.hasSucceeded)
        XCTAssertFalse(fetch.hasFailed)
    }
    
    func testFetch_WithKeyAndExistingFormat_ExpectAsyncFailure () {
        let key = self.name!
        let expectation = self.expectation(description: key)
        
        let fetch = sut.fetch(key: key, failure : { error in
            XCTAssertEqual(error!.domain, HanekeGlobals.Domain)
            XCTAssertEqual(error!.code, HanekeGlobals.HanekeCache.ErrorCode.objectNotFound.rawValue)
            XCTAssertNotNil(error!.localizedDescription)
            expectation.fulfill()
        }) { _ in
            XCTFail("expected failure")
            expectation.fulfill()
        }
        
        XCTAssertFalse(fetch.hasSucceeded)
        XCTAssertFalse(fetch.hasFailed)
        self.waitForExpectations(timeout: 1, handler: nil)
        XCTAssertFalse(fetch.hasSucceeded)
        XCTAssertTrue(fetch.hasFailed)
    }
    
    func testFetch_WithKeyAndInexistingFormat_ExpectSyncFailure () {
        let key = self.name!
        let expectation = self.expectation(description: key)
        
        let fetch = sut.fetch(key: key, formatName: key, failure : { error in
            XCTAssertEqual(error!.domain, HanekeGlobals.Domain)
            XCTAssertEqual(error!.code, HanekeGlobals.HanekeCache.ErrorCode.formatNotFound.rawValue)
            XCTAssertNotNil(error!.localizedDescription)
            expectation.fulfill()
        }) { _ in
            XCTFail("expected failure")
            expectation.fulfill()
        }
        
        XCTAssertFalse(fetch.hasSucceeded)
        XCTAssertTrue(fetch.hasFailed)
        self.waitForExpectations(timeout: 0, handler: nil)
    }
    
    func testFetch_AfterClearingMemoryHanekeCache_WithKeyAndFormatWithoutDiskCapacity_ExpectFailure() {
        let key = self.name!
        let data = Data.dataWithLength(8)
        let format = Format<Data>(name: key, diskCapacity: 0)
        sut.addFormat(format)
        let expectation = self.expectation(description: "fetch image")
        sut.set(value: data, key: key, formatName: format.name)
        self.clearMemoryHanekeCache()
        
        sut.fetch(key: key, formatName: format.name, failure: {_ in
            expectation.fulfill()
            }) { _ in
                XCTFail("expected failure")
                expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testFetch_AfterClearingMemoryHanekeCache_WithKeyAndFormatWithDiskCapacity_ExpectSuccess() {
        let key = self.name!
        let data = Data.dataWithLength(9)
        let format = Format<Data>(name: key)
        sut.addFormat(format)
        let expectation = self.expectation(description: key)
        sut.set(value: data, key: key, formatName: format.name)
        self.clearMemoryHanekeCache()
        
        self.sut.fetch(key: key, formatName: format.name, failure : { _ in
            XCTFail("expected success")
            expectation.fulfill()
            }) { _ in
                expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testFetchOnSuccess_WithSyncFetcher_ExpectAsyncSuccess () {
        let data = Data.dataWithLength(10)
        let fetcher = SimpleFetcher<Data>(key: self.name!, value: data)
        let expectation = self.expectation(description: self.name!)
        
        let fetch = sut.fetch(fetcher: fetcher).onSuccess {
            XCTAssertTrue($0 === data)
            expectation.fulfill()
        }
        
        XCTAssertFalse(fetch.hasSucceeded)
        XCTAssertFalse(fetch.hasFailed)
        self.waitForExpectations(timeout: 1, handler: nil)
        XCTAssertTrue(fetch.hasSucceeded)
        XCTAssertFalse(fetch.hasFailed)
    }
    
    func testFetchOnFailure_WithSyncFailingFetcher_ExpectAsyncFailure() {
        
        let fetcher = FailFetcher<Data>(key: self.name!)
        fetcher.error = Error(domain: "test", code: 376, userInfo: nil)
        let expectation = self.expectation(description: self.name!)
        
        let fetch = sut.fetch(fetcher: fetcher).onFailure { error in
            XCTAssertEqual(error!, fetcher.error)
            expectation.fulfill()
        }
        
        XCTAssertFalse(fetch.hasSucceeded)
        XCTAssertFalse(fetch.hasFailed)
        self.waitForExpectations(timeout: 1, handler: nil)
        XCTAssertFalse(fetch.hasSucceeded)
        XCTAssertTrue(fetch.hasFailed)
    }
    
    func testFetch_AfterSet_WithFetcher_ExpectSyncSuccess () {
        let data = Data.dataWithLength(10)
        let key = self.name!
        let fetcher = SimpleFetcher<Data>(key: key, value: data)
        let expectation = self.expectation(description: key)
        sut.set(value: data, key: key)
        
        let fetch = sut.fetch(fetcher: fetcher, success: {
            XCTAssertEqual($0, data)
            expectation.fulfill()
        })
        
        XCTAssertTrue(fetch.hasSucceeded)
        XCTAssertFalse(fetch.hasFailed)
        self.waitForExpectations(timeout: 0, handler: nil)
    }
    
    func testFetch_AfterSetAndClearingMemoryHanekeCache_WithFetcher_ExpectAsyncSuccess () {
        let data = Data.dataWithLength(10)
        let key = self.name!
        let fetcher = SimpleFetcher<Data>(key: key, value: data)
        let expectation = self.expectation(description: key)
        sut.set(value: data, key: key)
        self.clearMemoryHanekeCache()
        
        let fetch = sut.fetch(fetcher: fetcher, success: {
            XCTAssertTrue($0 !== data)
            XCTAssertEqual($0, data)
            expectation.fulfill()
        })
        
        XCTAssertFalse(fetch.hasSucceeded)
        XCTAssertFalse(fetch.hasFailed)
        self.waitForExpectations(timeout: 1, handler: nil)
        XCTAssertTrue(fetch.hasSucceeded)
        XCTAssertFalse(fetch.hasFailed)
    }
    
    func testFetch_WithSyncFetcher_ExpectAsyncSuccess () {
        let key = self.name!
        let data = Data.dataWithLength(11)
        let fetcher = SimpleFetcher<Data>(key: key, value: data)
        let expectation = self.expectation(description: key)
        
        let fetch = sut.fetch(fetcher: fetcher, failure : { _ in
            XCTFail("expected success")
            expectation.fulfill()
        }) {
            XCTAssertTrue($0 === data)
            expectation.fulfill()
        }
        
        XCTAssertFalse(fetch.hasSucceeded)
        XCTAssertFalse(fetch.hasFailed)
        self.waitForExpectations(timeout: 1, handler: nil)
        XCTAssertTrue(fetch.hasSucceeded)
        XCTAssertFalse(fetch.hasFailed)
    }
    
    func testFetch_WithFetcherAndCustomFormat_ExpectAsyncSuccess () {
        let key = self.name!
        let data = Data.dataWithLength(12)
        let formattedData = Data.dataWithLength(13)
        let fetcher = SimpleFetcher<Data>(key: key, value: data)
        let format = Format<Data>(name: key, transform: { _ in
            return formattedData
        })
        sut.addFormat(format)
        let expectation = self.expectation(description: key)
        
        let fetch = sut.fetch(fetcher: fetcher, formatName : format.name, failure : { _ in
            XCTFail("expected sucesss")
            expectation.fulfill()
        }) {
            XCTAssertTrue($0 === formattedData)
            expectation.fulfill()
        }
        
        XCTAssertFalse(fetch.hasSucceeded)
        XCTAssertFalse(fetch.hasFailed)
        self.waitForExpectations(timeout: 1, handler: nil)
        XCTAssertTrue(fetch.hasSucceeded)
        XCTAssertFalse(fetch.hasFailed)
    }
    
    func testFetch_WithFetcherAndInexistingFormat_ExpectSyncFailure () {
        let expectation = self.expectation(description: self.name!)
        let data = Data.dataWithLength(14)
        let fetcher = SimpleFetcher<Data>(key: self.name!, value: data)

        let fetch = sut.fetch(fetcher: fetcher, formatName: self.name!, failure : { error in
            XCTAssertEqual(error!.domain, HanekeGlobals.Domain)
            XCTAssertEqual(error!.code, HanekeGlobals.HanekeCache.ErrorCode.formatNotFound.rawValue)
            XCTAssertNotNil(error!.localizedDescription)
            expectation.fulfill()
        }) { _ in
            XCTFail("expected failure")
            expectation.fulfill()
        }
        
        XCTAssertFalse(fetch.hasSucceeded)
        XCTAssertTrue(fetch.hasFailed)
        self.waitForExpectations(timeout: 0, handler: nil)
    }
    
    // MARK: remove
    
    func testRemove_WithExistingKey() {
        let key = self.name!
        sut.set(value: Data.dataWithLength(14), key: key)
        let expectation = self.expectation(description: "fetch")

        sut.remove(key: key)
        
        sut.fetch(key: key, failure : { _ in
            expectation.fulfill()
        }) { _ in
            XCTFail("expected failure")
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testRemove_WithExistingKeyInFormat() {
        let key = self.name!
        let format = Format<Data>(name: self.name!)
        sut.addFormat(format)
        sut.set(value:  Data.dataWithLength(15), key: key, formatName: format.name)
        let expectation = self.expectation(description: "fetch")
        
        sut.remove(key: key, formatName: format.name)
        
        sut.fetch(key: key, formatName: format.name, failure : { _ in
            expectation.fulfill()
        }) { _ in
            XCTFail("expected failure")
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testRemove_WithExistingKeyInAnotherFormat() {
        let key = self.name!
        let format = Format<Data>(name: key)
        sut.addFormat(format)
        sut.set(value: Data.dataWithLength(16), key: key)
        let expectation = self.expectation(description: "fetch")
        
        sut.remove(key: key, formatName: format.name)
        
        sut.fetch(key: key, failure : { _ in
            XCTFail("expected success")
            expectation.fulfill()
        }) { _ in
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testRemove_WithExistingKeyAndInexistingFormat() {
        let key = self.name!
        sut.set(value: Data.dataWithLength(17), key: key)
        let expectation = self.expectation(description: "fetch")
        
        sut.remove(key: key, formatName: key)
        
        sut.fetch(key: key, failure : { _ in
            XCTFail("expected success")
            expectation.fulfill()
        }) { _ in
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testRemove_WithInexistingKey() {
        sut.remove(key: self.name!)
    }
    
    // MARK: removeAll
    
    func testRemoveAll_AfterOne() {
        let key = self.name!
        sut.set(value: Data.dataWithLength(18), key: key)
        let expectation = self.expectation(description: "fetch")
        
        sut.removeAll()
        
        sut.fetch(key: key, failure : { _ in
            expectation.fulfill()
        }) { _ in
            XCTFail("expected failure")
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 1, handler: nil)
    }

    func testRemoveAll_Completion() {
        let key = self.name!
        sut.set(value: Data.dataWithLength(18), key: key)
        let expectation = self.expectation(description: "removeAll")
        var completed = false
        sut.removeAll {
            completed = true
            expectation.fulfill()
        }

        XCTAssertFalse(completed)
        self.waitForExpectations(timeout: 1, handler: nil)
    }

    func testRemoveAll_WhenDataAlreadyPresentInHanekeCachePath() {
        let path = (sut.HanekeCachePath as NSString).appendingPathComponent("test")
        let data = Data.dataWithLength(1)
        try? data.write(to: URL(fileURLWithPath: path), options: [.atomic])
        XCTAssertTrue(FileManager.default.fileExists(atPath: path))

        let expectation = self.expectation(description: "removeAll")
        sut.removeAll {
            expectation.fulfill()
        }

        self.waitForExpectations(timeout: 1, handler: nil)
        XCTAssertFalse(FileManager.default.fileExists(atPath: path))
    }
    
    func testRemoveAll_AfterNone() {
        sut.removeAll()
    }
    
    func testOnMemoryWarning() {
        let key = self.name!
        let data = Data.dataWithLength(18)
        sut.set(value: data, key: key)
        let expectation = self.expectation(description: "fetch")

        sut.onMemoryWarning()
        
        let fetch = sut.fetch(key: key, failure : { _ in
            XCTFail("expected success")
            expectation.fulfill()
        }) { _ in
            expectation.fulfill()
        }
        XCTAssertFalse(fetch.hasSucceeded)
        self.waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testUIApplicationDidReceiveMemoryWarningNotification() {
        let expectation = self.expectation(description: "onMemoryWarning")
        
        let sut = HanekeCacheMock<UIImage>(name: self.name!)
        sut.expectation = expectation // XCode crashes if we use the original expectation directly
        
        NotificationCenter.default.post(name: NSNotification.Name.UIApplicationDidReceiveMemoryWarning, object: nil)
        
        waitForExpectations(timeout: 0, handler: nil)
    }
    
    // MARK: Helpers
    
    func clearMemoryHanekeCache() {
        NotificationCenter.default.post(name: NSNotification.Name.UIApplicationDidReceiveMemoryWarning, object: nil)
    }
}

class ImageHanekeCacheTests: XCTestCase {

    var sut : HanekeCache<UIImage>!
    
    override func setUp() {
        super.setUp()
        sut = HanekeCache<UIImage>(name: self.name!)
    }
    
    override func tearDown() {
        sut.removeAll()
        super.tearDown()
    }
    
    func testSet_ExpectAsyncDecompressedImage() {
        let key = self.name!
        sut = HanekeCache<UIImage>(name: key)
        let image = UIImage.imageWithColor(UIColor.green)
        let expectation = self.expectation(description: key)
        
        var finished = false
        sut.set(value: image, key: key, success: {
            finished = true
            XCTAssertTrue($0 !== image)
            XCTAssertTrue($0.isEqualPixelByPixel(image))
            expectation.fulfill()
        })
        
        XCTAssertFalse(finished, "set completed in main queue")
        self.waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testFetchOnSuccess_AfterSet_WithKey_ExpectSyncDecompressedImage () {
        let image = UIImage.imageWithColor(UIColor.cyan)
        let key = self.name!
        let expectation = self.expectation(description: key)
        sut.set(value: image, key: key, success: { decompressedImage in
            
            self.sut.fetch(key: key).onSuccess {
                XCTAssertTrue($0 === decompressedImage)
                XCTAssertTrue($0.isEqualPixelByPixel(image))
                expectation.fulfill()
            }
            
        })
        
        self.waitForExpectations(timeout: 1, handler: nil)
    }
    
}

class FailFetcher<T : DataConvertible> : Fetcher<T> {
    
    var error : Error!
    
    override init(key: String) {
        super.init(key: key)
    }
    
    override func fetch(failure fail : ((Error?) -> ()), success succeed : (T.Result) -> ()) {
        fail(error)
    }
    
}

class HanekeCacheMock<T : DataConvertible> : HanekeCache<T> where T.Result == T, T : DataRepresentable {
    
    var expectation : XCTestExpectation?
    
    override init(name: String) {
        super.init(name: name)
    }
    
    override func onMemoryWarning() {
        super.onMemoryWarning()
        expectation!.fulfill()
    }
}
