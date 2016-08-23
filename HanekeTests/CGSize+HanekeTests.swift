//
//  CGSize+HanekeTests.swift
//  Haneke
//
//  Created by Oriol Blanc Gimeno on 9/12/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import UIKit
import XCTest
@testable import Haneke

class CGSize_HanekeTests: XCTestCase {
    
    func testAspectFillSize() {
        let image = UIImage.imageWithColor(UIColor.red, false, CGSize(width: 10, height: 1))
        let sut: CGSize = image.size.hnk_aspectFillSize(CGSize(width: 10, height: 10))
        
        XCTAssertTrue(sut.height == 10)
    }
    
    func testAspectFitSize() {
        let image = UIImage.imageWithColor(UIColor.red, false, CGSize(width: 10, height: 1))
        let sut: CGSize = image.size.hnk_aspectFitSize(CGSize(width: 20, height: 20))
        
        XCTAssertTrue(sut.height == 2)
    }
}
