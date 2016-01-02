//
//  NSURLResponse+HanekeTests.swift
//  Haneke
//
//  Created by Hermes Pique on 9/15/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import XCTest
@testable import Haneke

class NSURLResponse_HanekeTests: XCTestCase {

    let httpURL = NSURL(string: "http://haneke.io")!
    let fileURL = NSURL(string: "file:///image.png")!
    
    func testValidateLengthOfData_NSHTTPURLResponse_Unknown() {
        let response = NSHTTPURLResponse(URL: httpURL, statusCode: 200, HTTPVersion: "HTTP/1.1", headerFields: nil)!
        let data = NSData.dataWithLength(132)
        XCTAssertTrue(response.hnk_validateLengthOfData(data))
    }
    
    func testValidateLengthOfData_NSHTTPURLResponse_Expected() {
        let length = 73
        let response = NSHTTPURLResponse(URL: httpURL, statusCode: 200, HTTPVersion: "HTTP/1.1", headerFields: ["Content-Length": String(length)])!
        let data = NSData.dataWithLength(length)
        XCTAssertTrue(response.hnk_validateLengthOfData(data))
    }
    
    func testValidateLengthOfData_NSHTTPURLResponse_LessThanExpected() {
        let length = 73
        let response = NSHTTPURLResponse(URL: httpURL, statusCode: 200, HTTPVersion: "HTTP/1.1", headerFields: ["Content-Length": String(length)])!
        let data = NSData.dataWithLength(length - 10)
        XCTAssertFalse(response.hnk_validateLengthOfData(data))
    }
    
    func testValidateLengthOfData_NSHTTPURLResponse_MoreThanExpected() {
        let length = 73
        let response = NSHTTPURLResponse(URL: httpURL, statusCode: 200, HTTPVersion: "HTTP/1.1", headerFields: ["Content-Length": String(length)])!
        let data = NSData.dataWithLength(length + 10)
        XCTAssertTrue(response.hnk_validateLengthOfData(data))
    }
    
    func testValidateLengthOfData_NSURLResponse_Unknown() {
        let response = NSURLResponse(URL: fileURL, MIMEType: "image/png", expectedContentLength: -1, textEncodingName: nil)
        let data = NSData.dataWithLength(73)
        XCTAssertTrue(response.hnk_validateLengthOfData(data))
    }
    
    func testValidateLengthOfData_NSURLResponse_Expected() {
        let length = 73
        let response = NSURLResponse(URL: fileURL, MIMEType: "image/png", expectedContentLength: length, textEncodingName: nil)
        let data = NSData.dataWithLength(length)
        XCTAssertTrue(response.hnk_validateLengthOfData(data))
    }
    
    func testValidateLengthOfData_NSURLResponse_LessThanExpected() {
        let length = 73
        let response = NSURLResponse(URL: fileURL, MIMEType: "image/png", expectedContentLength: length, textEncodingName: nil)
        let data = NSData.dataWithLength(length - 10)
        XCTAssertFalse(response.hnk_validateLengthOfData(data))
    }
    
    func testValidateLengthOfData_NSURLResponse_MoreThanExpected() {
        let length = 73
        let response = NSURLResponse(URL: fileURL, MIMEType: "image/png", expectedContentLength: length, textEncodingName: nil)
        let data = NSData.dataWithLength(length + 10)
        XCTAssertTrue(response.hnk_validateLengthOfData(data))
    }
}
