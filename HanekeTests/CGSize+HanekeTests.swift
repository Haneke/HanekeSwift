//
//  CGSize+HanekeTests.swift
//  Haneke
//
//  Created by Oriol Blanc Gimeno on 9/12/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import XCTest
import Haneke

class CGSize_HanekeTests: XCTestCase {
    
    func testResizeImageScaleNone() {
        
        let originalImage = UIImage.imageWithColor(UIColor.redColor(), CGSize(width: 1, height: 1), false)
        let sut: Format = Format(self.name, diskCapacity: 0, size: CGSizeMake(30, 5), scaleMode: .None)
        let resizedImage = sut.resizedImageFromImage(originalImage)
        
        XCTAssertEqual(originalImage.size.width, resizedImage.size.width)
        XCTAssertEqual(originalImage.size.height, resizedImage.size.height)
        XCTAssertNotEqual(resizedImage.size.width, 30)
        XCTAssertNotEqual(resizedImage.size.height, 5)
    }
    
    func testResizeImageScaleFill() {
        
        let originalImage = UIImage.imageWithColor(UIColor.redColor(), CGSize(width: 1, height: 1), false)
        let sut: Format = Format(self.name, diskCapacity: 0, size: CGSizeMake(30, 5), scaleMode : .Fill)
        let resizedImage = sut.resizedImageFromImage(originalImage)
        
        XCTAssertNotEqual(originalImage.size.width, resizedImage.size.width)
        XCTAssertNotEqual(originalImage.size.height, resizedImage.size.height)
        XCTAssertEqual(resizedImage.size.width, 30)
        XCTAssertEqual(resizedImage.size.height, 5)
    }
    
    func testResizeImageScaleAspectFill() {
        
        let originalImage = UIImage.imageWithColor(UIColor.redColor(), CGSize(width: 1, height: 1), false)
        let sut: Format = Format(self.name, diskCapacity: 0, size: CGSizeMake(30, 5), scaleMode: .AspectFill)
        let resizedImage = sut.resizedImageFromImage(originalImage)
        
        XCTAssertNotEqual(originalImage.size.width, resizedImage.size.width)
        XCTAssertNotEqual(originalImage.size.height, resizedImage.size.height)
        XCTAssertEqual(resizedImage.size.width, 30)
        XCTAssertEqual(resizedImage.size.height, 30)
    }
    
    func testResizeImageScaleAspectFit() {
        
        let originalImage = UIImage.imageWithColor(UIColor.redColor(), CGSize(width: 1, height: 1), false)
        let sut: Format = Format(self.name, diskCapacity: 0, size: CGSizeMake(30, 5), scaleMode: .AspectFit)
        let resizedImage = sut.resizedImageFromImage(originalImage)
        
        XCTAssertNotEqual(originalImage.size.width, resizedImage.size.width)
        XCTAssertNotEqual(originalImage.size.height, resizedImage.size.height)
        XCTAssertEqual(resizedImage.size.width, 5)
        XCTAssertEqual(resizedImage.size.height, 5)
    }
    
    func testResizeImageScaleAspectFillWithoutUpscaling() {
        
        let originalImage = UIImage.imageWithColor(UIColor.redColor(), CGSize(width: 1, height: 1), false)
        let sut: Format = Format(self.name, diskCapacity: 0, size: CGSizeMake(30, 5), scaleMode: .AspectFill, allowUpscaling: false)
        let resizedImage = sut.resizedImageFromImage(originalImage)
        
        XCTAssertEqual(originalImage.size.width, resizedImage.size.width)
        XCTAssertEqual(originalImage.size.height, resizedImage.size.height)
        XCTAssertEqual(resizedImage.size.width, 1)
        XCTAssertEqual(resizedImage.size.height, 1)
    }
}