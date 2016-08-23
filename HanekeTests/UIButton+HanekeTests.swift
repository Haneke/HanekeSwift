//
//  UIButton+HanekeTests.swift
//  Haneke
//
//  Created by Joan Romano on 10/6/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import UIKit
import XCTest
import OHHTTPStubs
@testable import Haneke

class UIButton_HanekeTests: DiskTestCase {
    
    var sut : UIButton!
    
    override func setUp() {
        super.setUp()
        sut = UIButton(frame: CGRect(x: 0, y: 0, width: 100, height: 20))
    }
    
    override func tearDown() {
        sut.hnk_cancelSetImage()
        sut.hnk_cancelSetBackgroundImage()
        OHHTTPStubs.removeAllStubs()
        
        Shared.imageCache.removeAll()
        super.tearDown()
    }
    
    // MARK: imageFormat
    
    func testImageFormat_Default() {
        let formatSize = sut.contentRect(forBounds: sut.bounds).size
        let format = sut.hnk_imageFormat
        let resizer = ImageResizer(size: formatSize, scaleMode: .AspectFit, allowUpscaling: false, compressionQuality: HanekeGlobals.UIKit.DefaultFormat.CompressionQuality)
        let image = UIImage.imageWithColor(UIColor.red)
        
        XCTAssertEqual(format.diskCapacity, HanekeGlobals.UIKit.DefaultFormat.DiskCapacity)
        let result = format.apply(image)
        let expected = resizer.resizeImage(image)
        XCTAssertTrue(result.isEqualPixelByPixel(expected))
    }
    
    // MARK: setImage
    
    func testSetImage_MemoryMiss_UIControlStateNormal() {
        let image = UIImage.imageWithColor(UIColor.green)
        let key = self.name!
        
        sut.hnk_setImage(image, key: key)
        
        XCTAssertNil(sut.image(for: UIControlState()))
        XCTAssertEqual(sut.hnk_imageFetcher.key, key)
    }
    
    func testSetImage_MemoryHit_UIControlStateSelected() {
        let image = UIImage.imageWithColor(UIColor.green)
        let key = self.name!
        let expectedImage = setImage(image, key: key, format: sut.hnk_imageFormat)
        
        sut.hnk_setImage(image, key: key, state: .selected)
        
        XCTAssertTrue(sut.image(for: .selected)?.isEqualPixelByPixel(expectedImage) == true)
        XCTAssertTrue(sut.hnk_imageFetcher == nil)
    }
    
    func testSetImage_UsingPlaceholder_MemoryMiss_UIControlStateDisabled() {
        let placeholder = UIImage.imageWithColor(UIColor.yellow)
        let image = UIImage.imageWithColor(UIColor.green)
        let key = self.name!
        
        sut.hnk_setImage(image, key: key, state: .disabled, placeholder: placeholder)
        
        XCTAssertEqual(sut.image(for: .disabled)!, placeholder)
        XCTAssertEqual(sut.hnk_imageFetcher.key, key)
    }
    
    func testSetImage_UsingPlaceholder_MemoryHit_UIControlStateNormal() {
        let placeholder = UIImage.imageWithColor(UIColor.yellow)
        let image = UIImage.imageWithColor(UIColor.green)
        let key = self.name!
        let expectedImage = setImage(image, key: key, format: sut.hnk_imageFormat)
        
        sut.hnk_setImage(image, key: key, placeholder: placeholder)
        
        XCTAssertTrue(sut.image(for: UIControlState())?.isEqualPixelByPixel(expectedImage) == true)
        XCTAssertTrue(sut.hnk_imageFetcher == nil)
    }
    
    func testSetImage_UsingFormat_UIControlStateHighlighted() {
        let image = UIImage.imageWithColor(UIColor.red)
        let expectedImage = UIImage.imageWithColor(UIColor.green)
        let format = Format<UIImage>(name: self.name!, diskCapacity: 0) { _ in return expectedImage }
        let key = self.name!
        let expectation = self.expectation(description: self.name!)
        
        sut.hnk_setImage(image, key: key, state: .highlighted, format: format, success:{resultImage in
            XCTAssertTrue(resultImage.isEqualPixelByPixel(expectedImage))
            expectation.fulfill()
        })
        
        self.waitForExpectations(timeout: 1, handler: nil)
    }
    
    // MARK: setImageFromFile
    
    func testSetImageFromFile_MemoryMiss_UIControlStateSelected() {
        let fetcher = DiskFetcher<UIImage>(path: self.uniquePath())
        
        sut.hnk_setImageFromFile(fetcher.key, state: .selected)
        
        XCTAssertNil(sut.image(for: .selected))
        XCTAssertEqual(sut.hnk_imageFetcher.key, fetcher.key)
    }
    
    func testSetImageFromFile_MemoryHit_UIControlStateNormal() {
        let image = UIImage.imageWithColor(UIColor.orange)
        let fetcher = DiskFetcher<UIImage>(path: self.uniquePath())
        let expectedImage = setImage(image, key: fetcher.key, format: sut.hnk_imageFormat)
        
        sut.hnk_setImageFromFile(fetcher.key)
        
        XCTAssertTrue(sut.image(for: UIControlState())?.isEqualPixelByPixel(expectedImage) == true)
        XCTAssertTrue(sut.hnk_imageFetcher == nil)
    }
    
    func testSetImageFromFileSuccessFailure_MemoryHit_UIControlStateSelected() {
        let image = UIImage.imageWithColor(UIColor.green)
        let fetcher = DiskFetcher<UIImage>(path: self.uniquePath())
        let cache = Shared.imageCache
        let format = sut.hnk_imageFormat
        cache.set(value: image, key: fetcher.key, formatName: format.name)
        
        sut.hnk_setImageFromFile(fetcher.key, state: .selected, failure: {error in
            XCTFail("")
            }){result in
                XCTAssertTrue(result.isEqualPixelByPixel(image))
        }
    }
    
    // MARK: setImageFromURL
    
    func testSetImageFromURL_MemoryMiss_UIControlStateSelected() {
        let URL = Foundation.URL(string: "http://haneke.io")!
        let fetcher = NetworkFetcher<UIImage>(URL: URL)
        
        sut.hnk_setImageFromURL(URL, state: .selected)
        
        XCTAssertNil(sut.image(for: .selected))
        XCTAssertEqual(sut.hnk_imageFetcher.key, fetcher.key)
    }
    
    func testSetImageFromURL_MemoryHit_UIControlStateNormal() {
        let image = UIImage.imageWithColor(UIColor.orange)
        let URL = Foundation.URL(string: "http://haneke.io")!
        let fetcher = NetworkFetcher<UIImage>(URL: URL)
        let expectedImage = setImage(image, key: fetcher.key, format: sut.hnk_imageFormat)
        
        sut.hnk_setImageFromURL(URL)
        
        XCTAssertTrue(sut.image(for: UIControlState())?.isEqualPixelByPixel(expectedImage) == true)
        XCTAssertTrue(sut.hnk_imageFetcher == nil)
    }
    
    func testSetImageFromURLSuccessFailure_MemoryHit_UIControlStateSelected() {
        let image = UIImage.imageWithColor(UIColor.green)
        let URL = Foundation.URL(string: "http://haneke.io")!
        let fetcher = NetworkFetcher<UIImage>(URL: URL)
        let cache = Shared.imageCache
        let format = sut.hnk_imageFormat
        cache.set(value: image, key: fetcher.key, formatName: format.name)
        
        sut.hnk_setImageFromURL(URL, state: .selected, failure: {error in
            XCTFail("")
            }){result in
                XCTAssertTrue(result.isEqualPixelByPixel(image))
        }
    }
    
    func testSetImageFromURL_Failure_UIControlStateNormal() {
        OHHTTPStubs.stubRequestsPassingTest({ _ in
            return true
            }, withStubResponse: { _ in
                let data = Data.dataWithLength(100)
                return OHHTTPStubsResponse(data: data, statusCode: 404, headers:nil)
        })
        let URL = Foundation.URL(string: "http://haneke.io")!
        let fetcher = NetworkFetcher<UIImage>(URL: URL)
        let expectation = self.expectation(description: self.name!)
        
        sut.hnk_setImageFromURL(URL, failure:{error in
            XCTAssertEqual(error!.domain, HanekeGlobals.Domain)
            expectation.fulfill()
        })
        
        XCTAssertNil(sut.image(for: UIControlState()))
        XCTAssertEqual(sut.hnk_imageFetcher.key, fetcher.key)
        self.waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testSetImageFromURL_UsingFormat() {
        let image = UIImage.imageWithColor(UIColor.red)
        let expectedImage = UIImage.imageWithColor(UIColor.green)
        let format = Format<UIImage>(name: self.name!, diskCapacity: 0) { _ in return expectedImage }
        OHHTTPStubs.stubRequestsPassingTest({ _ in
            return true
            }, withStubResponse: { _ in
                let data = UIImagePNGRepresentation(image)
                return OHHTTPStubsResponse(data: data!, statusCode: 200, headers:nil)
        })
        let URL = Foundation.URL(string: "http://haneke.io")!
        let expectation = self.expectation(description: self.name!)
        
        sut.hnk_setImageFromURL(URL, format: format, success:{resultImage in
            XCTAssertTrue(resultImage.isEqualPixelByPixel(expectedImage))
            expectation.fulfill()
        })
        
        self.waitForExpectations(timeout: 1, handler: nil)
    }
    
    // MARK: setImageFromFetcher

    func testSetImageFromFetcher_Hit_Animated_UIControlStateSelected() {
        let image = UIImage.imageWithColor(UIColor.green)
        let key = self.name!
        let fetcher = AsyncFetcher<UIImage>(key: key, value: image)
        let expectedImage = sut.hnk_imageFormat.apply(image)

        sut.hnk_setImageFromFetcher(fetcher, state: .selected)
        XCTAssertTrue(sut.hnk_imageFetcher === fetcher)
        XCTAssertNil(sut.image(for: .selected))

        self.wait(1) {
            return self.sut.image(for: .selected) != nil
        }

        XCTAssertTrue(sut.image(for: .selected)?.isEqualPixelByPixel(expectedImage) == true)
        XCTAssertNil(sut.hnk_imageFetcher)
    }
    
    func testSetImageFromFetcher_MemoryMiss_UIControlStateSelected() {
        let image = UIImage.imageWithColor(UIColor.green)
        let key = self.name!
        let fetcher = SimpleFetcher<UIImage>(key: key, value: image)
        
        sut.hnk_setImageFromFetcher(fetcher, state: .selected)
        
        XCTAssertNil(sut.image(for: .selected))
        XCTAssertTrue(sut.hnk_imageFetcher === fetcher)
    }
    
    func testSetImageFromFetcher_MemoryHit_UIControlStateNormal() {
        let image = UIImage.imageWithColor(UIColor.green)
        let key = self.name!
        let fetcher = SimpleFetcher<UIImage>(key: key, value: image)
        let expectedImage = setImage(image, key: key, format: sut.hnk_imageFormat)
        
        sut.hnk_setImageFromFetcher(fetcher)
        
        XCTAssertTrue(sut.image(for: UIControlState())?.isEqualPixelByPixel(expectedImage) == true)
        XCTAssertTrue(sut.hnk_imageFetcher == nil)
    }
    
    func testSetImageFromFetcherSuccessFailure_MemoryHit_UIControlStateNormal() {
        let image = UIImage.imageWithColor(UIColor.green)
        let key = self.name!
        let fetcher = SimpleFetcher<UIImage>(key: key, value: image)
        let cache = Shared.imageCache
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
        let URL = Foundation.URL(string: "http://imgs.xkcd.com/comics/election.png")!
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
        let URL = Foundation.URL(string: "http://imgs.xkcd.com/comics/election.png")!
        sut.hnk_setImageFromURL(URL, state: .highlighted, success: { _ in
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
        let formatSize = sut.contentRect(forBounds: sut.bounds).size
        let format = sut.hnk_backgroundImageFormat
        let resizer = ImageResizer(size: formatSize, scaleMode: .Fill, allowUpscaling: true, compressionQuality: HanekeGlobals.UIKit.DefaultFormat.CompressionQuality)
        let image = UIImage.imageWithColor(UIColor.red)
        
        XCTAssertEqual(format.diskCapacity, HanekeGlobals.UIKit.DefaultFormat.DiskCapacity)
        let result = format.apply(image)
        let expected = resizer.resizeImage(image)
        XCTAssertTrue(result.isEqualPixelByPixel(expected))
    }

    // MARK: setBackgroundImage
    
    func testSetBackgroundImage_MemoryMiss_UIControlStateNormal() {
        let image = UIImage.imageWithColor(UIColor.green)
        let key = self.name!
        
        sut.hnk_setBackgroundImage(image, key: key)
        
        XCTAssertNil(sut.backgroundImage(for: UIControlState()))
        XCTAssertEqual(sut.hnk_backgroundImageFetcher.key, key)
    }

    func testSetBackgroundImage_MemoryHit_UIControlStateSelected() {
        let image = UIImage.imageWithColor(UIColor.green)
        let key = self.name!
        let expectedImage = setImage(image, key: key, format: sut.hnk_backgroundImageFormat)
        
        sut.hnk_setBackgroundImage(image, key: key, state: .selected)
        
        let result = sut.backgroundImage(for: .selected)
        XCTAssertTrue(result?.isEqualPixelByPixel(expectedImage) == true)
        XCTAssertTrue(sut.hnk_backgroundImageFetcher == nil)
    }

    func testSetBackgroundImage_UsingPlaceholder_MemoryMiss_UIControlStateDisabled() {
        let placeholder = UIImage.imageWithColor(UIColor.yellow)
        let image = UIImage.imageWithColor(UIColor.green)
        let key = self.name!
        
        sut.hnk_setBackgroundImage(image, key: key, state: .disabled, placeholder: placeholder)
        
        XCTAssertEqual(sut.backgroundImage(for: .disabled)!, placeholder)
        XCTAssertEqual(sut.hnk_backgroundImageFetcher.key, key)
    }

    func testSetBackgroundImage_UsingPlaceholder_MemoryHit_UIControlStateNormal() {
        let placeholder = UIImage.imageWithColor(UIColor.yellow)
        let image = UIImage.imageWithColor(UIColor.green)
        let key = self.name!
        let expectedImage = setImage(image, key: key, format: sut.hnk_backgroundImageFormat)
        
        sut.hnk_setBackgroundImage(image, key: key, placeholder: placeholder)
        
        let result = sut.backgroundImage(for: UIControlState())
        XCTAssertTrue(result?.isEqualPixelByPixel(expectedImage) == true)
        XCTAssertTrue(sut.hnk_backgroundImageFetcher == nil)
    }
   
    func testSetBackgroundImage_UsingFormat_UIControlStateHighlighted() {
        let image = UIImage.imageWithColor(UIColor.red)
        let expectedImage = UIImage.imageWithColor(UIColor.green)
        let key = self.name!
        let format = Format<UIImage>(name: key, diskCapacity: 0) { _ in return expectedImage }
        let expectation = self.expectation(description: key)
        
        sut.hnk_setBackgroundImage(image, key: key, state: .highlighted, format: format, success:{resultImage in
            XCTAssertTrue(resultImage.isEqualPixelByPixel(expectedImage))
            expectation.fulfill()
        })
        
        self.waitForExpectations(timeout: 1, handler: nil)
    }
    
    // MARK: setBackgroundImageFromFile
    
    func testSetBackgroundImageFromFile_MemoryMiss_UIControlStateSelected() {
        let fetcher = DiskFetcher<UIImage>(path: self.uniquePath())
        
        sut.hnk_setBackgroundImageFromFile(fetcher.key, state: .selected)
        
        XCTAssertNil(sut.backgroundImage(for: .selected))
        XCTAssertEqual(sut.hnk_backgroundImageFetcher.key, fetcher.key)
    }
    
    func testSetBackgroundImageFromFile_MemoryHit_UIControlStateNormal() {
        let image = UIImage.imageWithColor(UIColor.orange)
        let fetcher = DiskFetcher<UIImage>(path: self.uniquePath())
        let expectedImage = setImage(image, key: fetcher.key, format: sut.hnk_backgroundImageFormat)
        
        sut.hnk_setBackgroundImageFromFile(fetcher.key)
        
        let result = sut.backgroundImage(for: UIControlState())
        XCTAssertTrue(result?.isEqualPixelByPixel(expectedImage) == true)
        XCTAssertTrue(sut.hnk_backgroundImageFetcher == nil)
    }
    
    func testSetBackgroundImageFromFileSuccessFailure_MemoryHit_UIControlStateSelected() {
        let image = UIImage.imageWithColor(UIColor.green)
        let fetcher = DiskFetcher<UIImage>(path: self.uniquePath())
        let cache = Shared.imageCache
        let format = sut.hnk_backgroundImageFormat
        cache.set(value: image, key: fetcher.key, formatName: format.name)
        
        sut.hnk_setBackgroundImageFromFile(fetcher.key, state: .selected, failure: {error in
            XCTFail("")
            }){result in
                XCTAssertTrue(result.isEqualPixelByPixel(image))
        }
    }
    
    // MARK: setBackgroundImageFromURL

    func testSetBackgroundImageFromURL_MemoryMiss_UIControlStateSelected() {
        let URL = Foundation.URL(string: "http://haneke.io")!
        let fetcher = NetworkFetcher<UIImage>(URL: URL)
        
        sut.hnk_setBackgroundImageFromURL(URL, state: .selected)
        
        XCTAssertNil(sut.backgroundImage(for: .selected))
        XCTAssertEqual(sut.hnk_backgroundImageFetcher.key, fetcher.key)
    }
    
    func testSetBackgroundImageFromURL_MemoryHit_UIControlStateNormal() {
        let image = UIImage.imageWithColor(UIColor.orange)
        let URL = Foundation.URL(string: "http://haneke.io")!
        let fetcher = NetworkFetcher<UIImage>(URL: URL)
        let expectedImage = setImage(image, key: fetcher.key, format: sut.hnk_backgroundImageFormat)
        
        sut.hnk_setBackgroundImageFromURL(URL)
        
        let result = sut.backgroundImage(for: UIControlState())
        XCTAssertTrue(result?.isEqualPixelByPixel(expectedImage) == true)
        XCTAssertTrue(sut.hnk_backgroundImageFetcher == nil)
    }
    
    func testSetBackgroundImageFromURLSuccessFailure_MemoryHit_UIControlStateSelected() {
        let image = UIImage.imageWithColor(UIColor.green)
        let URL = Foundation.URL(string: "http://haneke.io")!
        let fetcher = NetworkFetcher<UIImage>(URL: URL)
        let cache = Shared.imageCache
        let format = sut.hnk_backgroundImageFormat
        cache.set(value: image, key: fetcher.key, formatName: format.name)
        
        sut.hnk_setBackgroundImageFromURL(URL, state: .selected, failure: {error in
            XCTFail("")
            }){result in
                XCTAssertTrue(result.isEqualPixelByPixel(image))
        }
    }

    func testSetBackgroundImageFromURL_Failure_UIControlStateNormal() {
        OHHTTPStubs.stubRequestsPassingTest({ _ in
            return true
            }, withStubResponse: { _ in
                let data = Data.dataWithLength(100)
                return OHHTTPStubsResponse(data: data, statusCode: 404, headers:nil)
        })
        let URL = Foundation.URL(string: "http://haneke.io")!
        let fetcher = NetworkFetcher<UIImage>(URL: URL)
        let expectation = self.expectation(description: self.name!)
        
        sut.hnk_setBackgroundImageFromURL(URL, failure:{error in
            XCTAssertEqual(error!.domain, HanekeGlobals.Domain)
            expectation.fulfill()
        })
        
        XCTAssertNil(sut.backgroundImage(for: UIControlState()))
        XCTAssertEqual(sut.hnk_backgroundImageFetcher.key, fetcher.key)
        self.waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testSetBackgroundImageFromURL_UsingFormat() {
        let image = UIImage.imageWithColor(UIColor.red)
        let expectedImage = UIImage.imageWithColor(UIColor.green)
        let format = Format<UIImage>(name: self.name!, diskCapacity: 0) { _ in return expectedImage }
        OHHTTPStubs.stubRequestsPassingTest({ _ in
            return true
            }, withStubResponse: { _ in
                let data = UIImagePNGRepresentation(image)
                return OHHTTPStubsResponse(data: data!, statusCode: 200, headers:nil)
        })
        let URL = Foundation.URL(string: "http://haneke.io")!
        let expectation = self.expectation(description: self.name!)
        
        sut.hnk_setBackgroundImageFromURL(URL, format: format, success:{resultImage in
            XCTAssertTrue(resultImage.isEqualPixelByPixel(expectedImage))
            expectation.fulfill()
        })
        
        self.waitForExpectations(timeout: 1, handler: nil)
    }
    
    // MARK: setBackgroundImageFromFetcher

    func testSetBackgroundImageFromFetcher_Hit_Animated_UIControlStateSelected() {
        let image = UIImage.imageWithColor(UIColor.green)
        let key = self.name!
        let fetcher = AsyncFetcher<UIImage>(key: key, value: image)
        let expectedImage = sut.hnk_backgroundImageFormat.apply(image)

        sut.hnk_setBackgroundImageFromFetcher(fetcher, state: .selected)
        XCTAssertTrue(sut.hnk_backgroundImageFetcher === fetcher)
        XCTAssertNil(sut.backgroundImage(for: .selected))

        self.wait(1) {
            return self.sut.backgroundImage(for: .selected) != nil
        }

        XCTAssertTrue(sut.backgroundImage(for: .selected)?.isEqualPixelByPixel(expectedImage) == true)
        XCTAssertNil(sut.hnk_backgroundImageFetcher)
    }
    
    func testSetBackgroundImageFromFetcher_MemoryMiss_UIControlStateSelected() {
        let image = UIImage.imageWithColor(UIColor.green)
        let key = self.name!
        let fetcher = SimpleFetcher<UIImage>(key: key, value: image)
        
        sut.hnk_setBackgroundImageFromFetcher(fetcher, state: .selected)
        
        XCTAssertNil(sut.backgroundImage(for: .selected))
        XCTAssertTrue(sut.hnk_backgroundImageFetcher === fetcher)
    }
    
    func testSetBackgroundImageFromFetcher_MemoryHit_UIControlStateNormal() {
        let image = UIImage.imageWithColor(UIColor.green)
        let key = self.name!
        let fetcher = SimpleFetcher<UIImage>(key: key, value: image)
        let expectedImage = setImage(image, key: key, format: sut.hnk_backgroundImageFormat)
        
        sut.hnk_setBackgroundImageFromFetcher(fetcher)

        let result = sut.backgroundImage(for: UIControlState())
        XCTAssertTrue(result?.isEqualPixelByPixel(expectedImage) == true)
        XCTAssertTrue(sut.hnk_backgroundImageFetcher == nil)
    }
    
    func testSetBackgroundImageFromFetcherSuccessFailure_MemoryHit_UIControlStateNormal() {
        let image = UIImage.imageWithColor(UIColor.green)
        let key = self.name!
        let fetcher = SimpleFetcher<UIImage>(key: key, value: image)
        let cache = Shared.imageCache
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
        let URL = Foundation.URL(string: "http://imgs.xkcd.com/comics/election.png")!
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
        let URL = Foundation.URL(string: "http://imgs.xkcd.com/comics/election.png")!
        sut.hnk_setBackgroundImageFromURL(URL, state: .highlighted, success: { _ in
            XCTFail("unexpected success")
            }, failure: { _ in
                XCTFail("unexpected failure")
        })
        
        sut.hnk_cancelSetBackgroundImage()
        
        XCTAssertTrue(sut.hnk_backgroundImageFetcher == nil)
        self.waitFor(0.1)
    }
    
    // MARK: Helpers
    
    func setImage(_ image : UIImage, key: String, format : Format<UIImage>) -> UIImage {
        let expectedImage = format.apply(image)
        let cache = Shared.imageCache
        cache.addFormat(format)
        let expectation = self.expectation(description: "set")
        cache.set(value: image, key: key, formatName: format.name) { _ in
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 1, handler: nil)
        return expectedImage
    }
    
}
