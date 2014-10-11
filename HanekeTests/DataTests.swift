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

class JSONDataTests: XCTestCase {
    
    func testConvertFromData_WithArrayData() {
        let json = [self.name]
        let data = NSJSONSerialization.dataWithJSONObject(json, options: NSJSONWritingOptions.allZeros, error: nil)!
        
        let result = JSON.convertFromData(data)!
        
        switch result {
        case .Dictionary(_):
            XCTFail("expected array")
        case .Array(let object):
            let resultData = NSJSONSerialization.dataWithJSONObject(object, options: NSJSONWritingOptions.allZeros, error: nil)!
            XCTAssertEqual(resultData, data)
        }
    }
    
    func testConvertFromData_WithDictionaryData() {
        let json = ["test": self.name]
        let data = NSJSONSerialization.dataWithJSONObject(json, options: NSJSONWritingOptions.allZeros, error: nil)!
        
        let result = JSON.convertFromData(data)!
        
        switch result {
        case .Dictionary(let object):
            let resultData = NSJSONSerialization.dataWithJSONObject(object, options: NSJSONWritingOptions.allZeros, error: nil)!
        case .Array(_):
            XCTFail("expected dictionary")
        }
    }
    
    func testConvertFromData_WithInvalidData() {
        let data = NSData.dataWithLength(100)

        let result = JSON.convertFromData(data)
        
        XCTAssertTrue(result == nil)
    }
    
    func testAsData_Array() {
        let object = [self.name]
        let json = JSON.Array(object)
        
        let result = json.asData()
        
        let data = NSJSONSerialization.dataWithJSONObject(object, options: NSJSONWritingOptions.allZeros, error: nil)!
        XCTAssertEqual(result, data)
    }
    
    func testAsData_Dictionary() {
        let object = ["test": self.name]
        let json = JSON.Dictionary(object)
        
        let result = json.asData()
        
        let data = NSJSONSerialization.dataWithJSONObject(object, options: NSJSONWritingOptions.allZeros, error: nil)!
        XCTAssertEqual(result, data)
    }
    
    func testAsData_InvalidJSON() {
        let object = ["test": UIImage.imageWithColor(UIColor.redColor())]
        let json = JSON.Dictionary(object)
        
        // TODO: Swift doesn't support XCAssertThrows yet.
        // See: http://stackoverflow.com/questions/25529625/testing-assertion-in-swift
        // XCAssertThrows(json.asData())
    }
    
    func testArray_Array() {
        let object = [self.name]
        let json = JSON.Array(object)
        
        let result = json.array
        
        XCTAssertNotNil(result)
    }
    
    func testArray_Dictionary() {
        let object = ["test": self.name]
        let json = JSON.Dictionary(object)
        
        let result = json.array
        
        XCTAssertNil(result)
    }
    
    func testDictionary_Array() {
        let object = [self.name]
        let json = JSON.Array(object)
        
        let result = json.dictionary
        
        XCTAssertNil(result)
    }
    
    func testDictionary_Dictionary() {
        let object = ["test": self.name]
        let json = JSON.Dictionary(object)
        
        let result = json.dictionary
        
        XCTAssertNotNil(result)
    }
    
}
