//
//  EntityTests.swift
//  Haneke
//
//  Created by Hermes Pique on 9/10/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import UIKit
import XCTest

class EntityTests: XCTestCase {
    
    func testSimpleEntityInit() {
        let key = self.name
        let image = UIImage.imageWithColor(UIColor.greenColor())
        
        let entity = SimpleEntity<UIImage>(key: key, thing: image)

        XCTAssertEqual(entity.key, key)
        XCTAssertEqual(entity.getThing(), image)
    }
    
    func testSimpleEntityFetch() {
        let key = self.name
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let entity = SimpleEntity<UIImage>(key: key, thing: image)
        let expectation = self.expectationWithDescription(self.name)
        
        entity.fetchWithSuccess(success: {_ in
            // TODO: XCTAssertEqual($0, image)
            expectation.fulfill()
        }, failure: { _ in
            XCTFail("expected success")
        })
        
        self.waitForExpectationsWithTimeout(0, handler: nil)
    }
    
}
