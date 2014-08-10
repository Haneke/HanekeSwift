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
    }
    
    func testCacheQueue() {
        let sut = self.sut!
        let expectedLabel = HanekeDomain + "." + sut.name

        let label = String.stringWithUTF8String(dispatch_queue_get_label(sut.cacheQueue))!

        XCTAssertEqual(label, expectedLabel)
    }

}