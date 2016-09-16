//
//  NSFileManager+HanekeTests.swift
//  Haneke
//
//  Created by Hermes Pique on 8/26/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import XCTest
@testable import Haneke

class NSFileManager_HanekeTests: DiskTestCase {
    
    func testEnumerateContentsOfDirectoryAtPathEmpty() {
        let sut = FileManager.default
        
        sut.enumerateContentsOfDirectoryAtPath(self.directoryPath, orderedByProperty: URLResourceKey.nameKey, ascending: true) { (URL : Foundation.URL, index : Int, _) -> Void in
            XCTFail()
        }
    }
    
    func testEnumerateContentsOfDirectoryAtPathStop() {
        let sut = FileManager.default
        [self.writeDataWithLength(1), self.writeDataWithLength(2)]
        var count = 0
        
        sut.enumerateContentsOfDirectoryAtPath(self.directoryPath, orderedByProperty: URLResourceKey.nameKey, ascending: true) { (_ : URL, index : Int, stop : inout Bool) -> Void in
            count += 1
            stop = true
        }
        
        XCTAssertEqual(count, 1)
    }
    
    func testEnumerateContentsOfDirectoryAtPathNameAscending() {
        let sut = FileManager.default
    
        let paths = [self.writeDataWithLength(1), self.writeDataWithLength(2)].sorted(by: <)
        var resultPaths : [String] = []
        var indexes : [Int] = []
        
        sut.enumerateContentsOfDirectoryAtPath(self.directoryPath, orderedByProperty: URLResourceKey.nameKey, ascending: true) { (URL : Foundation.URL, index : Int, _) -> Void in
            resultPaths.append(URL.path!)
            indexes.append(index)
        }
        
        XCTAssertEqual(resultPaths.count, 2)
        XCTAssertEqual(resultPaths, paths)
        XCTAssertEqual(indexes[0], 0)
        XCTAssertEqual(indexes[1], 1)
    }
    
    func testEnumerateContentsOfDirectoryAtPathNameDescending() {
        let sut = FileManager.default
        
        let paths = [self.writeDataWithLength(1), self.writeDataWithLength(2)].sorted(by: >)
        var resultPaths : [String] = []
        var indexes : [Int] = []
        
        sut.enumerateContentsOfDirectoryAtPath(self.directoryPath, orderedByProperty: URLResourceKey.nameKey, ascending: false) { (URL : Foundation.URL, index : Int, _) -> Void in
            resultPaths.append(URL.path!)
            indexes.append(index)
        }
        
        XCTAssertEqual(resultPaths.count, 2)
        XCTAssertEqual(resultPaths, paths)
        XCTAssertEqual(indexes[0], 0)
        XCTAssertEqual(indexes[1], 1)
    }
    
    func testEnumerateContentsOfDirectoryAtPathFileSizeAscending() {
        let sut = FileManager.default
        
        let paths = [self.writeDataWithLength(1), self.writeDataWithLength(2)]
        var resultPaths : [String] = []
        
        sut.enumerateContentsOfDirectoryAtPath(self.directoryPath, orderedByProperty: URLResourceKey.fileSizeKey, ascending: true) { (URL : Foundation.URL, index : Int, _) -> Void in
            resultPaths.append(URL.path!)
        }
        
        XCTAssertEqual(resultPaths.count, 2)
        XCTAssertEqual(resultPaths, paths)
    }
    
    func testEnumerateContentsOfDirectoryAtPathFileSizeDescending() {
        let sut = FileManager.default
        
        let paths : [String] = [self.writeDataWithLength(1), self.writeDataWithLength(2)].reversed()
        var resultPaths : [String] = []
        
        sut.enumerateContentsOfDirectoryAtPath(self.directoryPath, orderedByProperty: URLResourceKey.fileSizeKey, ascending: false) { (URL : Foundation.URL, index : Int, _) -> Void in
            resultPaths.append(URL.path!)
        }
        
        XCTAssertEqual(resultPaths.count, 2)
        XCTAssertEqual(resultPaths, paths)
    }
    
    func testEnumerateContentsOfDirectoryAtPathModificationDateAscending() {
        let sut = FileManager.default
        
        let paths = [self.writeDataWithLength(1), self.writeDataWithLength(2)]
        try! sut.setAttributes([FileAttributeKey.modificationDate : Date.distantPast], ofItemAtPath: paths[0])
        
        var resultPaths : [String] = []
        
        sut.enumerateContentsOfDirectoryAtPath(self.directoryPath, orderedByProperty: URLResourceKey.contentModificationDateKey, ascending: true) { (URL : Foundation.URL, index : Int, _) -> Void in
            resultPaths.append(URL.path!)
        }
        
        XCTAssertEqual(resultPaths.count, 2)
        XCTAssertEqual(resultPaths, paths)
    }
    
    func testEnumerateContentsOfDirectoryAtPathModificationDateDescending() {
        let sut = FileManager.default
        
        let paths = [self.writeDataWithLength(1), self.writeDataWithLength(2)]
        try! sut.setAttributes([FileAttributeKey.modificationDate : Date.distantPast], ofItemAtPath: paths[1])
        var resultPaths : [String] = []
        
        sut.enumerateContentsOfDirectoryAtPath(self.directoryPath, orderedByProperty: URLResourceKey.contentModificationDateKey, ascending: false) { (URL : Foundation.URL, index : Int, _) -> Void in
            resultPaths.append(URL.path!)
        }
        
        XCTAssertEqual(resultPaths.count, 2)
        XCTAssertEqual(resultPaths, paths)
    }
    
}

