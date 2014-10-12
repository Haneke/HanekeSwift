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
    
    var sut : UIButton!
    
    override func setUp() {
        super.setUp()
        sut = UIButton(frame: CGRectMake(0, 0, 100, 20))
    }
    
    override func tearDown() {
        sut.hnk_cancelSetBackgroundImage()
        OHHTTPStubs.removeAllStubs()
        
        Haneke.sharedImageCache.removeAll()
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
    
    // MARK: setBackgroundImage
    
    func testBackgroundSetImage_MemoryMiss_UIControlStateNormal() {
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let key = self.name
        
        sut.hnk_setBackgroundImage(image, key: key, state: .Normal)
        
        XCTAssertNil(sut.backgroundImageForState(.Normal))
        XCTAssertEqual(sut.hnk_backgroundImageFetcher.key, key)
    }
    
    func testBackgroundImage_MemoryHit_UIControlStateSelected() {
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let key = self.name
        let cache = Haneke.sharedImageCache
        let format = sut.hnk_backgroundImageFormat
        cache.set(value: image, key: key, formatName: format.name)
        
        sut.hnk_setBackgroundImage(image, key: key, state: .Selected)
        
        XCTAssertTrue(sut.backgroundImageForState(.Selected)!.isEqualPixelByPixel(image))
        XCTAssertTrue(sut.hnk_backgroundImageFetcher == nil)
    }
    
    func testBackgroundImage_UsingPlaceholder_MemoryMiss_UIControlStateDisabled() {
        let placeholder = UIImage.imageWithColor(UIColor.yellowColor())
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let key = self.name
        
        sut.hnk_setBackgroundImage(image, key: key, state: .Disabled, placeholder: placeholder)
        
        XCTAssertEqual(sut.backgroundImageForState(.Disabled)!, placeholder)
        XCTAssertEqual(sut.hnk_backgroundImageFetcher.key, key)
    }
    
    func testBackgroundImage_UsingPlaceholder_MemoryHit_UIControlStateNormal() {
        let placeholder = UIImage.imageWithColor(UIColor.yellowColor())
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let key = self.name
        let cache = Haneke.sharedImageCache
        let format = sut.hnk_backgroundImageFormat
        cache.set(value: image, key: key, formatName: format.name)
        
        sut.hnk_setBackgroundImage(image, key: key, state: .Normal, placeholder: placeholder)
        
        XCTAssertTrue(sut.backgroundImageForState(.Normal)!.isEqualPixelByPixel(image))
        XCTAssertTrue(sut.hnk_backgroundImageFetcher == nil)
    }

    // MARK: setBackgroundImageFromURL

    func testSetBackgroundImageFromURL_MemoryMiss_UIControlStateSelected() {
        let URL = NSURL(string: "http://haneke.io")
        let fetcher = NetworkFetcher<UIImage>(URL: URL)
        
        sut.hnk_setBackgroundImageFromURL(URL, state: .Selected)
        
        XCTAssertNil(sut.backgroundImageForState(.Selected))
        XCTAssertEqual(sut.hnk_backgroundImageFetcher.key, fetcher.key)
    }
    
    func testSetBackgroundImageFromURL_MemoryHit_UIControlStateNormal() {
        let image = UIImage.imageWithColor(UIColor.orangeColor())
        let URL = NSURL(string: "http://haneke.io")
        let fetcher = NetworkFetcher<UIImage>(URL: URL)
        let cache = Haneke.sharedImageCache
        let format = sut.hnk_backgroundImageFormat
        cache.set(value: image, key: fetcher.key, formatName: format.name)
        
        sut.hnk_setBackgroundImageFromURL(URL, state: .Normal)
        
        XCTAssertTrue(sut.backgroundImageForState(.Normal)!.isEqualPixelByPixel(image))
        XCTAssertTrue(sut.hnk_backgroundImageFetcher == nil)
    }
    
    func testSetBackgroundImageFromURLSuccessFailure_MemoryHit_UIControlStateSelected() {
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let URL = NSURL(string: "http://haneke.io")
        let fetcher = NetworkFetcher<UIImage>(URL: URL)
        let cache = Haneke.sharedImageCache
        let format = sut.hnk_backgroundImageFormat
        cache.set(value: image, key: fetcher.key, formatName: format.name)
        
        sut.hnk_setBackgroundImageFromURL(URL, state: .Selected, failure: {error in
            XCTFail("")
            }){result in
                XCTAssertTrue(result.isEqualPixelByPixel(image))
        }
    }

    func testSetBackgroundImageFromURL_Failure_UIControlStateNormal() {
        OHHTTPStubs.stubRequestsPassingTest({ _ in
            return true
            }, withStubResponse: { _ in
                let data = NSData.dataWithLength(100)
                return OHHTTPStubsResponse(data: data, statusCode: 404, headers:nil)
        })
        let URL = NSURL(string: "http://haneke.io")
        let fetcher = NetworkFetcher<UIImage>(URL: URL)
        let expectation = self.expectationWithDescription(self.name)
        
        sut.hnk_setBackgroundImageFromURL(URL, state: .Normal, failure:{error in
            XCTAssertEqual(error!.domain, Haneke.Domain)
            expectation.fulfill()
        })
        
        XCTAssertNil(sut.backgroundImageForState(.Normal))
        XCTAssertEqual(sut.hnk_backgroundImageFetcher.key, fetcher.key)
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    // MARK: setBackgroundImageFromFetcher
    
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
