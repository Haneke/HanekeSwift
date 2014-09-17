//
//  DiskCacheTests.swift
//  Haneke
//
//  Created by Hermes Pique on 8/10/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import UIKit
import XCTest

class DiskCacheTests: XCTestCase {

    var sut : DiskCache!
    
    override func setUp() {
        super.setUp()
        sut = DiskCache(self.name, capacity : UINT64_MAX)
    }
    
    override func tearDown() {
        let fileManager = NSFileManager.defaultManager()
        fileManager.removeItemAtPath(sut.cachePath, error:nil)
        super.tearDown()
    }
    
    func testBasePath() {
        let cachesPath = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.CachesDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0] as String
        let basePath = cachesPath.stringByAppendingPathComponent(Haneke.Domain)
        XCTAssertEqual(DiskCache.basePath(), basePath)
    }
    
    func testInit() {
        let name = self.name

        let sut = DiskCache(name, capacity : UINT64_MAX)
        
        XCTAssertEqual(sut.name, name)
        XCTAssertEqual(sut.size, 0)
    }
    
    func testInitWithOneFile() {
        let name = self.name
        let directory = DiskCache(name, capacity : UINT64_MAX).cachePath
        let expectedSize = 8
        self.writeDataWithLength(expectedSize, directory: directory)
        
        let sut = DiskCache(name, capacity : UINT64_MAX)
        
        dispatch_sync(sut.cacheQueue, {
            XCTAssertEqual(sut.size, UInt64(expectedSize))
        })
    }
    
    func testInitWithTwoFiles() {
        let name = self.name
        let directory = DiskCache(name, capacity : UINT64_MAX).cachePath
        let lengths = [4, 7]
        self.writeDataWithLength(lengths[0], directory: directory)
        self.writeDataWithLength(lengths[1], directory: directory)
        
        let sut = DiskCache(name, capacity : UINT64_MAX)
        
        dispatch_sync(sut.cacheQueue, {
            XCTAssertEqual(sut.size, UInt64(lengths.reduce(0, +)))
        })
    }
    
    func testInitCapacityZeroOneExistingFile() {
        let name = self.name
        let directory = DiskCache(name, capacity : UINT64_MAX).cachePath
        let path = self.writeDataWithLength(1, directory: directory)
        
        let sut = DiskCache(name, capacity : 0)
        
        dispatch_sync(sut.cacheQueue, {
            XCTAssertEqual(sut.size, 0)
            XCTAssertFalse(NSFileManager.defaultManager().fileExistsAtPath(path))
        })
    }
    
    func testInitCapacityZeroTwoExistingFiles() {
        let name = self.name
        let directory = DiskCache(name, capacity : UINT64_MAX).cachePath
        let path1 = self.writeDataWithLength(1, directory: directory)
        let path2 = self.writeDataWithLength(2, directory: directory)
        
        let sut = DiskCache(name, capacity : 0)
        
        dispatch_sync(sut.cacheQueue, {
            XCTAssertEqual(sut.size, 0)
            XCTAssertFalse(NSFileManager.defaultManager().fileExistsAtPath(path1))
            XCTAssertFalse(NSFileManager.defaultManager().fileExistsAtPath(path2))
        })
    }
    
    func testInitLeastRecentlyUsedExistingFileDeleted() {
        let name = self.name
        let directory = DiskCache(name, capacity : UINT64_MAX).cachePath
        let path1 = self.writeDataWithLength(1, directory: directory)
        let path2 = self.writeDataWithLength(1, directory: directory)
        NSFileManager.defaultManager().setAttributes([NSFileModificationDate : NSDate.distantPast()], ofItemAtPath: path2, error: nil)
        
        let sut = DiskCache(name, capacity : 1)
        
        dispatch_sync(sut.cacheQueue, {
            XCTAssertEqual(sut.size, 1)
            XCTAssertTrue(NSFileManager.defaultManager().fileExistsAtPath(path1))
            XCTAssertFalse(NSFileManager.defaultManager().fileExistsAtPath(path2))
        })
    }
    
    func testCachePath() {
        let cachePath = DiskCache.basePath().stringByAppendingPathComponent(sut.name)
        XCTAssertEqual(sut.cachePath, cachePath)
        
        let fileManager = NSFileManager.defaultManager()
        var isDirectory: ObjCBool = ObjCBool(0)
        XCTAssertTrue(fileManager.fileExistsAtPath(cachePath, isDirectory: &isDirectory))
        XCTAssertTrue(isDirectory)
    }
    
    func testCachePathEmtpyName() {
        let sut = DiskCache("", capacity : UINT64_MAX)
        let cachePath = DiskCache.basePath()
        XCTAssertEqual(sut.cachePath, cachePath)
        
        let fileManager = NSFileManager.defaultManager()
        var isDirectory: ObjCBool = ObjCBool(0)
        XCTAssertTrue(fileManager.fileExistsAtPath(cachePath, isDirectory: &isDirectory))
        XCTAssertTrue(isDirectory)
    }
    
    func testCacheQueue() {
        let expectedLabel = Haneke.Domain + "." + sut.name

        let label = String.stringWithUTF8String(dispatch_queue_get_label(sut.cacheQueue))!

        XCTAssertEqual(label, expectedLabel)
    }
    
    func testSetCapacity() {
        sut.setData(NSData.dataWithLength(1), key: self.name)
        
        sut.capacity = 0
        
        dispatch_sync(sut.cacheQueue, {
            XCTAssertEqual(self.sut.size, 0)
        })        
    }
    
    func testSetData() {
        let data = UIImagePNGRepresentation(UIImage.imageWithColor(UIColor.redColor()))
        let key = self.name
        let path = sut.pathForKey(key)
        
        sut.setData(data, key: key)
        
        dispatch_sync(sut.cacheQueue, {
            let fileManager = NSFileManager.defaultManager()
            XCTAssertTrue(fileManager.fileExistsAtPath(path))
            let resultData = NSData(contentsOfFile:path)
            XCTAssertEqual(resultData, data)
            XCTAssertEqual(self.sut.size, UInt64(data.length))
        })
    }
    
    func testSetData_EscapedFilename() {
        let sut = self.sut!
        let data = UIImagePNGRepresentation(UIImage.imageWithColor(UIColor.redColor()))
        let key = "http://haneke.io"
        let path = sut.pathForKey(key)
        
        sut.setData(data, key: key)
        
        dispatch_sync(sut.cacheQueue, {
            let fileManager = NSFileManager.defaultManager()
            XCTAssertTrue(fileManager.fileExistsAtPath(path))
            let resultData = NSData(contentsOfFile:path)
            XCTAssertEqual(resultData, data)
            XCTAssertEqual(sut.size, UInt64(data.length))
        })
    }
    
    func testSetDataSizeGreaterThanZero() {
        let originalData = NSData.dataWithLength(5)
        let lengths = [5, 14]
        let keys = ["1", "2"]
        sut.setData(NSData.dataWithLength(lengths[0]), key: keys[0])
        
        sut.setData(NSData.dataWithLength(lengths[1]), key: keys[1])
        
        dispatch_sync(sut.cacheQueue, {
            XCTAssertEqual(self.sut.size, UInt64(lengths.reduce(0, combine: +)))
        })
    }
    
    func testSetDataReplace() {
        let originalData = NSData.dataWithLength(5)
        let data = NSData.dataWithLength(14)
        let key = self.name
        let path = sut.pathForKey(key)
        sut.setData(originalData, key: key)
        
        sut.setData(data, key: key)
        
        dispatch_sync(sut.cacheQueue, {
            let fileManager = NSFileManager.defaultManager()
            XCTAssertTrue(fileManager.fileExistsAtPath(path))
            let resultData = NSData(contentsOfFile:path)
            XCTAssertEqual(resultData, data)
            XCTAssertEqual(self.sut.size, UInt64(data.length))
        })
    }
    
    func testSetDataNil() {
        let key = self.name
        let path = sut.pathForKey(key)
        
        sut.setData({ return nil }(), key: key)
        
        dispatch_sync(sut.cacheQueue, {
            let fileManager = NSFileManager.defaultManager()
            XCTAssertFalse(fileManager.fileExistsAtPath(path))
            XCTAssertEqual(self.sut.size, 0)
        })
    }
    
    func testSetDataControlCapacity() {
        let sut = DiskCache(self.name, capacity:0)
        let key = self.name
        let path = sut.pathForKey(key)
        
        sut.setData(NSData.dataWithLength(1), key: key)
        
        dispatch_sync(sut.cacheQueue, {
            let fileManager = NSFileManager.defaultManager()
            XCTAssertFalse(fileManager.fileExistsAtPath(path))
            XCTAssertEqual(sut.size, 0)
        })
    }
    
    func testFetchData() {
        let data = NSData.dataWithLength(14)
        let key = self.name
        sut.setData(data, key : key)
        
        let expectation = self.expectationWithDescription(self.name)
        
        sut.fetchData(key, {
            expectation.fulfill()
            XCTAssertEqual($0, data)
        })
        
        dispatch_sync(sut.cacheQueue, {
            self.waitForExpectationsWithTimeout(0, nil)
        })
    }
    
    func testFetchData_Inexisting() {
        let key = self.name
        let expectation = self.expectationWithDescription(self.name)
        
        sut.fetchData(key,  success : { data in
            expectation.fulfill()
            XCTFail("Expected failure")
        }, failure : { errorOpt in
            expectation.fulfill()
            let error = errorOpt!
            XCTAssertEqual(error.code, NSFileReadNoSuchFileError)
        })
        
        dispatch_sync(sut.cacheQueue, {
            self.waitForExpectationsWithTimeout(0, nil)
        })
    }
    
    func testFetchData_Inexisting_NilFailureBlock() {
        let key = self.name
        
        sut.fetchData(key, { data in
            XCTFail("Expected failure")
        })
        
        dispatch_sync(sut.cacheQueue, {})
    }
    
    func testFetchData_UpdateAccessDate() {
        let data = NSData.dataWithLength(19)
        let key = self.name
        sut.setData(data, key : key)
        let path = sut.pathForKey(key)
        let fileManager = NSFileManager.defaultManager()
        dispatch_sync(sut.cacheQueue, {
            let _ = fileManager.setAttributes([NSFileModificationDate : NSDate.distantPast()], ofItemAtPath: path, error: nil)
        })
        let expectation = self.expectationWithDescription(self.name)
        
        // Preconditions
        dispatch_sync(sut.cacheQueue, {
            let attributes = fileManager.attributesOfItemAtPath(path, error: nil)!
            let accessDate = attributes[NSFileModificationDate] as NSDate
            XCTAssertEqual(accessDate, NSDate.distantPast() as NSDate)
        })
        
        sut.fetchData(key, {
            expectation.fulfill()
            XCTAssertEqual($0, data)
        })
        
        dispatch_sync(sut.cacheQueue, {
            self.waitForExpectationsWithTimeout(0, nil)
            
            let attributes = fileManager.attributesOfItemAtPath(path, error: nil)!
            let accessDate = attributes[NSFileModificationDate] as NSDate
            let now = NSDate()
            let interval = accessDate.timeIntervalSinceDate(now)
            XCTAssertEqualWithAccuracy(interval, 0, 1)
        })
    }
    
    func testRemoveDataTwoKeys() {
        let keys = ["1", "2"]
        let datas = [NSData.dataWithLength(5), NSData.dataWithLength(7)]
        sut.setData(datas[0], key: keys[0])
        sut.setData(datas[1], key: keys[1])

        sut.removeData(keys[1])
        
        dispatch_sync(sut.cacheQueue, {
            let fileManager = NSFileManager.defaultManager()
            let path = self.sut.pathForKey(keys[1])
            XCTAssertFalse(fileManager.fileExistsAtPath(path))
            XCTAssertEqual(self.sut.size, UInt64(datas[0].length))
        })
    }
    
    func testRemoveDataExisting() {
        let key = self.name
        let data = UIImagePNGRepresentation(UIImage.imageWithColor(UIColor.redColor()))
        let path = sut.pathForKey(key)
        sut.setData(data, key: key)
        
        sut.removeData(key)
        
        dispatch_sync(sut.cacheQueue, {
            let fileManager = NSFileManager.defaultManager()
            XCTAssertFalse(fileManager.fileExistsAtPath(path))
            XCTAssertEqual(self.sut.size, 0)
        })
    }
    
    func testRemoveDataInexisting() {
        let key = self.name
        let path = sut.pathForKey(key)
        let fileManager = NSFileManager.defaultManager()
        
        // Preconditions
        XCTAssertFalse(fileManager.fileExistsAtPath(path))
        
        sut.removeData(self.name)
    }
    
    func testRemoveAllData_Filled() {
        let key = self.name
        let data = NSData.dataWithLength(12)
        let path = sut.pathForKey(key)
        sut.setData(data, key: key)
        
        sut.removeAllData()
        
        dispatch_sync(sut.cacheQueue, {
            let fileManager = NSFileManager.defaultManager()
            XCTAssertFalse(fileManager.fileExistsAtPath(path))
            XCTAssertEqual(self.sut.size, 0)
        })
    }
    
    func testRemoveAllData_Empty() {
        let key = self.name
        let path = sut.pathForKey(key)
        let fileManager = NSFileManager.defaultManager()
        
        // Preconditions
        XCTAssertFalse(fileManager.fileExistsAtPath(path))
        
        sut.removeData(self.name)
    }
    
    func testPathForKey() {
        let key = self.name
        let expectedPath = sut.cachePath.stringByAppendingPathComponent(key.escapedFilename())

        XCTAssertEqual(sut.pathForKey(key), expectedPath)
    }

    
    // MARK: Helpers

    var dataIndex = 0
    
    func writeDataWithLength(length : Int, directory : String) -> String {
        let data = NSData.dataWithLength(length)
        let path = directory.stringByAppendingPathComponent("\(dataIndex)")
        data.writeToFile(path, atomically: true)
        dataIndex++
        return path
    }

}