//
//  DiskTestCase.swift
//  Haneke
//
//  Created by Hermes Pique on 8/26/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import XCTest

class DiskTestCase : XCTestCase {
 
    lazy var directoryPath : String = {
        var directoryPath = NSHomeDirectory()
        directoryPath = directoryPath.stringByAppendingPathComponent(_stdlib_getTypeName(self))
        return directoryPath
    }()
    
    override func setUp() {
        super.setUp()
        NSFileManager.defaultManager().createDirectoryAtPath(directoryPath, withIntermediateDirectories: true, attributes: nil, error: nil)
    }
    
    override func tearDown() {
        NSFileManager.defaultManager().removeItemAtPath(directoryPath, error: nil)
        super.tearDown()
    }
    
    var dataIndex = 0
    
    func writeDataWithLength(length : Int) -> String {
        let data = NSData.dataWithLength(length)
        return self.writeData(data)
    }
    
    func writeData(data : NSData) -> String {
        let path = self.directoryPath.stringByAppendingPathComponent("\(dataIndex)")
        data.writeToFile(path, atomically: true)
        dataIndex++
        return path
    }
    
}
