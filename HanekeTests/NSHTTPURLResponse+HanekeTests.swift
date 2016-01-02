//
//  NSHTTPURLResponse+HanekeTests.swift
//  Haneke
//
//  Created by Hermes Pique on 1/2/16.
//  Copyright © 2016 Haneke. All rights reserved.
//

import XCTest
@testable import Haneke

func responseWithStatusCode(statusCode : Int) -> NSHTTPURLResponse {
    return NSHTTPURLResponse(URL: NSURL(string: "http://haneke.io")!, statusCode: statusCode, HTTPVersion: "HTTP/1.1", headerFields: nil)!
}

class NSHTTPURLResponse_HanekeTests: XCTestCase {

    func testIsValidStatusCode() {
        XCTAssertTrue(responseWithStatusCode(200).hnk_isValidStatusCode())
        XCTAssertTrue(responseWithStatusCode(201).hnk_isValidStatusCode())
        XCTAssertFalse(responseWithStatusCode(404).hnk_isValidStatusCode())
    }

}