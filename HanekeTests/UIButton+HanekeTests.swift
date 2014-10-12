//
//  UIButton+HanekeTests.swift
//  Haneke
//
//  Created by Joan Romano on 10/6/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import UIKit
import XCTest

class UIButton_HanekeTests: XCTestCase {
    
    lazy var directoryPath : String = {
        let documentsPath = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0] as String
        let directoryPath = documentsPath.stringByAppendingPathComponent(self.name)
        return directoryPath
        }()
    
    var sut : UIButton!
    
    override func setUp() {
        super.setUp()
        sut = UIButton(frame: CGRectMake(0, 0, 100, 20))
        NSFileManager.defaultManager().createDirectoryAtPath(directoryPath, withIntermediateDirectories: true, attributes: nil, error: nil)
    }
    
    override func tearDown() {
        sut.hnk_cancelSetBackgroundImage()
        OHHTTPStubs.removeAllStubs()
        
        let backgroundFormat = sut.hnk_backgroundImageFormat
        Haneke.sharedImageCache.remove(key: self.name, formatName: backgroundFormat.name)
        NSFileManager.defaultManager().removeItemAtPath(directoryPath, error: nil)
        
        super.tearDown()
    }
    
    // MARK: backgroundImageFormat

    func testBackgroundImageFormat_Default() {
        let formatSize = sut.contentRectForBounds(sut.bounds).size
        let format = sut.hnk_backgroundImageFormat
        let resizer = ImageResizer(size: sut.bounds.size, scaleMode: .Fill, allowUpscaling: true, compressionQuality: Haneke.UIKit.DefaultFormat.CompressionQuality)
        let image = UIImage.imageWithColor(UIColor.redColor())
        
        XCTAssertEqual(format.diskCapacity, Haneke.UIKit.DefaultFormat.DiskCapacity)
        XCTAssertTrue(Haneke.sharedImageCache.formats[format.name] != nil) // Can't use XCTAssertNotNil because it expects AnyObject
        let result = format.apply(image)
        let expected = resizer.resizeImage(image)
        XCTAssertTrue(result.isEqualPixelByPixel(expected))
    }
    
    // MARK: setbackgroundImageFromFetcher
    
    func testSetBackgroundImageFromFetcher_MemoryMiss_UIControlStateSelected() {
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let key = self.name
        let fetcher = SimpleFetcher<UIImage>(key: key, thing: image)
        
        sut.hnk_setBackgroundImageFromFetcher(fetcher, state: .Selected)
        
        XCTAssertNil(sut.backgroundImageForState(.Selected))
        XCTAssertTrue(sut.hnk_backgroundImageFetcher === fetcher)
    }
    
    func testSetBackgroundImageFromFetcher_MemoryHit_UIControlStateNormal() {
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let key = self.name
        let fetcher = SimpleFetcher<UIImage>(key: key, thing: image)
        let cache = Haneke.sharedImageCache
        let format = sut.hnk_backgroundImageFormat
        cache.set(value: image, key: key, formatName: format.name)
        
        sut.hnk_setBackgroundImageFromFetcher(fetcher, state: .Normal)
        
        XCTAssertTrue(sut.backgroundImageForState(.Normal)!.isEqualPixelByPixel(image))
        XCTAssertTrue(sut.hnk_backgroundImageFetcher == nil)
    }
    
    func testSetBackgroundImageFromFetcherSuccessFailure_MemoryHit_UIControlStateNormal() {
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let key = self.name
        let fetcher = SimpleFetcher<UIImage>(key: key, thing: image)
        let cache = Haneke.sharedImageCache
        let format = sut.hnk_backgroundImageFormat
        cache.set(value: image, key: key, formatName: format.name)
        
        sut.hnk_setBackgroundImageFromFetcher(fetcher, state: .Normal, failure: {error in
            XCTFail("")
            }){result in
                XCTAssertTrue(result.isEqualPixelByPixel(image))
        }
    }
    
    // MARK: cancelSetBackgroundImage
    
    func testCancelSetBackgroundImage() {
        sut.hnk_cancelSetBackgroundImage()
        
        XCTAssertTrue(sut.hnk_backgroundImageFetcher == nil)
    }
   
}
