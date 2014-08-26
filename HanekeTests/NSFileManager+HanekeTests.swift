//
//  NSFileManager+HanekeTests.swift
//  Haneke
//
//  Created by Hermes Pique on 8/26/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import XCTest

class NSFileManager_HanekeTests: DiskTestCase {
    
    func testEnumerateContentsOfDirectoryAtPathEmpty() {
        let sut = NSFileManager.defaultManager()
        
        sut.enumerateContentsOfDirectoryAtPath(self.directoryPath, orderedByProperty: NSURLNameKey, ascending: true) { (URL : NSURL, index : Int, _) -> Void in
            XCTFail()
        }
    }
    
    func testEnumerateContentsOfDirectoryAtPathStop() {
        let sut = NSFileManager.defaultManager()
        
        let paths = [self.writeDataWithLength(1), self.writeDataWithLength(2)]
        var count = 0
        
        sut.enumerateContentsOfDirectoryAtPath(self.directoryPath, orderedByProperty: NSURLNameKey, ascending: true) { (_ : NSURL, index : Int, inout stop : Bool) -> Void in
            count++
            stop = true
        }
        
        XCTAssertEqual(count, 1)
    }
    
    func testEnumerateContentsOfDirectoryAtPathNameAscending() {
        let sut = NSFileManager.defaultManager()
    
        let paths = [self.writeDataWithLength(1), self.writeDataWithLength(2)].sorted(<)
        var resultPaths : Array<String> = []
        var indexes : Array<Int> = []
        
        sut.enumerateContentsOfDirectoryAtPath(self.directoryPath, orderedByProperty: NSURLNameKey, ascending: true) { (URL : NSURL, index : Int, _) -> Void in
            resultPaths.append(URL.path!)
            indexes.append(index)
        }
        
        XCTAssertEqual(resultPaths.count, 2)
        XCTAssertEqual(resultPaths, paths)
        XCTAssertEqual(indexes[0], 0)
        XCTAssertEqual(indexes[1], 1)
    }
    
    func testEnumerateContentsOfDirectoryAtPathNameDescending() {
        let sut = NSFileManager.defaultManager()
        
        let paths = [self.writeDataWithLength(1), self.writeDataWithLength(2)].sorted(>)
        var resultPaths : Array<String> = []
        var indexes : Array<Int> = []
        
        sut.enumerateContentsOfDirectoryAtPath(self.directoryPath, orderedByProperty: NSURLNameKey, ascending: false) { (URL : NSURL, index : Int, _) -> Void in
            resultPaths.append(URL.path!)
            indexes.append(index)
        }
        
        XCTAssertEqual(resultPaths.count, 2)
        XCTAssertEqual(resultPaths, paths)
        XCTAssertEqual(indexes[0], 0)
        XCTAssertEqual(indexes[1], 1)
    }
    
    func testEnumerateContentsOfDirectoryAtPathFileSizeAscending() {
        let sut = NSFileManager.defaultManager()
        
        let paths = [self.writeDataWithLength(1), self.writeDataWithLength(2)]
        var resultPaths : Array<String> = []
        
        sut.enumerateContentsOfDirectoryAtPath(self.directoryPath, orderedByProperty: NSURLFileSizeKey, ascending: true) { (URL : NSURL, index : Int, _) -> Void in
            resultPaths.append(URL.path!)
        }
        
        XCTAssertEqual(resultPaths.count, 2)
        XCTAssertEqual(resultPaths, paths)
    }
    
    func testEnumerateContentsOfDirectoryAtPathFileSizeDescending() {
        let sut = NSFileManager.defaultManager()
        
        let paths = [self.writeDataWithLength(1), self.writeDataWithLength(2)].reverse()
        var resultPaths : Array<String> = []
        
        sut.enumerateContentsOfDirectoryAtPath(self.directoryPath, orderedByProperty: NSURLFileSizeKey, ascending: false) { (URL : NSURL, index : Int, _) -> Void in
            resultPaths.append(URL.path!)
        }
        
        XCTAssertEqual(resultPaths.count, 2)
        XCTAssertEqual(resultPaths, paths)
    }
    
    func testEnumerateContentsOfDirectoryAtPathModificationDateAscending() {
        let sut = NSFileManager.defaultManager()
        
        let paths = [self.writeDataWithLength(1), self.writeDataWithLength(2)]
        sut.setAttributes([NSFileModificationDate : NSDate.distantPast()], ofItemAtPath: paths[0], error: nil)
        
        var resultPaths : Array<String> = []
        
        sut.enumerateContentsOfDirectoryAtPath(self.directoryPath, orderedByProperty: NSURLContentModificationDateKey, ascending: true) { (URL : NSURL, index : Int, _) -> Void in
            resultPaths.append(URL.path!)
        }
        
        XCTAssertEqual(resultPaths.count, 2)
        XCTAssertEqual(resultPaths, paths)
    }
    
    func testEnumerateContentsOfDirectoryAtPathModificationDateDescending() {
        let sut = NSFileManager.defaultManager()
        
        let paths = [self.writeDataWithLength(1), self.writeDataWithLength(2)]
        sut.setAttributes([NSFileModificationDate : NSDate.distantPast()], ofItemAtPath: paths[1], error: nil)
        var resultPaths : Array<String> = []
        
        sut.enumerateContentsOfDirectoryAtPath(self.directoryPath, orderedByProperty: NSURLContentModificationDateKey, ascending: false) { (URL : NSURL, index : Int, _) -> Void in
            resultPaths.append(URL.path!)
        }
        
        XCTAssertEqual(resultPaths.count, 2)
        XCTAssertEqual(resultPaths, paths)
    }
    
}

