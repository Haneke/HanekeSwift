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
    
    func testSetImage () {
        let sut = MemoryCache()
        let image = UIImage()
        let key = "key"
        
        sut.setImage(image, key)
    }
    
    func testFetchImage () {
        let sut = MemoryCache()
        let key = "key"
        
        XCTAssert(sut.fetchImage(key) == nil, "MemoryCache is empty")
        
        let image = UIImage()
        sut.setImage(image, key)
        
        XCTAssert(sut.fetchImage(key) != nil, "MemoryCache is not empty")
    }
    
    func testFetchImageWithNilKey () {
        let sut = MemoryCache()
        
        XCTAssert(sut.fetchImage(nil) == nil, "nil key should returns nil image")
    }
    
    func testFetchImageEqualImage () {
        let sut = MemoryCache()
        
        let image = UIImage.imageWithColor(UIColor.cyanColor(), CGSizeMake(30, 30), true)
        let key = "key"
        
        sut.setImage(image, key)
        
        XCTAssert(image.isEqualPixelByPixel(sut.fetchImage(key)), "Fetched image is equal to the original one.")
    }
}
