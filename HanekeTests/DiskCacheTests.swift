//
//  DiskCacheTests.swift
//  Haneke
//
//  Created by Hermes Pique on 8/10/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import UIKit
import XCTest
@testable import Haneke

class DiskCacheTests: XCTestCase {

    var sut : DiskCache!
    
    lazy var diskCachePath: String = {
        let diskCachePath =  (DiskCache.basePath() as NSString).appendingPathComponent(self.name!)
        try! FileManager.default.createDirectory(atPath: diskCachePath, withIntermediateDirectories: true, attributes: nil)
        return diskCachePath
    }()
    
    override func setUp() {
        super.setUp()
        sut = DiskCache(path:diskCachePath)
    }
    
    override func tearDown() {
        var completed = false
        sut.removeAllData() {
            completed = true
        }
        self.wait(5) {
            return completed
        }
        try! FileManager.default.removeItem(atPath: diskCachePath)
        super.tearDown()
    }
    
    func testBasePath() {
        let cachesPath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.cachesDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)[0]
        let basePath = (cachesPath as NSString).appendingPathComponent(HanekeGlobals.Domain)
        XCTAssertEqual(DiskCache.basePath(), basePath)
    }
    
    func testInit() {
        let sut = DiskCache(path:diskCachePath)
        
        XCTAssertEqual(sut.path, diskCachePath)
        XCTAssertEqual(Int(sut.size), 0)
    }
    
    func testInitWithOneFile() {
        let path = diskCachePath
        let expectedSize = 8
        self.writeDataWithLength(expectedSize, directory: path)
        
        let sut = DiskCache(path: path)
        
        sut.cacheQueue.sync {
            XCTAssertEqual(sut.size, UInt64(expectedSize))
        }
    }
    
    func testInitWithTwoFiles() {
        let directory = diskCachePath
        let lengths = [4, 7]
        self.writeDataWithLength(lengths[0], directory: directory)
        self.writeDataWithLength(lengths[1], directory: directory)
        
        let sut = DiskCache(path: directory)
        
        sut.cacheQueue.sync {
            XCTAssertEqual(sut.size, UInt64(lengths.reduce(0, +)))
        }
    }
    
    func testInitCapacityZeroOneExistingFile() {
        let directory = diskCachePath
        let path = self.writeDataWithLength(1, directory: directory)
        
        let sut = DiskCache(path: directory, capacity : 0)
        
        sut.cacheQueue.sync {
            XCTAssertEqual(sut.size, 0)
            XCTAssertFalse(FileManager.default.fileExists(atPath: path))
        }
    }
    
    func testInitCapacityZeroTwoExistingFiles() {
        let directory = diskCachePath
        let path1 = self.writeDataWithLength(1, directory: directory)
        let path2 = self.writeDataWithLength(2, directory: directory)
        
        let sut = DiskCache(path: directory, capacity : 0)
        
        sut.cacheQueue.sync(execute: {
            XCTAssertEqual(Int(sut.size), 0)
            XCTAssertFalse(FileManager.default.fileExists(atPath: path1))
            XCTAssertFalse(FileManager.default.fileExists(atPath: path2))
        })
    }
    
    func testInitLeastRecentlyUsedExistingFileDeleted() {
        let directory = diskCachePath
        let path1 = self.writeDataWithLength(1, directory: directory)
        let path2 = self.writeDataWithLength(1, directory: directory)
        try! FileManager.default.setAttributes([FileAttributeKey.modificationDate : Date.distantPast], ofItemAtPath: path2)
        
        let sut = DiskCache(path: directory, capacity : 1)
        
        sut.cacheQueue.sync(execute: {
            XCTAssertEqual(Int(sut.size), 1)
            XCTAssertTrue(FileManager.default.fileExists(atPath: path1))
            XCTAssertFalse(FileManager.default.fileExists(atPath: path2))
        })
    }
    
    func testCacheQueue() {
        let expectedLabel = HanekeGlobals.Domain + "." + (diskCachePath as NSString).lastPathComponent

        let label = String(validatingUTF8: sut.cacheQueue.label)!

        XCTAssertEqual(label, expectedLabel)
    }
    
    func testSetCapacity() {
        sut.setData(Data.dataWithLength(1), key: self.name!)
        
        sut.capacity = 0
        
        sut.cacheQueue.sync(execute: {
            XCTAssertEqual(Int(self.sut.size), 0)
        })        
    }
    
    func testSetData() {
        let data = UIImagePNGRepresentation(UIImage.imageWithColor(UIColor.red))!
        let key = self.name!
        let path = sut.pathForKey(key)
        
        sut.setData(data, key: key)
        
        sut.cacheQueue.sync {
            let fileManager = FileManager.default
            XCTAssertTrue(fileManager.fileExists(atPath: path))
            let resultData = try! Data(contentsOf: URL(fileURLWithPath: path))
            XCTAssertEqual(resultData, data)
            XCTAssertEqual(self.sut.size, UInt64(data.count))
        }
    }
    
    func testSetData_WithKeyIncludingSpecialCharacters() {
        let sut = self.sut!
        let data = UIImagePNGRepresentation(UIImage.imageWithColor(UIColor.red))!
        let key = "http://haneke.io"
        let path = sut.pathForKey(key)
        
        sut.setData(data, key: key)
        
        sut.cacheQueue.sync {
            let fileManager = FileManager.default
            XCTAssertTrue(fileManager.fileExists(atPath: path))
            let resultData = try! Data(contentsOf: URL(fileURLWithPath: path))
            XCTAssertEqual(resultData, data)
            XCTAssertEqual(sut.size, UInt64(data.count))
        }
    }
    
    func testSetData_WithLongKey() {
        let sut = self.sut!
        let data = Data.dataWithLength(10)
        let key = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aliquam pretium id nibh a pulvinar. Integer id ex in tellus egestas placerat. Praesent ultricies libero ligula, et convallis ligula imperdiet eu. Sed gravida, turpis sed vulputate feugiat, metus nisl scelerisque diam, ac aliquet metus nisi rutrum ipsum. Nulla vulputate pretium dolor, a pellentesque nulla. Nunc pellentesque tortor porttitor, sollicitudin leo in, sollicitudin ligula. Cras malesuada orci at neque interdum elementum. Integer sed sagittis diam. Mauris non elit sed augue consequat feugiat. Nullam volutpat tortor eget tempus pretium. Sed pharetra sem vitae diam hendrerit, sit amet dapibus arcu interdum. Fusce egestas quam libero, ut efficitur turpis placerat eu. Sed velit sapien, aliquam sit amet ultricies a, bibendum ac nibh. Maecenas imperdiet, quam quis tincidunt sollicitudin, nunc tellus ornare ipsum, nec rhoncus nunc nisi a lacus."
        let path = sut.pathForKey(key)
        
        sut.setData(data, key: key)
        
        sut.cacheQueue.sync {
            let fileManager = FileManager.default
            XCTAssertTrue(fileManager.fileExists(atPath: path))
            let resultData = try! Data(contentsOf: URL(fileURLWithPath: path))
            XCTAssertEqual(resultData, data)
            XCTAssertEqual(sut.size, UInt64(data.count))
        }
    }
    
    func testSetDataSizeGreaterThanZero() {
        let lengths = [5, 14]
        let keys = ["1", "2"]
        sut.setData(Data.dataWithLength(lengths[0]), key: keys[0])
        
        sut.setData(Data.dataWithLength(lengths[1]), key: keys[1])
        
        sut.cacheQueue.sync {
            XCTAssertEqual(self.sut.size, UInt64(lengths.reduce(0, +)))
        }
    }
    
    func testSetDataReplace() {
        let originalData = Data.dataWithLength(5)
        let data = Data.dataWithLength(14)
        let key = self.name!
        let path = sut.pathForKey(key)
        sut.setData(originalData, key: key)
        
        sut.setData(data, key: key)
        
        sut.cacheQueue.sync {
            let fileManager = FileManager.default
            XCTAssertTrue(fileManager.fileExists(atPath: path))
            let resultData = try! Data(contentsOf: URL(fileURLWithPath: path))
            XCTAssertEqual(resultData, data)
            XCTAssertEqual(self.sut.size, UInt64(data.count))
        }
    }
    
    func testSetDataNil() {
        let key = self.name!
        let path = sut.pathForKey(key)
        
        sut.setData({ return nil }(), key: key)
        
        sut.cacheQueue.sync(execute: {
            let fileManager = FileManager.default
            XCTAssertFalse(fileManager.fileExists(atPath: path))
            XCTAssertEqual(Int(self.sut.size), 0)
        })
    }
    
    func testSetDataControlCapacity() {
        let sut = DiskCache(path: diskCachePath, capacity:0)
        let key = self.name!
        let path = sut.pathForKey(key)
        
        sut.setData(Data.dataWithLength(1), key: key)
        
        sut.cacheQueue.sync(execute: {
            let fileManager = FileManager.default
            XCTAssertFalse(fileManager.fileExists(atPath: path))
            XCTAssertEqual(Int(sut.size), 0)
        })
    }
    
    func testFetchData() {
        let data = Data.dataWithLength(14)
        let key = self.name!
        sut.setData(data, key : key)
        
        let expectation = self.expectation(description: key)
        
        sut.fetchData(key: key, success: {
            expectation.fulfill()
            XCTAssertEqual($0, data)
        })

        sut.cacheQueue.sync {}
        self.waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testFetchData_Inexisting() {
        let key = self.name!
        let expectation = self.expectation(description: key)
        
        sut.fetchData(key: key, failure : { error in
            XCTAssertEqual(error!.code, NSFileReadNoSuchFileError)
            expectation.fulfill()
        }) { data in
            XCTFail("Expected failure")
            expectation.fulfill()
        }

        sut.cacheQueue.sync {}
        self.waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testFetchData_Inexisting_NilFailureBlock() {
        let key = self.name!
        
        sut.fetchData(key: key, success: { _ in
            XCTFail("Expected failure")
        })
        
        sut.cacheQueue.sync {}
    }
    
    func testFetchData_UpdateAccessDate() {
        let now = Date()
        let data = Data.dataWithLength(19)
        let key = self.name!
        sut.setData(data, key : key)
        let path = sut.pathForKey(key)
        let fileManager = FileManager.default
        sut.cacheQueue.sync(execute: {
            try! fileManager.setAttributes([FileAttributeKey.modificationDate : Date.distantPast], ofItemAtPath: path)
        })
        let expectation = self.expectation(description: key)
        
        // Preconditions
        sut.cacheQueue.sync {
            let attributes = try! fileManager.attributesOfItem(atPath: path)
            let accessDate = attributes[FileAttributeKey.modificationDate] as! Date
            XCTAssertTrue((accessDate as NSDate).laterDate(now) == now)
        }
        
        sut.fetchData(key: key, success: {
            expectation.fulfill()
            XCTAssertEqual($0, data)
        })

        sut.cacheQueue.sync {}
        self.waitForExpectations(timeout: 1, handler: nil)

        let attributes = try! fileManager.attributesOfItem(atPath: path)
        let accessDate = attributes[FileAttributeKey.modificationDate] as! Date
        let interval = accessDate.timeIntervalSince(now)
        XCTAssertEqualWithAccuracy(interval, 0, accuracy: 1)
    }

    func testUpdateAccessDateFileInDisk() {
        let now = Date()
        let data = Data.dataWithLength(10)
        let key = self.name!
        sut.setData(data, key : key)
        let path = sut.pathForKey(key)
        let fileManager = FileManager.default
        sut.cacheQueue.sync {
            try! fileManager.setAttributes([FileAttributeKey.modificationDate : Date.distantPast], ofItemAtPath: path)
        }
        
        // Preconditions
        sut.cacheQueue.sync {
            let attributes = try! fileManager.attributesOfItem(atPath: path)
            let accessDate = attributes[FileAttributeKey.modificationDate] as! Date
            XCTAssertTrue((accessDate as NSDate).laterDate(now) == now)
        }
        
        sut.updateAccessDate(data, key: key)
        
        sut.cacheQueue.sync {
            let attributes = try! fileManager.attributesOfItem(atPath: path)
            let accessDate = attributes[FileAttributeKey.modificationDate] as! Date
            let now = Date()
            let interval = accessDate.timeIntervalSince(now)
            XCTAssertEqualWithAccuracy(interval, 0, accuracy: 1)
        }
    }
    
    func testUpdateAccessDateFileNotInDisk() {
        let image = UIImage.imageWithColor(UIColor.red)
        let key = self.name!
        let path = sut.pathForKey(key)
        let fileManager = FileManager.default
        
        // Preconditions
        sut.cacheQueue.sync {
            XCTAssertFalse(fileManager.fileExists(atPath: path))
        }
        
        sut.updateAccessDate(image.hnk_data(), key: key)
        
        sut.cacheQueue.sync {
            XCTAssertTrue(fileManager.fileExists(atPath: path))
        }
    }
    
    func testRemoveDataTwoKeys() {
        let keys = ["1", "2"]
        let datas = [Data.dataWithLength(5), Data.dataWithLength(7)]
        sut.setData(datas[0], key: keys[0])
        sut.setData(datas[1], key: keys[1])

        sut.removeData(keys[1])
        
        sut.cacheQueue.sync {
            let fileManager = FileManager.default
            let path = self.sut.pathForKey(keys[1])
            XCTAssertFalse(fileManager.fileExists(atPath: path))
            XCTAssertEqual(self.sut.size, UInt64(datas[0].count))
        }
    }
    
    func testRemoveDataExisting() {
        let key = self.name!
        let data = UIImagePNGRepresentation(UIImage.imageWithColor(UIColor.red))
        let path = sut.pathForKey(key)
        sut.setData(data, key: key)
        
        sut.removeData(key)
        
        sut.cacheQueue.sync {
            let fileManager = FileManager.default
            XCTAssertFalse(fileManager.fileExists(atPath: path))
            XCTAssertEqual(Int(self.sut.size), 0)
        }
    }
    
    func testRemoveDataInexisting() {
        let key = self.name!
        let path = sut.pathForKey(key)
        let fileManager = FileManager.default
        
        // Preconditions
        XCTAssertFalse(fileManager.fileExists(atPath: path))
        
        sut.removeData(key)
    }
    
    func testRemoveAllData_Filled() {
        let key = self.name!
        let data = Data.dataWithLength(12)
        let path = sut.pathForKey(key)
        sut.setData(data, key: key)
        
        sut.removeAllData()
        
        sut.cacheQueue.sync {
            let fileManager = FileManager.default
            XCTAssertFalse(fileManager.fileExists(atPath: path))
            XCTAssertEqual(Int(self.sut.size), 0)
        }
    }

    func testRemoveAllData_Completion_Filled() {
        let key = self.name!
        let data = Data.dataWithLength(12)
        sut.setData(data, key: key)
        let expectation = self.expectation(description: key)

        var completed = false
        sut.removeAllData {
            completed = true
            expectation.fulfill()
        }

        XCTAssertFalse(completed)
        self.waitForExpectations(timeout: 1, handler: nil)
    }

    func testRemoveAllData_Empty() {
        let key = self.name!
        let path = sut.pathForKey(key)
        let fileManager = FileManager.default
        
        // Preconditions
        XCTAssertFalse(fileManager.fileExists(atPath: path))
        
        sut.removeAllData()
    }
    
    func testRemoveAllData_ThenSetData() {
        let key = self.name!
        let path = sut.pathForKey(key)
        let data = Data.dataWithLength(12)
        
        sut.removeAllData()

        sut.setData(data, key: key)
        sut.cacheQueue.sync {
            let fileManager = FileManager.default
            XCTAssertTrue(fileManager.fileExists(atPath: path))
        }
    }
    
    func testPathForKey_WithShortKey() {
        let key = "test"
        let expectedPath = (sut.path as NSString).appendingPathComponent(key.escapedFilename())

        XCTAssertEqual(sut.pathForKey(key), expectedPath)
    }
    
    func testPathForKey_WithShortKeyWithSpecialCharacters() {
        let key = "http://haneke.io"
        let expectedPath = (sut.path as NSString).appendingPathComponent(key.escapedFilename())
        
        XCTAssertEqual(sut.pathForKey(key), expectedPath)
    }
    
    func testPathForKey_WithLongKey() {
        let key = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aliquam pretium id nibh a pulvinar. Integer id ex in tellus egestas placerat. Praesent ultricies libero ligula, et convallis ligula imperdiet eu. Sed gravida, turpis sed vulputate feugiat, metus nisl scelerisque diam, ac aliquet metus nisi rutrum ipsum. Nulla vulputate pretium dolor, a pellentesque nulla. Nunc pellentesque tortor porttitor, sollicitudin leo in, sollicitudin ligula. Cras malesuada orci at neque interdum elementum. Integer sed sagittis diam. Mauris non elit sed augue consequat feugiat. Nullam volutpat tortor eget tempus pretium. Sed pharetra sem vitae diam hendrerit, sit amet dapibus arcu interdum. Fusce egestas quam libero, ut efficitur turpis placerat eu. Sed velit sapien, aliquam sit amet ultricies a, bibendum ac nibh. Maecenas imperdiet, quam quis tincidunt sollicitudin, nunc tellus ornare ipsum, nec rhoncus nunc nisi a lacus."
        let expectedPath = (sut.path as NSString).appendingPathComponent(key.MD5Filename())
        
        XCTAssertEqual(sut.pathForKey(key), expectedPath)
    }
    
    // MARK: Helpers

    var dataIndex = 0
    
    func writeDataWithLength(_ length : Int, directory: String) -> String {
        let data = Data.dataWithLength(length)
        let path = (directory as NSString).appendingPathComponent("\(dataIndex)")
        try? data.write(to: URL(fileURLWithPath: path), options: [.atomic])
        dataIndex += 1
        return path
    }

}
