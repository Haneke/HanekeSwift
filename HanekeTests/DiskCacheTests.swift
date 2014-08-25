//
//  DiskCacheTests.swift
//  Haneke
//
//  Created by Hermes Pique on 8/10/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import Foundation
import XCTest
import Haneke

class DiskCacheTests: XCTestCase {

    var sut : DiskCache?
    
    override func setUp() {
        super.setUp()
        sut = DiskCache(self.name)
    }
    
    override func tearDown() {
        let fileManager = NSFileManager.defaultManager()
        fileManager.removeItemAtPath(sut!.cachePath, error:nil)
        super.tearDown()
    }
    
    func testBasePath() {
        let cachesPath = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.CachesDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0] as String
        let basePath = cachesPath.stringByAppendingPathComponent(HanekeDomain)
        XCTAssertEqual(DiskCache.basePath(), basePath)
    }
    
    func testInit() {
        let name = self.name

        let sut = DiskCache(name)
        
        XCTAssertEqual(sut.name, name)
        XCTAssertEqual(sut.size, 0)
    }
    
    func testInitWithOneFile() {
        let name = self.name
        let directory = DiskCache(name).cachePath
        let expectedSize = 8
        self.writeDataWithLength(expectedSize, directory: directory)
        
        let sut = DiskCache(name)
        
        dispatch_sync(sut.cacheQueue, {
            XCTAssertEqual(sut.size, UInt64(expectedSize))
        });
    }
    
    func testInitWithTwoFiles() {
        let name = self.name
        let directory = DiskCache(name).cachePath
        let lengths = [4, 7];
        self.writeDataWithLength(lengths[0], directory: directory)
        self.writeDataWithLength(lengths[1], directory: directory)
        
        let sut = DiskCache(name)
        
        dispatch_sync(sut.cacheQueue, {
            XCTAssertEqual(sut.size, UInt64(lengths.reduce(0, +)))
        });
    }
    
    func testCachePath() {
        let sut = self.sut!
        let cachePath = DiskCache.basePath().stringByAppendingPathComponent(sut.name)
        XCTAssertEqual(sut.cachePath, cachePath)
        
        let fileManager = NSFileManager.defaultManager()
        var isDirectory: ObjCBool = ObjCBool(0)
        XCTAssertTrue(fileManager.fileExistsAtPath(cachePath, isDirectory: &isDirectory))
        XCTAssertTrue(isDirectory)
    }
    
    func testCachePathEmtpyName() {
        let sut = DiskCache("")
        let cachePath = DiskCache.basePath()
        XCTAssertEqual(sut.cachePath, cachePath)
        
        let fileManager = NSFileManager.defaultManager()
        var isDirectory: ObjCBool = ObjCBool(0)
        XCTAssertTrue(fileManager.fileExistsAtPath(cachePath, isDirectory: &isDirectory))
        XCTAssertTrue(isDirectory)
    }
    
    func testCacheQueue() {
        let sut = self.sut!
        let expectedLabel = HanekeDomain + "." + sut.name

        let label = String.stringWithUTF8String(dispatch_queue_get_label(sut.cacheQueue))!

        XCTAssertEqual(label, expectedLabel)
    }
    
    func testSetData() {
        let sut = self.sut!
        let data = UIImagePNGRepresentation(UIImage.imageWithColor(UIColor.redColor()));
        let key = self.name
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
        let sut = self.sut!
        let originalData = NSData.dataWithLength(5)
        let lengths = [5, 14]
        let keys = ["1", "2"]
        sut.setData(NSData.dataWithLength(lengths[0]), key: keys[0])
        
        sut.setData(NSData.dataWithLength(lengths[1]), key: keys[1])
        
        dispatch_sync(sut.cacheQueue, {
            XCTAssertEqual(sut.size, UInt64(lengths.reduce(0, combine: +)))
        })
    }
    
    func testSetDataReplace() {
        let sut = self.sut!
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
            XCTAssertEqual(sut.size, UInt64(data.length))
        })
    }
    
    func testSetDataNil() {
        let sut = self.sut!
        let key = self.name
        let path = sut.pathForKey(key)
        
        sut.setData({ return nil }(), key: key)
        
        dispatch_sync(sut.cacheQueue, {
            let fileManager = NSFileManager.defaultManager()
            XCTAssertFalse(fileManager.fileExistsAtPath(path))
            XCTAssertEqual(sut.size, 0)
        })
    }
    
    func testRemoveDataTwoKeys() {
        let sut = self.sut!
        let keys = ["1", "2"]
        let datas = [NSData.dataWithLength(5), NSData.dataWithLength(7)]
        sut.setData(datas[0], key: keys[0])
        sut.setData(datas[1], key: keys[1])

        sut.removeData(keys[1])
        
        dispatch_sync(sut.cacheQueue, {
            let fileManager = NSFileManager.defaultManager()
            let path = sut.pathForKey(keys[1])
            XCTAssertFalse(fileManager.fileExistsAtPath(path))
            XCTAssertEqual(sut.size, UInt64(datas[0].length))
        })
    }
    
    func testFetchData () {
        let sut = self.sut!
        let key = "key"
        
        XCTAssert(sut.getData(key) == nil, "Disk is empty")
        
        let image = NSData()
        sut.setData(image, key: key)
        
        XCTAssert(sut.getData(key) != nil, "Disk is not empty")
    }
    
    func testFetchDataWithNilKey () {
        let sut = self.sut!
        
        XCTAssert(sut.getData(nil) == nil, "nil key should returns nil data")
    }
    
    func testFetchDataEqualImage () {
        let sut = self.sut!
        
        let data = UIImagePNGRepresentation(UIImage.imageWithColor(UIColor.redColor()));
        let key = "key"
        
        sut.setData(data, key: key)
        
        XCTAssert(data.isEqualToData(sut.getData(key)), "Fetched data is equal to the original one.")
    }
    
    func testRemoveDataExisting() {
        let sut = self.sut!
        let key = self.name
        let data = UIImagePNGRepresentation(UIImage.imageWithColor(UIColor.redColor()));
        let path = sut.pathForKey(key)
        sut.setData(data, key: key)
        
        sut.removeData(key)
        
        dispatch_sync(sut.cacheQueue, {
            let fileManager = NSFileManager.defaultManager()
            XCTAssertFalse(fileManager.fileExistsAtPath(path))
            XCTAssertEqual(sut.size, 0)
        })
    }
    
    func testRemoveDataInexisting() {
        let sut = self.sut!
        let key = self.name
        let path = sut.pathForKey(key)
        let fileManager = NSFileManager.defaultManager()
        
        // Preconditions
        XCTAssertFalse(fileManager.fileExistsAtPath(path))
        
        sut.removeData(self.name)
    }
    
    func testPathForKey() {
        let sut = self.sut!
        let key = self.name
        let expectedPath = sut.cachePath.stringByAppendingPathComponent(key)

        XCTAssertEqual(sut.pathForKey(key), expectedPath)
    }

    
    // MARK: Helpers

    var dataIndex = 0;
    
    func writeDataWithLength(length : Int, directory : String) {
        let data = NSData.dataWithLength(length)
        let path = directory.stringByAppendingPathComponent("\(dataIndex)")
        data.writeToFile(path, atomically: true)
        dataIndex++
    }

}