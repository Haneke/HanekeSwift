//
//  UIImageView+HanekeTests.swift
//  Haneke
//
//  Created by Hermes Pique on 9/17/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import UIKit
import XCTest

class UIImageView_HanekeTests: DiskTestCase {

    var sut : UIImageView!
    
    override func setUp() {
        super.setUp()
        sut = UIImageView(frame: CGRectMake(0, 0, 10, 10))
    }
    
    override func tearDown() {
        OHHTTPStubs.removeAllStubs()
        
        let format = sut.hnk_format
        let cache = Haneke.sharedImageCache
        cache.removeAll()
        super.tearDown()
    }
    
    func testScaleMode_ScaleToFill() {
        sut.contentMode = .ScaleToFill
        XCTAssertEqual(sut.hnk_scaleMode, ImageResizer.ScaleMode.Fill)
    }
    
    func testScaleMode_ScaleAspectFit() {
        sut.contentMode = .ScaleAspectFit
        XCTAssertEqual(sut.hnk_scaleMode, ImageResizer.ScaleMode.AspectFit)
    }
    
    func testScaleMode_ScaleAspectFill() {
        sut.contentMode = .ScaleAspectFill
        XCTAssertEqual(sut.hnk_scaleMode, ImageResizer.ScaleMode.AspectFill)
    }
    
    func testScaleMode_Redraw() {
        sut.contentMode = .Redraw
        XCTAssertEqual(sut.hnk_scaleMode, ImageResizer.ScaleMode.None)
    }
    
    func testScaleMode_Center() {
        sut.contentMode = .Center
        XCTAssertEqual(sut.hnk_scaleMode, ImageResizer.ScaleMode.None)
    }
    
    func testScaleMode_Top() {
        sut.contentMode = .Top
        XCTAssertEqual(sut.hnk_scaleMode, ImageResizer.ScaleMode.None)
    }
    
    func testScaleMode_Bottom() {
        sut.contentMode = .Bottom
        XCTAssertEqual(sut.hnk_scaleMode, ImageResizer.ScaleMode.None)
    }
    
    func testScaleMode_Left() {
        sut.contentMode = .Left
        XCTAssertEqual(sut.hnk_scaleMode, ImageResizer.ScaleMode.None)
    }
    
    func testScaleMode_Right() {
        sut.contentMode = .Right
        XCTAssertEqual(sut.hnk_scaleMode, ImageResizer.ScaleMode.None)
    }
    
    func testScaleMode_TopLeft() {
        sut.contentMode = .TopLeft
        XCTAssertEqual(sut.hnk_scaleMode, ImageResizer.ScaleMode.None)
    }
    
    func testScaleMode_TopRight() {
        sut.contentMode = .TopRight
        XCTAssertEqual(sut.hnk_scaleMode, ImageResizer.ScaleMode.None)
    }
    
    func testScaleMode_BottomLeft() {
        sut.contentMode = .BottomLeft
        XCTAssertEqual(sut.hnk_scaleMode, ImageResizer.ScaleMode.None)
    }
    
    func testScaleMode_BottomRight() {
        sut.contentMode = .BottomRight
        XCTAssertEqual(sut.hnk_scaleMode, ImageResizer.ScaleMode.None)
    }
    
    func testFormatWithSize() {
        let size = CGSizeMake(10, 20)
        let scaleMode = ImageResizer.ScaleMode.Fill
        let image = UIImage.imageWithColor(UIColor.redColor())
        let resizer = ImageResizer(size: size, scaleMode: scaleMode, allowUpscaling: true, compressionQuality: Haneke.UIKitGlobals.DefaultFormat.CompressionQuality)
        
        let format = Haneke.UIKitGlobals.formatWithSize(size, scaleMode: scaleMode)
        
        XCTAssertEqual(format.diskCapacity, Haneke.UIKitGlobals.DefaultFormat.DiskCapacity)
        let result = format.apply(image)
        let expected = resizer.resizeImage(image)
        XCTAssertTrue(result.isEqualPixelByPixel(expected))
    }
    
    func testFormat_Default() {
        let cache = Haneke.sharedImageCache
        let resizer = ImageResizer(size: sut.bounds.size, scaleMode: sut.hnk_scaleMode, allowUpscaling: true, compressionQuality: Haneke.UIKitGlobals.DefaultFormat.CompressionQuality)
        let image = UIImage.imageWithColor(UIColor.greenColor())
        
        let format = sut.hnk_format
        
        XCTAssertEqual(format.diskCapacity, Haneke.UIKitGlobals.DefaultFormat.DiskCapacity)
        XCTAssertTrue(cache.formats[format.name] != nil) // Can't use XCTAssertNotNil because it expects AnyObject
        let result = format.apply(image)
        let expected = resizer.resizeImage(image)
        XCTAssertTrue(result.isEqualPixelByPixel(expected))
    }

    // MARK: setImage

    func testSetImage_MemoryMiss() {
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let key = self.name
        
        sut.hnk_setImage(image, key: key)
        
        XCTAssertNil(sut.image)
        XCTAssertEqual(sut.hnk_fetcher.key, key)
    }
    
    func testSetImage_MemoryHit() {
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let key = self.name
        let expectedImage = setImage(image, key: key)
        
        sut.hnk_setImage(image, key: key)
        
        XCTAssertTrue(sut.image?.isEqualPixelByPixel(expectedImage) == true)
        XCTAssertTrue(sut.hnk_fetcher == nil)
    }
    
    func testSetImage_ImageSet_MemoryMiss() {
        let previousImage = UIImage.imageWithColor(UIColor.redColor())
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let key = self.name
        sut.image = previousImage
        
        sut.hnk_setImage(image, key: key)
        
        XCTAssertEqual(sut.image!, previousImage)
        XCTAssertEqual(sut.hnk_fetcher.key, key)
    }
    
    func testSetImage_UsingPlaceholder_MemoryMiss() {
        let placeholder = UIImage.imageWithColor(UIColor.yellowColor())
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let key = self.name
        
        sut.hnk_setImage(image, key: key, placeholder: placeholder)
        
        XCTAssertEqual(sut.image!, placeholder)
        XCTAssertEqual(sut.hnk_fetcher.key, key)
    }
    
    func testSetImage_UsingPlaceholder_MemoryHit() {
        let placeholder = UIImage.imageWithColor(UIColor.yellowColor())
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let key = self.name
        let expectedImage = setImage(image, key: key)
        
        sut.hnk_setImage(image, key: key, placeholder: placeholder)
        
        XCTAssertTrue(sut.image?.isEqualPixelByPixel(expectedImage) == true)
        XCTAssertTrue(sut.hnk_fetcher == nil)
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
        XCTAssertEqual(sut.hnk_fetcher.key, key)
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testSetImage_UsingFormat() {
        let image = UIImage.imageWithColor(UIColor.redColor())
        let expectedImage = UIImage.imageWithColor(UIColor.greenColor())
        let format = Format<UIImage>(name: self.name, diskCapacity: 0) { _ in return expectedImage }
        let key = self.name
        let expectation = self.expectationWithDescription(self.name)
        
        sut.hnk_setImage(image, key: key, format: format, success:{resultImage in
            XCTAssertTrue(resultImage.isEqualPixelByPixel(expectedImage))
            expectation.fulfill()
        })
        
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    // MARK: setImageFromFetcher

    func testSetImageFromFetcher_MemoryMiss() {
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let key = self.name
        let fetcher = SimpleFetcher<UIImage>(key: key, value: image)
        
        sut.hnk_setImageFromFetcher(fetcher)

        XCTAssertNil(sut.image)
        XCTAssertTrue(sut.hnk_fetcher === fetcher)
    }
    
    func testSetImageFromFetcher_MemoryHit() {
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let key = self.name
        let fetcher = SimpleFetcher<UIImage>(key: key, value: image)
        let expectedImage = setImage(image, key: key)
        
        sut.hnk_setImageFromFetcher(fetcher)
        
        XCTAssertTrue(sut.image?.isEqualPixelByPixel(expectedImage) == true)
        XCTAssertTrue(sut.hnk_fetcher == nil)
    }
    
    func testSetImageFromFetcher_ImageSet_MemoryMiss() {
        let previousImage = UIImage.imageWithColor(UIColor.redColor())
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let key = self.name
        let fetcher = SimpleFetcher<UIImage>(key: key, value: image)
        sut.image = previousImage
        
        sut.hnk_setImageFromFetcher(fetcher)
        
        XCTAssertEqual(sut.image!, previousImage)
        XCTAssertTrue(sut.hnk_fetcher === fetcher)
    }

    func testSetImageFromFetcher_UsingPlaceholder_MemoryMiss() {
        let placeholder = UIImage.imageWithColor(UIColor.yellowColor())
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let key = self.name
        let fetcher = SimpleFetcher<UIImage>(key: key, value: image)
        
        sut.hnk_setImageFromFetcher(fetcher, placeholder:placeholder)
        
        XCTAssertEqual(sut.image!, placeholder)
        XCTAssertTrue(sut.hnk_fetcher === fetcher)
    }
    
    func testSetImageFromFetcher_UsingPlaceholder_MemoryHit() {
        let placeholder = UIImage.imageWithColor(UIColor.yellowColor())
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let key = self.name
        let fetcher = SimpleFetcher<UIImage>(key: key, value: image)
        let expectedImage = setImage(image, key: key)
        
        sut.hnk_setImageFromFetcher(fetcher, placeholder:placeholder)
        
        XCTAssertTrue(sut.image?.isEqualPixelByPixel(expectedImage) == true)
        XCTAssertTrue(sut.hnk_fetcher == nil)
    }
    
    func testSetImageFromFetcher_Success() {
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let key = self.name
        let fetcher = SimpleFetcher<UIImage>(key: key, value: image)
        sut.contentMode = .Center // No resizing
        let expectation = self.expectationWithDescription(self.name)
        
        sut.hnk_setImageFromFetcher(fetcher, success: { resultImage in
            XCTAssertTrue(resultImage.isEqualPixelByPixel(image))
            expectation.fulfill()
        })
        
        XCTAssertNil(sut.image)
        XCTAssertTrue(sut.hnk_fetcher === fetcher)
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testSetImageFromFetcher_Failure() {
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let key = self.name
        let fetcher = MockFetcher<UIImage>(key:key)
        let expectation = self.expectationWithDescription(self.name)
        
        sut.hnk_setImageFromFetcher(fetcher, failure: {error in
            XCTAssertEqual(error!.domain, Haneke.Domain)
            expectation.fulfill()
        })
        
        XCTAssertNil(sut.image)
        XCTAssertTrue(sut.hnk_fetcher === fetcher)
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testSetImageFromFetcher_UsingFormat() {
        let image = UIImage.imageWithColor(UIColor.redColor())
        let expectedImage = UIImage.imageWithColor(UIColor.greenColor())
        let format = Format<UIImage>(name: self.name, diskCapacity: 0) { _ in return expectedImage }
        let key = self.name
        let fetcher = SimpleFetcher<UIImage>(key: key, value: image)
        let expectation = self.expectationWithDescription(self.name)
        
        sut.hnk_setImageFromFetcher(fetcher, format: format, success: { resultImage in
            XCTAssertTrue(resultImage.isEqualPixelByPixel(expectedImage))
            expectation.fulfill()
        })
        
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    // MARK: setImageFromFile
    
    func testSetImageFromFile_MemoryMiss() {
        let fetcher = DiskFetcher<UIImage>(path: self.uniquePath())
        
        sut.hnk_setImageFromFile(fetcher.key)
        
        XCTAssertNil(sut.image)
        XCTAssertEqual(sut.hnk_fetcher.key, fetcher.key)
    }
    
    func testSetImageFromFile_MemoryHit() {
        let image = UIImage.imageWithColor(UIColor.orangeColor())
        let fetcher = DiskFetcher<UIImage>(path: self.uniquePath())
        let expectedImage = setImage(image, key: fetcher.key)
        
        sut.hnk_setImageFromFile(fetcher.key)
        
        XCTAssertTrue(sut.image?.isEqualPixelByPixel(expectedImage) == true)
        XCTAssertTrue(sut.hnk_fetcher == nil)
    }
    
    func testSetImageFromFileSuccessFailure_MemoryHit() {
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let fetcher = DiskFetcher<UIImage>(path: self.uniquePath())
        let expectedImage = setImage(image, key: fetcher.key)
        
        sut.hnk_setImageFromFile(fetcher.key, failure: {error in
            XCTFail("")
        }) { result in
            XCTAssertTrue(result.isEqualPixelByPixel(expectedImage))
        }
    }
    
    // MARK: setImageFromURL
    
    func testSetImageFromURL_MemoryMiss() {
        let URL = NSURL(string: "http://haneke.io")!
        let fetcher = NetworkFetcher<UIImage>(URL: URL)
        
        sut.hnk_setImageFromURL(URL)
        
        XCTAssertNil(sut.image)
        XCTAssertEqual(sut.hnk_fetcher.key, fetcher.key)
    }
    
    func testSetImageFromURL_MemoryHit() {
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let URL = NSURL(string: "http://haneke.io")!
        let fetcher = NetworkFetcher<UIImage>(URL: URL)
        let expectedImage = setImage(image, key: fetcher.key)
        
        sut.hnk_setImageFromURL(URL)
        
        XCTAssertTrue(sut.image?.isEqualPixelByPixel(expectedImage) == true)
        XCTAssertTrue(sut.hnk_fetcher == nil)
    }
    
    func testSetImageFromURL_ImageSet_MemoryMiss() {
        let previousImage = UIImage.imageWithColor(UIColor.redColor())
        let URL = NSURL(string: "http://haneke.io")!
        let fetcher = NetworkFetcher<UIImage>(URL: URL)
        sut.image = previousImage
        
        sut.hnk_setImageFromURL(URL)
        
        XCTAssertEqual(sut.image!, previousImage)
        XCTAssertEqual(sut.hnk_fetcher.key, fetcher.key)
    }
    
    func testSetImageFromURL_UsingPlaceholder_MemoryMiss() {
        let placeholder = UIImage.imageWithColor(UIColor.yellowColor())
        let URL = NSURL(string: "http://haneke.io")!
        let fetcher = NetworkFetcher<UIImage>(URL: URL)
        
        sut.hnk_setImageFromURL(URL, placeholder: placeholder)
        
        XCTAssertEqual(sut.image!, placeholder)
        XCTAssertEqual(sut.hnk_fetcher.key, fetcher.key)
    }
    
    func testSetImageFromURL_UsingPlaceholder_MemoryHit() {
        let placeholder = UIImage.imageWithColor(UIColor.yellowColor())
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let URL = NSURL(string: "http://haneke.io")!
        let fetcher = NetworkFetcher<UIImage>(URL: URL)
        let expectedImage = setImage(image, key: fetcher.key)
        
        sut.hnk_setImageFromURL(URL, placeholder: placeholder)
        
        XCTAssertTrue(sut.image?.isEqualPixelByPixel(expectedImage) == true)
        XCTAssertTrue(sut.hnk_fetcher == nil)
    }
    
    func testSetImageFromURL_Success() {
        let image = UIImage.imageWithColor(UIColor.greenColor())
        OHHTTPStubs.stubRequestsPassingTest({ _ in
            return true
            }, withStubResponse: { _ in
                let data = UIImagePNGRepresentation(image)
                return OHHTTPStubsResponse(data: data, statusCode: 200, headers:nil)
        })
        let URL = NSURL(string: "http://haneke.io")!
        let fetcher = NetworkFetcher<UIImage>(URL: URL)
        sut.contentMode = .Center // No resizing
        let expectation = self.expectationWithDescription(self.name)
        
        sut.hnk_setImageFromURL(URL, success:{resultImage in
            XCTAssertTrue(resultImage.isEqualPixelByPixel(image))
            expectation.fulfill()
        })
        
        XCTAssertNil(sut.image)
        XCTAssertEqual(sut.hnk_fetcher.key, fetcher.key)
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testSetImageFromURL_WhenPreviousSetImageFromURL() {
        let image = UIImage.imageWithColor(UIColor.greenColor())
        OHHTTPStubs.stubRequestsPassingTest({ _ in
            return true
            }, withStubResponse: { _ in
                let data = UIImagePNGRepresentation(image)
                return OHHTTPStubsResponse(data: data, statusCode: 200, headers:nil).responseTime(0.1)
        })
        let URL1 = NSURL(string: "http://haneke.io/1.png")!
        sut.contentMode = .Center // No resizing
        sut.hnk_setImageFromURL(URL1, success:{_ in
            XCTFail("unexpected success")
            }, failure:{_ in
            XCTFail("unexpected failure")
        })
        let URL2 = NSURL(string: "http://haneke.io/2.png")!
        let fetcher2 = NetworkFetcher<UIImage>(URL: URL2)
        let expectation = self.expectationWithDescription(self.name)
        
        sut.hnk_setImageFromURL(URL2, success:{resultImage in
            XCTAssertTrue(resultImage.isEqualPixelByPixel(image))
            expectation.fulfill()
        })
        
        XCTAssertNil(sut.image)
        XCTAssertEqual(sut.hnk_fetcher.key, fetcher2.key)
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testSetImageFromURL_Failure() {
        OHHTTPStubs.stubRequestsPassingTest({ _ in
            return true
            }, withStubResponse: { _ in
                let data = NSData.dataWithLength(100)
                return OHHTTPStubsResponse(data: data, statusCode: 404, headers:nil)
        })
        let URL = NSURL(string: "http://haneke.io")!
        let fetcher = NetworkFetcher<UIImage>(URL: URL)
        let expectation = self.expectationWithDescription(self.name)
        
        sut.hnk_setImageFromURL(URL, failure:{error in
            XCTAssertEqual(error!.domain, Haneke.Domain)
            expectation.fulfill()
        })
        
        XCTAssertNil(sut.image)
        XCTAssertEqual(sut.hnk_fetcher.key, fetcher.key)
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testSetImageFromURL_UsingFormat() {
        let image = UIImage.imageWithColor(UIColor.redColor())
        let expectedImage = UIImage.imageWithColor(UIColor.greenColor())
        let format = Format<UIImage>(name: self.name, diskCapacity: 0) { _ in return expectedImage }
        OHHTTPStubs.stubRequestsPassingTest({ _ in
            return true
            }, withStubResponse: { _ in
                let data = UIImagePNGRepresentation(image)
                return OHHTTPStubsResponse(data: data, statusCode: 200, headers:nil)
        })
        let URL = NSURL(string: "http://haneke.io")!
        let fetcher = NetworkFetcher<UIImage>(URL: URL)
        let expectation = self.expectationWithDescription(self.name)
        
        sut.hnk_setImageFromURL(URL, format: format, success:{resultImage in
            XCTAssertTrue(resultImage.isEqualPixelByPixel(expectedImage))
            expectation.fulfill()
        })
        
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    // MARK: cancelSetImage
    
    func testCancelSetImage() {
        sut.hnk_cancelSetImage()
        
        XCTAssertTrue(sut.hnk_fetcher == nil)
    }
    
    func testCancelSetImage_AfterSetImage() {
        let URL = NSURL(string: "http://imgs.xkcd.com/comics/election.png")!
        sut.hnk_setImageFromURL(URL, success: { _ in
            XCTFail("unexpected success")
        }, failure: { _ in
            XCTFail("unexpected failure")
        })
        
        sut.hnk_cancelSetImage()
        
        XCTAssertTrue(sut.hnk_fetcher == nil)
        self.waitFor(0.1)
    }
    
    // MARK: Helpers
    
    func setImage(image : UIImage, key: String) -> UIImage {
        let format = sut.hnk_format
        let expectedImage = format.apply(image)
        let cache = Haneke.sharedImageCache
        cache.addFormat(format)
        let expectation = self.expectationWithDescription("set")
        cache.set(value: image, key: key, formatName: format.name) { _ in
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1, handler: nil)
        return expectedImage
    }

}

class MockFetcher<T : DataConvertible> : Fetcher<T> {
    
    override init(key: String) {
        super.init(key: key)
    }
    
    override func fetch(failure fail : ((NSError?) -> ()), success succeed : (T.Result) -> ()) {
        let error = Haneke.errorWithCode(0, description: "test")
        fail(error)
    }
    
    override func cancelFetch() {}
    
}
