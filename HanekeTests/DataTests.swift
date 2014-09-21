//
//  DataTests.swift
//  Haneke
//
//  Created by Hermes Pique on 9/19/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import UIKit
import XCTest

class ImageDataTests: XCTestCase {

    func testConvertFromData() {
        let image = UIImage.imageGradientFromColor()
        let data = image.hnk_data()

        let result = UIImage.convertFromData(data)

        XCTAssertTrue(image.isEqualPixelByPixel(image))
    }
    
    func testAsData() {
        let image = UIImage.imageGradientFromColor()
        let data = image.hnk_data()
        
        let result = image.asData()
        
        XCTAssertEqual(result, data)
    }
    
}

class StringDataTests: XCTestCase {
    
    func testConvertFromData() {
        let string = self.name
        let data = string.dataUsingEncoding(NSUTF8StringEncoding)!
        
        let result = String.convertFromData(data)
        
        XCTAssertEqual(result!, string)
    }
    
    func testAsData() {
        let string = self.name
        let data = string.dataUsingEncoding(NSUTF8StringEncoding)!
        
        let result = string.asData()
        
        XCTAssertEqual(result, data)
    }
    
}

class DataDataTests: XCTestCase {
    
    func testConvertFromData() {
        let data = NSData.dataWithLength(32)
        
        let result = NSData.convertFromData(data)
        
        XCTAssertEqual(result!, data)
    }
    
    func testAsData() {
        let data = NSData.dataWithLength(32)
        
        let result = data.asData()
        
        XCTAssertEqual(result, data)
    }
    
}
