//
//  NSURLResponse+HanekeTests.swift
//  Haneke
//
//  Created by Hermes Pique on 9/15/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import XCTest

class NSURLResponse_HanekeTests: XCTestCase {

    let httpURL = NSURL(string: "http://haneke.io")!
    let fileURL = NSURL(string: "file:///image.png")!
    
    func testValidateLengthOfData_unknown() {
        let response = NSHTTPURLResponse(URL: httpURL, statusCode: 200, HTTPVersion: "HTTP/1.1", headerFields: nil)!
        let data = NSData.dataWithLength(132)
        XCTAssertTrue(response.hnk_validateLengthOfData(data))
    }
    
    func testValidateLengthOfData_Expected() {
        let length = 73
        let response = NSHTTPURLResponse(URL: httpURL, statusCode: 200, HTTPVersion: "HTTP/1.1", headerFields: ["Content-Length": String(length)])!
        let data = NSData.dataWithLength(length)
        XCTAssertTrue(response.hnk_validateLengthOfData(data))
    }
    
    func testValidateLengthOfData_LessThanExpected() {
        let length = 73
        let response = NSHTTPURLResponse(URL: httpURL, statusCode: 200, HTTPVersion: "HTTP/1.1", headerFields: ["Content-Length": String(length)])!
        let data = NSData.dataWithLength(length - 10)
        XCTAssertFalse(response.hnk_validateLengthOfData(data))
    }
    
    func testValidateLengthOfData_MoreThanExpected() {
        let length = 73
        let response = NSHTTPURLResponse(URL: httpURL, statusCode: 200, HTTPVersion: "HTTP/1.1", headerFields: ["Content-Length": String(length)])!
        let data = NSData.dataWithLength(length + 10)
        XCTAssertTrue(response.hnk_validateLengthOfData(data))
    }
    
    func testShouldValidateWhenLengthIsUndeterminedForNonHTTPResponse() {
        let response = NSURLResponse(URL: fileURL, MIMEType: "image/png", expectedContentLength: -1, textEncodingName: nil)
        let data = NSData.dataWithLength(73)
        XCTAssertTrue(response.hnk_validateLengthOfData(data))
    }
    
    func testShouldValidateWhenLengthIsCorrectForNonHTTPResponse() {
        let length = 73
        let response = NSURLResponse(URL: fileURL, MIMEType: "image/png", expectedContentLength: length, textEncodingName: nil)
        let data = NSData.dataWithLength(length)
        XCTAssertTrue(response.hnk_validateLengthOfData(data))
    }
    
    func testShouldNotValidateWhenLengthIsLessThanExpectedForNonHTTPResponse() {
        let length = 73
        let response = NSURLResponse(URL: fileURL, MIMEType: "image/png", expectedContentLength: length, textEncodingName: nil)
        let data = NSData.dataWithLength(length - 10)
        XCTAssertFalse(response.hnk_validateLengthOfData(data))
    }
    
    func testShouldStillValidateWhenLengthIsMoreThanExpectedForNonHTTPResponse() {
        let length = 73
        let response = NSURLResponse(URL: fileURL, MIMEType: "image/png", expectedContentLength: length, textEncodingName: nil)
        let data = NSData.dataWithLength(length + 10)
        XCTAssertTrue(response.hnk_validateLengthOfData(data))
    }
}
