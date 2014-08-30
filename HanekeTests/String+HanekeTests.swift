//
//  String+HanekeTests.swift
//  Haneke
//
//  Created by Hermes Pique on 8/30/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import XCTest

class String_HanekeTests: XCTestCase {

    func testEscapedFilename() {
        XCTAssertEqual("".escapedFilename(), "")
        XCTAssertEqual(":".escapedFilename(), "%3A")
        XCTAssertEqual("/".escapedFilename(), "%2F")
        XCTAssertEqual(" ".escapedFilename(), " ")
        XCTAssertEqual("\\".escapedFilename(), "\\")
        XCTAssertEqual("test".escapedFilename(), "test")
        XCTAssertEqual("http://haneke.io".escapedFilename(), "http%3A%2F%2Fhaneke.io")
        XCTAssertEqual("/path/to/file".escapedFilename(), "%2Fpath%2Fto%2Ffile")
    }
    
}