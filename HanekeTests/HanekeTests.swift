//
//  HanekeTests.swift
//  Haneke
//
//  Created by Hermes Pique on 9/9/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import XCTest
@testable import Haneke

class HanekeTests: XCTestCase {

    func testErrorWithCode() {
        let code = 200
        let description = self.name
        let error = errorWithCode(code, description: description)
        
        XCTAssertEqual(error._domain, HanekeGlobals.Domain)
        XCTAssertEqual(error._code, code)
        XCTAssertEqual(error.localizedDescription, description)
    }
    
    func testSharedImageCache() {
        Shared.imageCache
    }
    
    func testSharedDataCache() {
        Shared.dataCache
    }
    
    func testSharedStringCache() {
        Shared.stringCache
    }
    
    func testSharedJSONCache() {
        Shared.JSONCache
    }
    
}
