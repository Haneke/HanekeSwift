//
//  NSHTTPURLResponse+HanekeTests.swift
//  Haneke
//
//  Created by Hermes Pique on 1/2/16.
//  Copyright © 2016 Haneke. All rights reserved.
//

import XCTest
@testable import Haneke

func responseWithStatusCode(_ statusCode : Int) -> HTTPURLResponse {
    return HTTPURLResponse(url: URL(string: "http://haneke.io")!, statusCode: statusCode, httpVersion: "HTTP/1.1", headerFields: nil)!
}

class NSHTTPURLResponse_HanekeTests: XCTestCase {

    func testIsValidStatusCode() {
        XCTAssertTrue(responseWithStatusCode(200).hnk_isValidStatusCode())
        XCTAssertTrue(responseWithStatusCode(201).hnk_isValidStatusCode())
        XCTAssertFalse(responseWithStatusCode(404).hnk_isValidStatusCode())
    }

}
