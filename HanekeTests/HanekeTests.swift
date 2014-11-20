//
//  HanekeTests.swift
//  Haneke
//
//  Created by Hermes Pique on 9/9/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import XCTest

class HanekeTests: XCTestCase {

    func testErrorWithCode() {
        let code = 200
        let description = self.name
        let error = errorWithCode(code, description:description)
        
        XCTAssertEqual(error.domain, HanekeGlobals.Domain)
        XCTAssertEqual(error.code, code)
        XCTAssertEqual(error.localizedDescription, description)
    }
    
    func testSharedImageCache() {
        let cache = Shared.imageCache
    }
    
    func testSharedDataCache() {
        let cache = Shared.dataCache
    }
    
    func testSharedStringCache() {
        let cache = Shared.stringCache
    }
    
    func testSharedJSONCache() {
        let cache = Shared.JSONCache
    }
    
}
