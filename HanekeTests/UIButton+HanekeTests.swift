//
//  UIButton+HanekeTests.swift
//  Haneke
//
//  Created by Joan Romano on 10/6/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import UIKit
import XCTest

class UIButton_HanekeTests: DiskTestCase {
    
    var sut : UIButton!
    
    override func setUp() {
        super.setUp()
        sut = UIButton(frame: CGRectMake(0, 0, 100, 20))
    }
    
    override func tearDown() {
        sut.hnk_cancelSetImage()
        sut.hnk_cancelSetBackgroundImage()
        OHHTTPStubs.removeAllStubs()
        
        Haneke.sharedImageCache.removeAll()
        super.tearDown()
    }
    
    // MARK: imageFormat
    
    func testImageFormat_Default() {
        let formatSize = sut.contentRectForBounds(sut.bounds).size
        let format = sut.hnk_imageFormat
        let resizer = ImageResizer(size: sut.bounds.size, scaleMode: .AspectFit, allowUpscaling: false, compressionQuality: Haneke.UIKitGlobals.DefaultFormat.CompressionQuality)
        let image = UIImage.imageWithColor(UIColor.redColor())
        
        XCTAssertEqual(format.diskCapacity, Haneke.UIKitGlobals.DefaultFormat.DiskCapacity)
        let result = format.apply(image)
        let expected = resizer.resizeImage(image)
        XCTAssertTrue(result.isEqualPixelByPixel(expected))
    }
    
    // MARK: setImage
    
    func testSetImage_MemoryMiss_UIControlStateNormal() {
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let key = self.name
        
        sut.hnk_setImage(image, key: key)
        
        XCTAssertNil(sut.imageForState(.Normal))
        XCTAssertEqual(sut.hnk_imageFetcher.key, key)
    }
    
    func testSetImage_MemoryHit_UIControlStateSelected() {
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let key = self.name
        let expectedImage = setImage(image, key: key, format: sut.hnk_imageFormat)
        
        sut.hnk_setImage(image, key: key, state: .Selected)
        
        XCTAssertTrue(sut.imageForState(.Selected)?.isEqualPixelByPixel(expectedImage) == true)
        XCTAssertTrue(sut.hnk_imageFetcher == nil)
    }
    
    func testSetImage_UsingPlaceholder_MemoryMiss_UIControlStateDisabled() {
        let placeholder = UIImage.imageWithColor(UIColor.yellowColor())
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let key = self.name
        
        sut.hnk_setImage(image, key: key, state: .Disabled, placeholder: placeholder)
        
        XCTAssertEqual(sut.imageForState(.Disabled)!, placeholder)
        XCTAssertEqual(sut.hnk_imageFetcher.key, key)
    }
    
    func testSetImage_UsingPlaceholder_MemoryHit_UIControlStateNormal() {
        let placeholder = UIImage.imageWithColor(UIColor.yellowColor())
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let key = self.name
        let expectedImage = setImage(image, key: key, format: sut.hnk_imageFormat)
        
        sut.hnk_setImage(image, key: key, placeholder: placeholder)
        
        XCTAssertTrue(sut.imageForState(.Normal)?.isEqualPixelByPixel(expectedImage) == true)
        XCTAssertTrue(sut.hnk_imageFetcher == nil)
    }
    
    func testSetImage_UsingFormat_UIControlStateHighlighted() {
        let image = UIImage.imageWithColor(UIColor.redColor())
        let expectedImage = UIImage.imageWithColor(UIColor.greenColor())
        let format = Format<UIImage>(name: self.name, diskCapacity: 0) { _ in return expectedImage }
        let key = self.name
        let expectation = self.expectationWithDescription(self.name)
        
        sut.hnk_setImage(image, key: key, state: .Highlighted, format: format, success:{resultImage in
            XCTAssertTrue(resultImage.isEqualPixelByPixel(expectedImage))
            expectation.fulfill()
        })
        
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    // MARK: setImageFromFile
    
    func testSetImageFromFile_MemoryMiss_UIControlStateSelected() {
        let fetcher = DiskFetcher<UIImage>(path: self.uniquePath())
        
        sut.hnk_setImageFromFile(fetcher.key, state: .Selected)
        
        XCTAssertNil(sut.imageForState(.Selected))
        XCTAssertEqual(sut.hnk_imageFetcher.key, fetcher.key)
    }
    
    func testSetImageFromFile_MemoryHit_UIControlStateNormal() {
        let image = UIImage.imageWithColor(UIColor.orangeColor())
        let fetcher = DiskFetcher<UIImage>(path: self.uniquePath())
        let expectedImage = setImage(image, key: fetcher.key, format: sut.hnk_imageFormat)
        
        sut.hnk_setImageFromFile(fetcher.key)
        
        XCTAssertTrue(sut.imageForState(.Normal)?.isEqualPixelByPixel(image) == true)
        XCTAssertTrue(sut.hnk_imageFetcher == nil)
    }
    
    func testSetImageFromFileSuccessFailure_MemoryHit_UIControlStateSelected() {
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let fetcher = DiskFetcher<UIImage>(path: self.uniquePath())
        let cache = Haneke.sharedImageCache
        let format = sut.hnk_imageFormat
        cache.set(value: image, key: fetcher.key, formatName: format.name)
        
        sut.hnk_setImageFromFile(fetcher.key, state: .Selected, failure: {error in
            XCTFail("")
            }){result in
                XCTAssertTrue(result.isEqualPixelByPixel(image))
        }
    }
    
    // MARK: setImageFromURL
    
    func testSetImageFromURL_MemoryMiss_UIControlStateSelected() {
        let URL = NSURL(string: "http://haneke.io")!
        let fetcher = NetworkFetcher<UIImage>(URL: URL)
        
        sut.hnk_setImageFromURL(URL, state: .Selected)
        
        XCTAssertNil(sut.imageForState(.Selected))
        XCTAssertEqual(sut.hnk_imageFetcher.key, fetcher.key)
    }
    
    func testSetImageFromURL_MemoryHit_UIControlStateNormal() {
        let image = UIImage.imageWithColor(UIColor.orangeColor())
        let URL = NSURL(string: "http://haneke.io")!
        let fetcher = NetworkFetcher<UIImage>(URL: URL)
        let expectedImage = setImage(image, key: fetcher.key, format: sut.hnk_imageFormat)
        
        sut.hnk_setImageFromURL(URL)
        
        XCTAssertTrue(sut.imageForState(.Normal)?.isEqualPixelByPixel(expectedImage) == true)
        XCTAssertTrue(sut.hnk_imageFetcher == nil)
    }
    
    func testSetImageFromURLSuccessFailure_MemoryHit_UIControlStateSelected() {
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let URL = NSURL(string: "http://haneke.io")!
        let fetcher = NetworkFetcher<UIImage>(URL: URL)
        let cache = Haneke.sharedImageCache
        let format = sut.hnk_imageFormat
        cache.set(value: image, key: fetcher.key, formatName: format.name)
        
        sut.hnk_setImageFromURL(URL, state: .Selected, failure: {error in
            XCTFail("")
            }){result in
                XCTAssertTrue(result.isEqualPixelByPixel(image))
        }
    }
    
    func testSetImageFromURL_Failure_UIControlStateNormal() {
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
        
        XCTAssertNil(sut.imageForState(.Normal))
        XCTAssertEqual(sut.hnk_imageFetcher.key, fetcher.key)
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
    
    // MARK: setImageFromFetcher
    
    func testSetImageFromFetcher_MemoryMiss_UIControlStateSelected() {
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let key = self.name
        let fetcher = SimpleFetcher<UIImage>(key: key, value: image)
        
        sut.hnk_setImageFromFetcher(fetcher, state: .Selected)
        
        XCTAssertNil(sut.imageForState(.Selected))
        XCTAssertTrue(sut.hnk_imageFetcher === fetcher)
    }
    
    func testSetImageFromFetcher_MemoryHit_UIControlStateNormal() {
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let key = self.name
        let fetcher = SimpleFetcher<UIImage>(key: key, value: image)
        let expectedImage = setImage(image, key: key, format: sut.hnk_imageFormat)
        
        sut.hnk_setImageFromFetcher(fetcher)
        
        XCTAssertTrue(sut.imageForState(.Normal)?.isEqualPixelByPixel(image) == true)
        XCTAssertTrue(sut.hnk_imageFetcher == nil)
    }
    
    func testSetImageFromFetcherSuccessFailure_MemoryHit_UIControlStateNormal() {
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let key = self.name
        let fetcher = SimpleFetcher<UIImage>(key: key, value: image)
        let cache = Haneke.sharedImageCache
        let format = sut.hnk_imageFormat
        cache.set(value: image, key: key, formatName: format.name)
        
        sut.hnk_setImageFromFetcher(fetcher, failure: {error in
            XCTFail("")
            }){result in
                XCTAssertTrue(result.isEqualPixelByPixel(image))
        }
    }
    
    // MARK: cancelSetImage
    
    func testCancelSetImage() {
        sut.hnk_cancelSetImage()
        
        XCTAssertTrue(sut.hnk_imageFetcher == nil)
    }
    
    func testCancelSetImage_AfterSetImage() {
        let URL = NSURL(string: "http://imgs.xkcd.com/comics/election.png")!
        sut.hnk_setImageFromURL(URL, success: { _ in
            XCTFail("unexpected success")
            }, failure: { _ in
                XCTFail("unexpected failure")
        })
        
        sut.hnk_cancelSetImage()
        
        XCTAssertTrue(sut.hnk_imageFetcher == nil)
        self.waitFor(0.1)
    }

    func testCancelSetImage_AfterSetImage_UIControlStateHighlighted() {
        let URL = NSURL(string: "http://imgs.xkcd.com/comics/election.png")!
        sut.hnk_setImageFromURL(URL, state: .Highlighted, success: { _ in
            XCTFail("unexpected success")
            }, failure: { _ in
                XCTFail("unexpected failure")
        })
        
        sut.hnk_cancelSetImage()
        
        XCTAssertTrue(sut.hnk_imageFetcher == nil)
        self.waitFor(0.1)
    }
    
    // MARK: backgroundImageFormat

    func testBackgroundImageFormat_Default() {
        let formatSize = sut.contentRectForBounds(sut.bounds).size
        let format = sut.hnk_backgroundImageFormat
        let resizer = ImageResizer(size: sut.bounds.size, scaleMode: .Fill, allowUpscaling: true, compressionQuality: Haneke.UIKitGlobals.DefaultFormat.CompressionQuality)
        let image = UIImage.imageWithColor(UIColor.redColor())
        
        XCTAssertEqual(format.diskCapacity, Haneke.UIKitGlobals.DefaultFormat.DiskCapacity)
        let result = format.apply(image)
        let expected = resizer.resizeImage(image)
        XCTAssertTrue(result.isEqualPixelByPixel(expected))
    }

    // MARK: setBackgroundImage
    
    func testSetBackgroundImage_MemoryMiss_UIControlStateNormal() {
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let key = self.name
        
        sut.hnk_setBackgroundImage(image, key: key)
        
        XCTAssertNil(sut.backgroundImageForState(.Normal))
        XCTAssertEqual(sut.hnk_backgroundImageFetcher.key, key)
    }

    func testSetBackgroundImage_MemoryHit_UIControlStateSelected() {
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let key = self.name
        let expectedImage = setImage(image, key: key, format: sut.hnk_backgroundImageFormat)
        
        sut.hnk_setBackgroundImage(image, key: key, state: .Selected)
        
        let result = sut.backgroundImageForState(.Selected)
        XCTAssertTrue(result?.isEqualPixelByPixel(expectedImage) == true)
        XCTAssertTrue(sut.hnk_backgroundImageFetcher == nil)
    }

    func testSetBackgroundImage_UsingPlaceholder_MemoryMiss_UIControlStateDisabled() {
        let placeholder = UIImage.imageWithColor(UIColor.yellowColor())
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let key = self.name
        
        sut.hnk_setBackgroundImage(image, key: key, state: .Disabled, placeholder: placeholder)
        
        XCTAssertEqual(sut.backgroundImageForState(.Disabled)!, placeholder)
        XCTAssertEqual(sut.hnk_backgroundImageFetcher.key, key)
    }

    func testSetBackgroundImage_UsingPlaceholder_MemoryHit_UIControlStateNormal() {
        let placeholder = UIImage.imageWithColor(UIColor.yellowColor())
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let key = self.name
        let expectedImage = setImage(image, key: key, format: sut.hnk_backgroundImageFormat)
        
        sut.hnk_setBackgroundImage(image, key: key, placeholder: placeholder)
        
        let result = sut.backgroundImageForState(.Normal)
        XCTAssertTrue(result?.isEqualPixelByPixel(expectedImage) == true)
        XCTAssertTrue(sut.hnk_backgroundImageFetcher == nil)
    }
   
    func testSetBackgroundImage_UsingFormat_UIControlStateHighlighted() {
        let image = UIImage.imageWithColor(UIColor.redColor())
        let expectedImage = UIImage.imageWithColor(UIColor.greenColor())
        let format = Format<UIImage>(name: self.name, diskCapacity: 0) { _ in return expectedImage }
        let key = self.name
        let expectation = self.expectationWithDescription(self.name)
        
        sut.hnk_setBackgroundImage(image, key: key, state: .Highlighted, format: format, success:{resultImage in
            XCTAssertTrue(resultImage.isEqualPixelByPixel(expectedImage))
            expectation.fulfill()
        })
        
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    // MARK: setBackgroundImageFromFile
    
    func testSetBackgroundImageFromFile_MemoryMiss_UIControlStateSelected() {
        let fetcher = DiskFetcher<UIImage>(path: self.uniquePath())
        
        sut.hnk_setBackgroundImageFromFile(fetcher.key, state: .Selected)
        
        XCTAssertNil(sut.backgroundImageForState(.Selected))
        XCTAssertEqual(sut.hnk_backgroundImageFetcher.key, fetcher.key)
    }
    
    func testSetBackgroundImageFromFile_MemoryHit_UIControlStateNormal() {
        let image = UIImage.imageWithColor(UIColor.orangeColor())
        let fetcher = DiskFetcher<UIImage>(path: self.uniquePath())
        let expectedImage = setImage(image, key: fetcher.key, format: sut.hnk_backgroundImageFormat)
        
        sut.hnk_setBackgroundImageFromFile(fetcher.key)
        
        let result = sut.backgroundImageForState(.Normal)
        XCTAssertTrue(result?.isEqualPixelByPixel(expectedImage) == true)
        XCTAssertTrue(sut.hnk_backgroundImageFetcher == nil)
    }
    
    func testSetBackgroundImageFromFileSuccessFailure_MemoryHit_UIControlStateSelected() {
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let fetcher = DiskFetcher<UIImage>(path: self.uniquePath())
        let cache = Haneke.sharedImageCache
        let format = sut.hnk_backgroundImageFormat
        cache.set(value: image, key: fetcher.key, formatName: format.name)
        
        sut.hnk_setBackgroundImageFromFile(fetcher.key, state: .Selected, failure: {error in
            XCTFail("")
            }){result in
                XCTAssertTrue(result.isEqualPixelByPixel(image))
        }
    }
    
    // MARK: setBackgroundImageFromURL

    func testSetBackgroundImageFromURL_MemoryMiss_UIControlStateSelected() {
        let URL = NSURL(string: "http://haneke.io")!
        let fetcher = NetworkFetcher<UIImage>(URL: URL)
        
        sut.hnk_setBackgroundImageFromURL(URL, state: .Selected)
        
        XCTAssertNil(sut.backgroundImageForState(.Selected))
        XCTAssertEqual(sut.hnk_backgroundImageFetcher.key, fetcher.key)
    }
    
    func testSetBackgroundImageFromURL_MemoryHit_UIControlStateNormal() {
        let image = UIImage.imageWithColor(UIColor.orangeColor())
        let URL = NSURL(string: "http://haneke.io")!
        let fetcher = NetworkFetcher<UIImage>(URL: URL)
        let expectedImage = setImage(image, key: fetcher.key, format: sut.hnk_backgroundImageFormat)
        
        sut.hnk_setBackgroundImageFromURL(URL)
        
        let result = sut.backgroundImageForState(.Normal)
        XCTAssertTrue(result?.isEqualPixelByPixel(expectedImage) == true)
        XCTAssertTrue(sut.hnk_backgroundImageFetcher == nil)
    }
    
    func testSetBackgroundImageFromURLSuccessFailure_MemoryHit_UIControlStateSelected() {
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let URL = NSURL(string: "http://haneke.io")!
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
        let URL = NSURL(string: "http://haneke.io")!
        let fetcher = NetworkFetcher<UIImage>(URL: URL)
        let expectation = self.expectationWithDescription(self.name)
        
        sut.hnk_setBackgroundImageFromURL(URL, failure:{error in
            XCTAssertEqual(error!.domain, Haneke.Domain)
            expectation.fulfill()
        })
        
        XCTAssertNil(sut.backgroundImageForState(.Normal))
        XCTAssertEqual(sut.hnk_backgroundImageFetcher.key, fetcher.key)
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testSetBackgroundImageFromURL_UsingFormat() {
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
        
        sut.hnk_setBackgroundImageFromURL(URL, format: format, success:{resultImage in
            XCTAssertTrue(resultImage.isEqualPixelByPixel(expectedImage))
            expectation.fulfill()
        })
        
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    // MARK: setBackgroundImageFromFetcher
    
    func testSetBackgroundImageFromFetcher_MemoryMiss_UIControlStateSelected() {
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let key = self.name
        let fetcher = SimpleFetcher<UIImage>(key: key, value: image)
        
        sut.hnk_setBackgroundImageFromFetcher(fetcher, state: .Selected)
        
        XCTAssertNil(sut.backgroundImageForState(.Selected))
        XCTAssertTrue(sut.hnk_backgroundImageFetcher === fetcher)
    }
    
    func testSetBackgroundImageFromFetcher_MemoryHit_UIControlStateNormal() {
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let key = self.name
        let fetcher = SimpleFetcher<UIImage>(key: key, value: image)
        let expectedImage = setImage(image, key: key, format: sut.hnk_backgroundImageFormat)
        
        sut.hnk_setBackgroundImageFromFetcher(fetcher)

        let result = sut.backgroundImageForState(.Normal)
        XCTAssertTrue(result?.isEqualPixelByPixel(expectedImage) == true)
        XCTAssertTrue(sut.hnk_backgroundImageFetcher == nil)
    }
    
    func testSetBackgroundImageFromFetcherSuccessFailure_MemoryHit_UIControlStateNormal() {
        let image = UIImage.imageWithColor(UIColor.greenColor())
        let key = self.name
        let fetcher = SimpleFetcher<UIImage>(key: key, value: image)
        let cache = Haneke.sharedImageCache
        let format = sut.hnk_backgroundImageFormat
        cache.set(value: image, key: key, formatName: format.name)
        
        sut.hnk_setBackgroundImageFromFetcher(fetcher, failure: {error in
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
    
    func testCancelSetBackgroundImage_AfterSetImage() {
        let URL = NSURL(string: "http://imgs.xkcd.com/comics/election.png")!
        sut.hnk_setBackgroundImageFromURL(URL, success: { _ in
            XCTFail("unexpected success")
            }, failure: { _ in
                XCTFail("unexpected failure")
        })
        
        sut.hnk_cancelSetBackgroundImage()
        
        XCTAssertTrue(sut.hnk_backgroundImageFetcher == nil)
        self.waitFor(0.1)
    }
    
    func testCancelSetBackgroundImage_AfterSetImage_UIControlStateHighlighted() {
        let URL = NSURL(string: "http://imgs.xkcd.com/comics/election.png")!
        sut.hnk_setBackgroundImageFromURL(URL, state: .Highlighted, success: { _ in
            XCTFail("unexpected success")
            }, failure: { _ in
                XCTFail("unexpected failure")
        })
        
        sut.hnk_cancelSetBackgroundImage()
        
        XCTAssertTrue(sut.hnk_backgroundImageFetcher == nil)
        self.waitFor(0.1)
    }
    
    // MARK: Helpers
    
    func setImage(image : UIImage, key: String, format : Format<UIImage>) -> UIImage {
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
