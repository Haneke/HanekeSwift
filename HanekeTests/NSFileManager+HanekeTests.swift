//
//  NSFileManager+HanekeTests.swift
//  Haneke
//
//  Created by Hermes Pique on 8/26/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import XCTest

class NSFileManager_HanekeTests: DiskTestCase {
    
    func testEnumerateContentsOfDirectoryAtPathNameAscending() {
        let sut = NSFileManager.defaultManager()
    
        let paths = [self.writeDataWithLength(1), self.writeDataWithLength(2)].sorted(<)
        var URLs : Array<NSURL> = []
        var indexes : Array<Int> = []
        
        sut.enumerateContentsOfDirectoryAtPath(self.directoryPath, orderedByProperty: NSURLNameKey, ascending: true) { (URL : NSURL, index : Int, _) -> Void in
            URLs.append(URL)
            indexes.append(index)
        }
        
        XCTAssertEqual(URLs.count, 2)
        XCTAssertEqual(URLs[0].path!, paths[0])
        XCTAssertEqual(URLs[1].path!, paths[1])
        XCTAssertEqual(indexes[0], 0)
        XCTAssertEqual(indexes[1], 1)
    }
    
}

