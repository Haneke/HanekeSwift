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

    let httpURL = URL(string: "http://haneke.io")!
    let fileURL = URL(string: "file:///image.png")!
    
    func testValidateLengthOfData_NSHTTPURLResponse_Unknown() {
        let response = HTTPURLResponse(url: httpURL, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: nil)!
        let data = Data.dataWithLength(132)
        XCTAssertTrue(response.hnk_validateLengthOfData(data))
    }
    
    func testValidateLengthOfData_NSHTTPURLResponse_Expected() {
        let length = 73
        let response = HTTPURLResponse(url: httpURL, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Content-Length": String(length)])!
        let data = Data.dataWithLength(length)
        XCTAssertTrue(response.hnk_validateLengthOfData(data))
    }
    
    func testValidateLengthOfData_NSHTTPURLResponse_LessThanExpected() {
        let length = 73
        let response = HTTPURLResponse(url: httpURL, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Content-Length": String(length)])!
        let data = Data.dataWithLength(length - 10)
        XCTAssertFalse(response.hnk_validateLengthOfData(data))
    }
    
    func testValidateLengthOfData_NSHTTPURLResponse_MoreThanExpected() {
        let length = 73
        let response = HTTPURLResponse(url: httpURL, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Content-Length": String(length)])!
        let data = Data.dataWithLength(length + 10)
        XCTAssertTrue(response.hnk_validateLengthOfData(data))
    }
    
    func testValidateLengthOfData_NSURLResponse_Unknown() {
        let response = URLResponse(url: fileURL, mimeType: "image/png", expectedContentLength: -1, textEncodingName: nil)
        let data = Data.dataWithLength(73)
        XCTAssertTrue(response.hnk_validateLengthOfData(data))
    }
    
    func testValidateLengthOfData_NSURLResponse_Expected() {
        let length = 73
        let response = URLResponse(url: fileURL, mimeType: "image/png", expectedContentLength: length, textEncodingName: nil)
        let data = Data.dataWithLength(length)
        XCTAssertTrue(response.hnk_validateLengthOfData(data))
    }
    
    func testValidateLengthOfData_NSURLResponse_LessThanExpected() {
        let length = 73
        let response = URLResponse(url: fileURL, mimeType: "image/png", expectedContentLength: length, textEncodingName: nil)
        let data = Data.dataWithLength(length - 10)
        XCTAssertFalse(response.hnk_validateLengthOfData(data))
    }
    
    func testValidateLengthOfData_NSURLResponse_MoreThanExpected() {
        let length = 73
        let response = URLResponse(url: fileURL, mimeType: "image/png", expectedContentLength: length, textEncodingName: nil)
        let data = Data.dataWithLength(length + 10)
        XCTAssertTrue(response.hnk_validateLengthOfData(data))
    }
}
