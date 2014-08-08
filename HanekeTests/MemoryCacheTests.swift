//
//  MemoryCacheTests.swift
//  Haneke
//
//  Created by Luis Ascorbe on 23/07/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import Foundation
import UIKit
import XCTest
import Haneke

class MemoryCacheTests: XCTestCase {
    
    func testInit() {
        let sut = MemoryCache("test")
        XCTAssertNotNil(sut.memoryWarningObserver)
    }
    
    func testDeinit() {
        weak var sut = MemoryCache("test")
    }
    
    func testSetImage () {
        let sut = MemoryCache("test")
        let image = UIImage()
        let key = "key"
        
        sut.setImage(image, key)
    }
    
    func testFetchImage () {
        let sut = MemoryCache("test")
        let key = "key"
        
        XCTAssert(sut.fetchImage(key) == nil, "MemoryCache is empty")
        
        let image = UIImage()
        sut.setImage(image, key)
        
        XCTAssert(sut.fetchImage(key) != nil, "MemoryCache is not empty")
    }
    
    func testFetchImageWithNilKey () {
        let sut = MemoryCache("test")
        
        XCTAssert(sut.fetchImage(nil) == nil, "nil key should returns nil image")
    }
    
    func testFetchImageEqualImage () {
        let sut = MemoryCache("test")
        
        let image = UIImage.imageWithColor(UIColor.cyanColor(), CGSizeMake(30, 30), true)
        let key = "key"
        
        sut.setImage(image, key)
        
        XCTAssert(image.isEqualPixelByPixel(sut.fetchImage(key)), "Fetched image is equal to the original one.")
    }
    
    func testRemoveImageExisting() {
        let sut = MemoryCache("test")
        let key = "key"
        sut.setImage(UIImage(), key)
        
        sut.removeImage(key)
        
        XCTAssertNil(sut.fetchImage(key))
    }
    
    func testRemoveImageInexisting() {
        let sut = MemoryCache("test")
        
        sut.removeImage("key")
    }
    
    func testOnMemoryWarning() {
        let sut = MemoryCache("test")
        let key = "key"
        sut.setImage(UIImage(), key)
        XCTAssertNotNil(sut.fetchImage(key))
        
        sut.onMemoryWarning()
        
        XCTAssertNil(sut.fetchImage(key))
    }
    
    func testUIApplicationDidReceiveMemoryWarningNotification() {
        let expectation = expectationWithDescription("onMemoryWarning")
        
        class MemoryCacheMock : MemoryCache {
            
            var expectation : XCTestExpectation?
            
            override func onMemoryWarning() {
                super.onMemoryWarning()
                expectation!.fulfill()
            }
        }
        
        let sut = MemoryCacheMock("test")
        sut.expectation = expectation // XCode crashes if we use the original expectation directly
        
        NSNotificationCenter.defaultCenter().postNotificationName(UIApplicationDidReceiveMemoryWarningNotification, object: nil)
        
        waitForExpectationsWithTimeout(0, nil)
    }
}
