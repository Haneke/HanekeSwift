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
        let name = "test"
        let sut = DiskCache(name)
        XCTAssertEqual(name, sut.name)
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
        let key = "key"
        let path = sut.pathForKey(key)
        
        sut.setData(data, key: key)
        
        let expectation = self.expectationWithDescription(self.name)
        
        dispatch_async(sut.cacheQueue, {
            let fileManager = NSFileManager.defaultManager()
            XCTAssertTrue(fileManager.fileExistsAtPath(path))
            let resultData = NSData(contentsOfFile:path)
            XCTAssertEqual(resultData, data)
            expectation.fulfill()
        })
        
        self.waitForExpectationsWithTimeout(0.5, nil)
    }
    
    func testSetDataNil() {
        let sut = self.sut!
        let key = self.name
        let path = sut.pathForKey(key)
        
        sut.setData({ return nil }(), key: key)
        
        let expectation = self.expectationWithDescription(self.name)
        
        dispatch_async(sut.cacheQueue, {
            let fileManager = NSFileManager.defaultManager()
            XCTAssertFalse(fileManager.fileExistsAtPath(path))
            expectation.fulfill()
        })
        
        self.waitForExpectationsWithTimeout(0.5, nil)
    }
    
    func testRemoveDataExisting() {
        let sut = self.sut!
        let key = self.name
        let data = UIImagePNGRepresentation(UIImage.imageWithColor(UIColor.redColor()));
        let path = sut.pathForKey(key)
        sut.setData(data, key: key)
        
        sut.removeData(key)
        
        let expectation = self.expectationWithDescription("data removed")
        dispatch_async(sut.cacheQueue, {
            let fileManager = NSFileManager.defaultManager()
            XCTAssertFalse(fileManager.fileExistsAtPath(path))
            expectation.fulfill()
        })
        self.waitForExpectationsWithTimeout(0.5, nil)
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

}