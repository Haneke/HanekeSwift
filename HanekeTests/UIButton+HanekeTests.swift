//
//  UIButton+HanekeTests.swift
//  Haneke
//
//  Created by Joan Romano on 10/6/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import UIKit
import XCTest

class UIButton_HanekeTests: XCTestCase {
    
    lazy var directoryPath : String = {
        let documentsPath = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0] as String
        let directoryPath = documentsPath.stringByAppendingPathComponent(self.name)
        return directoryPath
        }()
    
    var sut : UIButton!
    
    override func setUp() {
        super.setUp()
        sut = UIButton(frame: CGRectMake(0, 0, 100, 20))
        NSFileManager.defaultManager().createDirectoryAtPath(directoryPath, withIntermediateDirectories: true, attributes: nil, error: nil)
    }
    
    override func tearDown() {
        sut.hnk_cancelSetBackgroundImage()
        OHHTTPStubs.removeAllStubs()
        
        let backgroundFormat = sut.hnk_backgroundImageFormat
        Haneke.sharedImageCache.remove(key: self.name, formatName: backgroundFormat.name)
        NSFileManager.defaultManager().removeItemAtPath(directoryPath, error: nil)
        
        super.tearDown()
    }
    
    // MARK: backgroundImageFormat

    func testBackgroundImageFormat() {
        let formatSize = sut.contentRectForBounds(sut.bounds).size
        let format = sut.hnk_backgroundImageFormat
        
        XCTAssertTrue(format.diskCapacity == Haneke.UIKit.DefaultFormat.DiskCapacity, "")
    }
    
    func testSetBackgroundImageFormat_Nil() {

    }
   
}
