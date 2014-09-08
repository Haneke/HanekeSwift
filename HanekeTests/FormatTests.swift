//
//  FormatTests.swift
//  Haneke
//
//  Created by Hermes Pique on 8/27/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import XCTest
import Haneke

class FormatTests: XCTestCase {

    func testInit() {
        let name = self.name
        let sut = Format(name)
        
        XCTAssertEqual(sut.name, name)
        XCTAssertEqual(sut.diskCapacity, 0)
    }
    
    // TODO: test default format
    func testResizeImage() {

        let image = UIImage.imageWithColor(UIColor.redColor(), CGSize(width: 1, height: 1), false)
        let sut = Format(self.name)
        sut.size = CGSizeMake(30, 5);
        
        
        
        XCTAssertEqual(sut.name, name)
        XCTAssertEqual(sut.diskCapacity, 0)
    }
    
    // TODO: test resize image fill
    
    // TODO: test resize image fit
}

