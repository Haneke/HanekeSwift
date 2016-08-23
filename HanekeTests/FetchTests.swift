//
//  FetchTests.swift
//  Haneke
//
//  Created by Hermes Pique on 9/28/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import Foundation
import XCTest
@testable import Haneke

class FetchTests : XCTestCase {
    
    var sut : Fetch<String>!
    
    override func setUp() {
        super.setUp()
        sut = Fetch<String>()
    }

    func testHasSucceded_True() {
        sut.succeed(self.name!)
        
        XCTAssertTrue(sut.hasSucceeded)
    }
    
    func testHasSucceded_False() {
        XCTAssertFalse(sut.hasSucceeded)
    }
    
    func testHasSucceded_AfterFail_False() {
        sut.fail()
        
        XCTAssertFalse(sut.hasSucceeded)
    }
    
    func testHasFailed_True() {
        sut.fail()
        
        XCTAssertTrue(sut.hasFailed)
    }
    
    func testHasFailed_False() {
        XCTAssertFalse(sut.hasFailed)
    }
    
    func testHasSucceded_AfterSucceed_False() {
        sut.succeed(self.name!)
        
        XCTAssertFalse(sut.hasFailed)
    }
    
    func testSucceed() {
        sut.succeed(self.name!)
    }

    func testSucceed_AfterOnSuccess() {
        let value = self.name!
        let expectation = self.expectation(description: value)
        sut.onSuccess {
            XCTAssertEqual($0, value)
            expectation.fulfill()
        }
        
        sut.succeed(value)
        
        self.waitForExpectations(timeout: 0, handler: nil)
    }
    
    func testFail() {
        sut.fail()
    }
    
    func testFail_AfterOnFailure() {
        let error = Error(domain: self.name!, code: 10, userInfo: nil)
        let expectation = self.expectation(description: self.name!)
        sut.onFailure {
            XCTAssertEqual($0!, error)
            expectation.fulfill()
        }
        
        sut.fail(error)
        
        self.waitForExpectations(timeout: 0, handler: nil)
    }
    
    func testOnSuccess() {
        sut.onSuccess { _ in
            XCTFail("unexpected success")
        }
    }
    
    func testOnSuccess_AfterSucceed() {
        let value = self.name!
        sut.succeed(value)
        let expectation = self.expectation(description: value)
        
        sut.onSuccess {
            XCTAssertEqual($0, value)
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 0, handler: nil)
    }
    
    func testOnFailure() {
        sut.onFailure { _ in
            XCTFail("unexpected failure")
        }
    }
    
    func testOnFailure_AfterFail() {
        let error = Error(domain: self.name!, code: 10, userInfo: nil)
        sut.fail(error)
        let expectation = self.expectation(description: self.name!)
        
        sut.onFailure {
            XCTAssertEqual($0!, error)
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 0, handler: nil)
    }
    
}
