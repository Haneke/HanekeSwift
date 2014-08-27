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
    }
    
}

