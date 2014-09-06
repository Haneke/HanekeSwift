//
//  UIImage+HanekeTests.swift
//  Haneke
//
//  Created by Hermes Pique on 8/10/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import XCTest
import Haneke

class UIImage_HanekeTests: XCTestCase {

    func testHasAlphaTrue() {
        let image = UIImage.imageWithColor(UIColor.redColor(), CGSize(width: 1, height: 1), false)
        XCTAssertTrue(image.hnk_hasAlpha())
    }
    
    func testHasAlphaFalse() {
        let image = UIImage.imageWithColor(UIColor.redColor(), CGSize(width: 1, height: 1), true)
        XCTAssertFalse(image.hnk_hasAlpha())
    }
    
    func testDataPNG() {
        let image = UIImage.imageWithColor(UIColor.redColor(), CGSize(width: 1, height: 1), false)
        let expectedData = UIImagePNGRepresentation(image)
        
        let data = image.hnk_data()
        
        XCTAssertEqual(data!, expectedData)
    }
    
    func testDataJPEG() {
        let image = UIImage.imageWithColor(UIColor.redColor(), CGSize(width: 1, height: 1), true)
        let expectedData = UIImageJPEGRepresentation(image, 1)
        
        let data = image.hnk_data()
        
        XCTAssertEqual(data!, expectedData)
    }
    
    func testDataNil() {
        let image = UIImage()

        XCTAssertNil(image.hnk_data())
    }
    
    func testAspectFillSize() {
        let image = UIImage.imageWithColor(UIColor.redColor(), CGSize(width: 10, height: 1), false)
        let sut: CGSize = image.hnk_aspectFillSize(CGSizeMake(10, 10))
        
        XCTAssertEqual(sut.height, 10)
    }
    
    func testAspectFitSize() {
        let image = UIImage.imageWithColor(UIColor.redColor(), CGSize(width: 10, height: 1), false)
        let sut: CGSize = image.hnk_aspectFitSize(CGSizeMake(20, 20))
        
        XCTAssertEqual(sut.height, 2)
    }
}
