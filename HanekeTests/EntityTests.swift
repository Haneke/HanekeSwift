//
//  EntityTests.swift
//  Haneke
//
//  Created by Hermes Pique on 9/10/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import XCTest
import Haneke

class EntityTests: XCTestCase {
    
    func testSimpleEntityInit() {
        let key = self.name
        let image = UIImage.imageWithColor(UIColor.greenColor())
        
        let entity = SimpleEntity(key: key, image: image)

        XCTAssertEqual(entity.key, key)
        XCTAssertEqual(entity.image, image)
    }
    
    func testSimpleEntityFetch() {
        let key = self.name
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let entity = SimpleEntity(key: key, image: image)
        let expectation = self.expectationWithDescription(self.name)
        
        entity.fetchImageWithSuccess(success: {
            XCTAssertEqual($0, image)
            expectation.fulfill()
        }, failure: { _ in
            XCTFail("expected success")
        })
        
        self.waitForExpectationsWithTimeout(0, handler: nil)
    }
    
}
