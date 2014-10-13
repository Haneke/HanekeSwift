//
//  NSHTTPURLResponse+HanekeTests.swift
//  Haneke
//
//  Created by Hermes Pique on 9/15/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import XCTest

class NSHTTPURLResponse_HanekeTests: XCTestCase {

    let URL = NSURL(string: "http://haneke.io")!
    
    func testValidateLengthOfData_unknown() {
        let response = NSHTTPURLResponse(URL: URL, statusCode: 200, HTTPVersion: "HTTP/1.1", headerFields: nil)!
        let data = NSData.dataWithLength(132)
        XCTAssertTrue(response.hnk_validateLengthOfData(data))
    }
    
    func testValidateLengthOfData_Expected() {
        let length = 73
        let response = NSHTTPURLResponse(URL: URL, statusCode: 200, HTTPVersion: "HTTP/1.1", headerFields: ["Content-Length" : String(length)])!
        let data = NSData.dataWithLength(length)
        XCTAssertTrue(response.hnk_validateLengthOfData(data))
    }
    
    func testValidateLengthOfData_LessThanExpected() {
        let length = 73
        let response = NSHTTPURLResponse(URL: URL, statusCode: 200, HTTPVersion: "HTTP/1.1", headerFields: ["Content-Length" : String(length)])!
        let data = NSData.dataWithLength(length - 10)
        XCTAssertFalse(response.hnk_validateLengthOfData(data))
    }
    
    func testValidateLengthOfData_MoreThanExpected() {
        let length = 73
        let response = NSHTTPURLResponse(URL: URL, statusCode: 200, HTTPVersion: "HTTP/1.1", headerFields: ["Content-Length" : String(length)])!
        let data = NSData.dataWithLength(length + 10)
        XCTAssertTrue(response.hnk_validateLengthOfData(data))
    }

}
