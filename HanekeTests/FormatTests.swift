//
//  FormatTests.swift
//  Haneke
//
//  Created by Hermes Pique on 8/27/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import UIKit
import XCTest
@testable import Haneke

class FormatTests: XCTestCase {

    func testDefaultInit() {
        let name = self.name!
        let sut = Format<UIImage>(name: name)
        
        XCTAssertEqual(sut.name, name)
        XCTAssertEqual(sut.diskCapacity, UINT64_MAX)
        XCTAssertTrue(sut.transform == nil)
    }
    
    func testIsIdentity_WithoutTransform_ExpectTrue() {
        let sut = Format<UIImage>(name: self.name!)
        
        XCTAssertTrue(sut.isIdentity)
    }
    
    func testIsIdentity_WithTransform_ExpectFalse() {
        let sut = Format<UIImage>(name: self.name!, transform: { return $0 })
        
        XCTAssertFalse(sut.isIdentity)
    }
    
    func testResizeImageScaleNone() {
        
        let originalImage = UIImage.imageWithColor(UIColor.red, false, CGSize(width: 1, height: 1))
        let sut = ImageResizer(size: CGSize(width: 30, height: 5), scaleMode: .None)
        let resizedImage = sut.resizeImage(originalImage)
        
        XCTAssertEqual(originalImage.size.width, resizedImage.size.width)
        XCTAssertEqual(originalImage.size.height, resizedImage.size.height)
        XCTAssertNotEqual(Float(resizedImage.size.width), Float(30))
        XCTAssertNotEqual(Float(resizedImage.size.height), Float(5))
    }
    
    func testResizeImageScaleFill() {
        
        let originalImage = UIImage.imageWithColor(UIColor.red, false, CGSize(width: 1, height: 1))
        let sut = ImageResizer(size: CGSize(width: 30, height: 5), scaleMode : .Fill)
        let resizedImage = sut.resizeImage(originalImage)
        
        XCTAssertNotEqual(originalImage.size.width, resizedImage.size.width)
        XCTAssertNotEqual(originalImage.size.height, resizedImage.size.height)
        XCTAssertEqual(Float(resizedImage.size.width), Float(30))
        XCTAssertEqual(Float(resizedImage.size.height), Float(5))
    }
    
    func testResizeImageScaleAspectFill() {
        
        let originalImage = UIImage.imageWithColor(UIColor.red, false, CGSize(width: 1, height: 1))
        let sut = ImageResizer(size: CGSize(width: 30, height: 5), scaleMode: .AspectFill)
        let resizedImage = sut.resizeImage(originalImage)
        
        XCTAssertNotEqual(originalImage.size.width, resizedImage.size.width)
        XCTAssertNotEqual(originalImage.size.height, resizedImage.size.height)
        XCTAssertEqual(Float(resizedImage.size.width), Float(30))
        XCTAssertEqual(Float(resizedImage.size.height), Float(30))
    }
    
    func testResizeImageScaleAspectFit() {
        
        let originalImage = UIImage.imageWithColor(UIColor.red, false, CGSize(width: 1, height: 1))
        let sut = ImageResizer(size: CGSize(width: 30, height: 5), scaleMode: .AspectFit)
        let resizedImage = sut.resizeImage(originalImage)
        
        XCTAssertNotEqual(originalImage.size.width, resizedImage.size.width)
        XCTAssertNotEqual(originalImage.size.height, resizedImage.size.height)
        XCTAssertEqual(Float(resizedImage.size.width), Float(5))
        XCTAssertEqual(Float(resizedImage.size.height), Float(5))
    }
    
    func testResizeImageScaleAspectFillWithoutUpscaling() {
        
        let originalImage = UIImage.imageWithColor(UIColor.red, false, CGSize(width: 1, height: 1))
        let sut = ImageResizer(size: CGSize(width: 30, height: 5), scaleMode: .AspectFill, allowUpscaling: false)
        let resizedImage = sut.resizeImage(originalImage)
        
        XCTAssertEqual(originalImage.size.width, resizedImage.size.width)
        XCTAssertEqual(originalImage.size.height, resizedImage.size.height)
        XCTAssertEqual(Float(resizedImage.size.width), Float(1))
        XCTAssertEqual(Float(resizedImage.size.height), Float(1))
    }
}

