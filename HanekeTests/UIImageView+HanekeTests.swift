//
//  UIImageView+HanekeTests.swift
//  Haneke
//
//  Created by Hermes Pique on 9/17/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import UIKit
import XCTest

class UIImageView_HanekeTests: XCTestCase {

    var sut : UIImageView!
    
    override func setUp() {
        super.setUp()
        sut = UIImageView(frame: CGRectMake(0, 0, 10, 10))
    }
    
    override func tearDown() {
        OHHTTPStubs.removeAllStubs()
        
        let format = sut.hnk_format
        let cache = Haneke.sharedCache
        cache.removeAllImages()
        super.tearDown()
    }
    
    func testScaleMode_ScaleToFill() {
        sut.contentMode = .ScaleToFill
        XCTAssertEqual(sut.hnk_scaleMode, ScaleMode.Fill)
    }
    
    func testScaleMode_ScaleAspectFit() {
        sut.contentMode = .ScaleAspectFit
        XCTAssertEqual(sut.hnk_scaleMode, ScaleMode.AspectFit)
    }
    
    func testScaleMode_ScaleAspectFill() {
        sut.contentMode = .ScaleAspectFill
        XCTAssertEqual(sut.hnk_scaleMode, ScaleMode.AspectFill)
    }
    
    func testScaleMode_Redraw() {
        sut.contentMode = .Redraw
        XCTAssertEqual(sut.hnk_scaleMode, ScaleMode.None)
    }
    
    func testScaleMode_Center() {
        sut.contentMode = .Center
        XCTAssertEqual(sut.hnk_scaleMode, ScaleMode.None)
    }
    
    func testScaleMode_Top() {
        sut.contentMode = .Top
        XCTAssertEqual(sut.hnk_scaleMode, ScaleMode.None)
    }
    
    func testScaleMode_Bottom() {
        sut.contentMode = .Bottom
        XCTAssertEqual(sut.hnk_scaleMode, ScaleMode.None)
    }
    
    func testScaleMode_Left() {
        sut.contentMode = .Left
        XCTAssertEqual(sut.hnk_scaleMode, ScaleMode.None)
    }
    
    func testScaleMode_Right() {
        sut.contentMode = .Right
        XCTAssertEqual(sut.hnk_scaleMode, ScaleMode.None)
    }
    
    func testScaleMode_TopLeft() {
        sut.contentMode = .TopLeft
        XCTAssertEqual(sut.hnk_scaleMode, ScaleMode.None)
    }
    
    func testScaleMode_TopRight() {
        sut.contentMode = .TopRight
        XCTAssertEqual(sut.hnk_scaleMode, ScaleMode.None)
    }
    
    func testScaleMode_BottomLeft() {
        sut.contentMode = .BottomLeft
        XCTAssertEqual(sut.hnk_scaleMode, ScaleMode.None)
    }
    
    func testScaleMode_BottomRight() {
        sut.contentMode = .BottomRight
        XCTAssertEqual(sut.hnk_scaleMode, ScaleMode.None)
    }
    
    func testFormatWithSize() {
        let size = CGSizeMake(10, 20)
        let scaleMode = ScaleMode.Fill
        let cache = Haneke.sharedCache
        
        let format = UIImageView.hnk_formatWithSize(size, scaleMode: scaleMode)
        
        // TODO: Test properly
        // XCTAssertEqual(format.allowUpscaling, true)
        // XCTAssertEqual(format.compressionQuality, Haneke.UIKit.DefaultFormat.CompressionQuality)
        XCTAssertEqual(format.diskCapacity, Haneke.UIKit.DefaultFormat.DiskCapacity)
        // XCTAssertEqual(format.size, size)
        // XCTAssertEqual(format.scaleMode, scaleMode)
        XCTAssertTrue(cache.formats[format.name] != nil) // Can't use XCTAssertNotNil because it expects AnyObject
    }
    
    func testFormatWithSize_Twice() {
        let size = CGSizeMake(10, 20)
        let scaleMode = ScaleMode.Fill
        let cache = Haneke.sharedCache
        let format1 = UIImageView.hnk_formatWithSize(size, scaleMode: scaleMode)
        let image = UIImage.imageWithColor(UIColor.greenColor())
        cache.setImage(image, self.name, formatName: format1.name)
        
        let format2 = UIImageView.hnk_formatWithSize(size, scaleMode: scaleMode)
        
        let (_,memoryCache,_) = cache.formats[format2.name]!
        let resultImage = memoryCache.objectForKey(self.name)! as UIImage
        XCTAssertEqual(resultImage, image)
    }
    
    func testFormat_Default() {
        let cache = Haneke.sharedCache
        
        let format = sut.hnk_format
        
        // TODO: Test properly
        // XCTAssertEqual(format.size, sut.bounds.size)
        // XCTAssertEqual(format.scaleMode, sut.hnk_scaleMode)
        XCTAssertEqual(format.diskCapacity, Haneke.UIKit.DefaultFormat.DiskCapacity)
        // XCTAssertEqual(format.allowUpscaling, true)
        // XCTAssertEqual(format.compressionQuality, Haneke.UIKit.DefaultFormat.CompressionQuality)
        XCTAssertTrue(cache.formats[format.name] != nil) // Can't use XCTAssertNotNil because it expects AnyObject
    }

    // MARK: setImage

    func testSetImage_MemoryMiss() {
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let key = self.name
        
        sut.hnk_setImage(image, key: key)
        
        XCTAssertNil(sut.image)
        XCTAssertEqual(sut.hnk_entity.key, key)
    }
    
    func testSetImage_MemoryHit() {
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let key = self.name
        let cache = Haneke.sharedCache
        let format = sut.hnk_format
        cache.setImage(image, key, formatName: format.name)
        
        sut.hnk_setImage(image, key: key)
        
        XCTAssertTrue(sut.image!.isEqualPixelByPixel(image))
        XCTAssertTrue(sut.hnk_entity == nil)
    }
    
    func testSetImage_ImageSet_MemoryMiss() {
        let previousImage = UIImage.imageWithColor(UIColor.redColor())
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let key = self.name
        sut.image = previousImage
        
        sut.hnk_setImage(image, key: key)
        
        XCTAssertEqual(sut.image!, previousImage)
        XCTAssertEqual(sut.hnk_entity.key, key)
    }
    
    func testSetImage_UsingPlaceholder_MemoryMiss() {
        let placeholder = UIImage.imageWithColor(UIColor.yellowColor())
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let key = self.name
        
        sut.hnk_setImage(image, key: key, placeholder: placeholder)
        
        XCTAssertEqual(sut.image!, placeholder)
        XCTAssertEqual(sut.hnk_entity.key, key)
    }
    
    func testSetImage_UsingPlaceholder_MemoryHit() {
        let placeholder = UIImage.imageWithColor(UIColor.yellowColor())
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let key = self.name
        let cache = Haneke.sharedCache
        let format = sut.hnk_format
        cache.setImage(image, key, formatName: format.name)
        
        sut.hnk_setImage(image, key: key, placeholder: placeholder)
        
        XCTAssertTrue(sut.image!.isEqualPixelByPixel(image))
        XCTAssertTrue(sut.hnk_entity == nil)
    }
    
    func testSetImage_Success() {
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let key = self.name
        sut.contentMode = .Center // No resizing
        let expectation = self.expectationWithDescription(self.name)
        
        sut.hnk_setImage(image, key: key, success:{resultImage in
            XCTAssertTrue(resultImage.isEqualPixelByPixel(image))
            expectation.fulfill()
        })
        
        XCTAssertNil(sut.image)
        XCTAssertEqual(sut.hnk_entity.key, key)
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    // MARK: setImageFromEntity

    func testSetImageFromEntity_MemoryMiss() {
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let key = self.name
        let entity = SimpleEntity(key: key, thing: image)
        
        sut.hnk_setImageFromEntity(entity)

        XCTAssertNil(sut.image)
        XCTAssertEqual(sut.hnk_entity.key, entity.key)
    }
    
    func testSetImageFromEntity_MemoryHit() {
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let key = self.name
        let entity = SimpleEntity(key: key, thing: image)
        let cache = Haneke.sharedCache
        let format = sut.hnk_format
        cache.setImage(image, key, formatName: format.name)
        
        sut.hnk_setImageFromEntity(entity)
        
        XCTAssertTrue(sut.image!.isEqualPixelByPixel(image))
        XCTAssertTrue(sut.hnk_entity == nil)
    }
    
    func testSetImageFromEntity_ImageSet_MemoryMiss() {
        let previousImage = UIImage.imageWithColor(UIColor.redColor())
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let key = self.name
        let entity = SimpleEntity(key: key, thing: image)
        sut.image = previousImage
        
        sut.hnk_setImageFromEntity(entity)
        
        XCTAssertEqual(sut.image!, previousImage)
        XCTAssertEqual(sut.hnk_entity.key, entity.key)
    }

    func testSetImageFromEntity_UsingPlaceholder_MemoryMiss() {
        let placeholder = UIImage.imageWithColor(UIColor.yellowColor())
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let key = self.name
        let entity = SimpleEntity(key: key, thing: image)
        
        sut.hnk_setImageFromEntity(entity, placeholder:placeholder)
        
        XCTAssertEqual(sut.image!, placeholder)
        XCTAssertEqual(sut.hnk_entity.key, entity.key)
    }
    
    func testSetImageFromEntity_UsingPlaceholder_MemoryHit() {
        let placeholder = UIImage.imageWithColor(UIColor.yellowColor())
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let key = self.name
        let entity = SimpleEntity(key: key, thing: image)
        let cache = Haneke.sharedCache
        let format = sut.hnk_format
        cache.setImage(image, key, formatName: format.name)
        
        sut.hnk_setImageFromEntity(entity, placeholder:placeholder)
        
        XCTAssertTrue(sut.image!.isEqualPixelByPixel(image))
        XCTAssertTrue(sut.hnk_entity == nil)
    }
    
    func testSetImageFromEntity_Success() {
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let key = self.name
        let entity = SimpleEntity(key: key, thing: image)
        sut.contentMode = .Center // No resizing
        let expectation = self.expectationWithDescription(self.name)
        
        sut.hnk_setImageFromEntity(entity, success:{resultImage in
            XCTAssertTrue(resultImage.isEqualPixelByPixel(image))
            expectation.fulfill()
        })
        
        XCTAssertNil(sut.image)
        XCTAssertEqual(sut.hnk_entity.key, entity.key)
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testSetImageFromEntity_Failure() {
        class MockEntity : Fetcher {
            let key = "test"
            
            func fetchWithSuccess(success doSuccess : (DataConvertible) -> (), failure doFailure : ((NSError?) -> ())) {
                let error = Haneke.errorWithCode(0, description: "test")
                doFailure(error)
            }
            
            func cancelFetch() {}
            
        }
        
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let key = self.name
        let entity = MockEntity()
        let expectation = self.expectationWithDescription(self.name)
        
        sut.hnk_setImageFromEntity(entity, failure:{error in
            XCTAssertEqual(error!.domain, Haneke.Domain)
            expectation.fulfill()
        })
        
        XCTAssertNil(sut.image)
        XCTAssertEqual(sut.hnk_entity.key, entity.key)
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    // MARK: setImageFromURL
    
    func testSetImageFromURL_MemoryMiss() {
        let URL = NSURL(string: "http://haneke.io")
        let entity = NetworkEntity<UIImage>(URL: URL)
        
        sut.hnk_setImageFromURL(URL)
        
        XCTAssertNil(sut.image)
        XCTAssertEqual(sut.hnk_entity.key, entity.key)
    }
    
    func testSetImageFromURL_MemoryHit() {
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let URL = NSURL(string: "http://haneke.io")
        let entity = NetworkEntity<UIImage>(URL: URL)
        let cache = Haneke.sharedCache
        let format = sut.hnk_format
        cache.setImage(image, entity.key, formatName: format.name)
        
        sut.hnk_setImageFromURL(URL)
        
        XCTAssertTrue(sut.image!.isEqualPixelByPixel(image))
        XCTAssertTrue(sut.hnk_entity == nil)
    }
    
    func testSetImageFromURL_ImageSet_MemoryMiss() {
        let previousImage = UIImage.imageWithColor(UIColor.redColor())
        let URL = NSURL(string: "http://haneke.io")
        let entity = NetworkEntity<UIImage>(URL: URL)
        sut.image = previousImage
        
        sut.hnk_setImageFromURL(URL)
        
        XCTAssertEqual(sut.image!, previousImage)
        XCTAssertEqual(sut.hnk_entity.key, entity.key)
    }
    
    func testSetImageFromURL_UsingPlaceholder_MemoryMiss() {
        let placeholder = UIImage.imageWithColor(UIColor.yellowColor())
        let URL = NSURL(string: "http://haneke.io")
        let entity = NetworkEntity<UIImage>(URL: URL)
        
        sut.hnk_setImageFromURL(URL, placeholder: placeholder)
        
        XCTAssertEqual(sut.image!, placeholder)
        XCTAssertEqual(sut.hnk_entity.key, entity.key)
    }
    
    func testSetImageFromURL_UsingPlaceholder_MemoryHit() {
        let placeholder = UIImage.imageWithColor(UIColor.yellowColor())
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let URL = NSURL(string: "http://haneke.io")
        let entity = NetworkEntity<UIImage>(URL: URL)
        let cache = Haneke.sharedCache
        let format = sut.hnk_format
        cache.setImage(image, entity.key, formatName: format.name)
        
        sut.hnk_setImageFromURL(URL, placeholder: placeholder)
        
        XCTAssertTrue(sut.image!.isEqualPixelByPixel(image))
        XCTAssertTrue(sut.hnk_entity == nil)
    }
    
    func testSetImageFromURL_Success() {
        let image = UIImage.imageWithColor(UIColor.greenColor())
        OHHTTPStubs.stubRequestsPassingTest({ _ in
            return true
            }, withStubResponse: { _ in
                let data = UIImagePNGRepresentation(image)
                return OHHTTPStubsResponse(data: data, statusCode: 200, headers:nil)
        })
        let URL = NSURL(string: "http://haneke.io")
        let entity = NetworkEntity<UIImage>(URL: URL)
        sut.contentMode = .Center // No resizing
        let expectation = self.expectationWithDescription(self.name)
        
        sut.hnk_setImageFromURL(URL, success:{resultImage in
            XCTAssertTrue(resultImage.isEqualPixelByPixel(image))
            expectation.fulfill()
        })
        
        XCTAssertNil(sut.image)
        XCTAssertEqual(sut.hnk_entity.key, entity.key)
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testSetImageFromURL_Failure() {
        OHHTTPStubs.stubRequestsPassingTest({ _ in
            return true
            }, withStubResponse: { _ in
                let data = NSData.dataWithLength(100)
                return OHHTTPStubsResponse(data: data, statusCode: 404, headers:nil)
        })
        let URL = NSURL(string: "http://haneke.io")
        let entity = NetworkEntity<UIImage>(URL: URL)
        let expectation = self.expectationWithDescription(self.name)
        
        sut.hnk_setImageFromURL(URL, failure:{error in
            XCTAssertEqual(error!.domain, Haneke.Domain)
            expectation.fulfill()
        })
        
        XCTAssertNil(sut.image)
        XCTAssertEqual(sut.hnk_entity.key, entity.key)
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    // MARK: cancelSetImage
    
    func testCancelSetImage() {
        sut.hnk_cancelSetImage()
        
        XCTAssertTrue(sut.hnk_entity == nil)
    }
    
    func testCancelSetImage_AfterSetImage() {
        let URL = NSURL(string: "http://imgs.xkcd.com/comics/election.png")
        sut.hnk_setImageFromURL(URL, success: { _ in
            XCTFail("unexpected success")
        }, failure: { _ in
            XCTFail("unexpected failure")
        })
        
        sut.hnk_cancelSetImage()
        
        XCTAssertTrue(sut.hnk_entity == nil)
        self.waitFor(0.1)
    }

}
