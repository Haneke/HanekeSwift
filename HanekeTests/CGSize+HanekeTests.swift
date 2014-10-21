//
//  CGSize+HanekeTests.swift
//  Haneke
//
//  Created by Oriol Blanc Gimeno on 9/12/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import UIKit
import XCTest

class CGSize_HanekeTests: XCTestCase {
    
    func testAspectFillSize() {
        let image = UIImage.imageWithColor(UIColor.redColor(), CGSize(width: 10, height: 1), false)
        let sut: CGSize = image.size.hnk_aspectFillSize(CGSizeMake(10, 10))
        
        XCTAssertTrue(sut.height == 10)
    }
    
    func testAspectFitSize() {
        let image = UIImage.imageWithColor(UIColor.redColor(), CGSize(width: 10, height: 1), false)
        let sut: CGSize = image.size.hnk_aspectFitSize(CGSizeMake(20, 20))
        
        XCTAssertTrue(sut.height == 2)
    }
}