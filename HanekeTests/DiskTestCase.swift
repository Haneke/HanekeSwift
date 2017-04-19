//
//  DiskTestCase.swift
//  Haneke
//
//  Created by Hermes Pique on 8/26/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import XCTest

class DiskTestCase : XCTestCase {
 
    lazy var directoryPath: String = {
        let documentsPath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]
        let directoryPath = (documentsPath as NSString).appendingPathComponent(self.name!)
        return directoryPath
    }()
    
    override func setUp() {
        super.setUp()
        try! FileManager.default.createDirectory(atPath: directoryPath, withIntermediateDirectories: true, attributes: nil)
    }
    
    override func tearDown() {
        try! FileManager.default.removeItem(atPath: directoryPath)
        super.tearDown()
    }
    
    var dataIndex = 0
    
    func writeDataWithLength(_ length : Int) -> String {
        let data = Data.dataWithLength(length)
        return self.writeData(data)
    }
    
    func writeData(_ data : Data) -> String {
        let path = self.uniquePath()
        try? data.write(to: URL(fileURLWithPath: path), options: [.atomic])
        return path
    }
    
    func uniquePath() -> String {
        let path = (self.directoryPath as NSString).appendingPathComponent("\(dataIndex)")
        dataIndex += 1
        return path
    }
    
}
