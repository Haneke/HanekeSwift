//
//  UIImageView+HanekeTests.swift
//  Haneke
//
//  Created by Hermes Pique on 9/17/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import UIKit
import XCTest
import OHHTTPStubs
@testable import Haneke

class UIImageView_HanekeTests: DiskTestCase {

    var sut : UIImageView!
    
    override func setUp() {
        super.setUp()
        sut = UIImageView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
    }
    
    override func tearDown() {
        OHHTTPStubs.removeAllStubs()
        
        let cache = Shared.imageCache
        cache.removeAll()
        super.tearDown()
    }
    
    func testScaleMode_ScaleToFill() {
        sut.contentMode = .scaleToFill
        XCTAssertEqual(sut.hnk_scaleMode, ImageResizer.ScaleMode.Fill)
    }
    
    func testScaleMode_ScaleAspectFit() {
        sut.contentMode = .scaleAspectFit
        XCTAssertEqual(sut.hnk_scaleMode, ImageResizer.ScaleMode.AspectFit)
    }
    
    func testScaleMode_ScaleAspectFill() {
        sut.contentMode = .scaleAspectFill
        XCTAssertEqual(sut.hnk_scaleMode, ImageResizer.ScaleMode.AspectFill)
    }
    
    func testScaleMode_Redraw() {
        sut.contentMode = .redraw
        XCTAssertEqual(sut.hnk_scaleMode, ImageResizer.ScaleMode.None)
    }
    
    func testScaleMode_Center() {
        sut.contentMode = .center
        XCTAssertEqual(sut.hnk_scaleMode, ImageResizer.ScaleMode.None)
    }
    
    func testScaleMode_Top() {
        sut.contentMode = .top
        XCTAssertEqual(sut.hnk_scaleMode, ImageResizer.ScaleMode.None)
    }
    
    func testScaleMode_Bottom() {
        sut.contentMode = .bottom
        XCTAssertEqual(sut.hnk_scaleMode, ImageResizer.ScaleMode.None)
    }
    
    func testScaleMode_Left() {
        sut.contentMode = .left
        XCTAssertEqual(sut.hnk_scaleMode, ImageResizer.ScaleMode.None)
    }
    
    func testScaleMode_Right() {
        sut.contentMode = .right
        XCTAssertEqual(sut.hnk_scaleMode, ImageResizer.ScaleMode.None)
    }
    
    func testScaleMode_TopLeft() {
        sut.contentMode = .topLeft
        XCTAssertEqual(sut.hnk_scaleMode, ImageResizer.ScaleMode.None)
    }
    
    func testScaleMode_TopRight() {
        sut.contentMode = .topRight
        XCTAssertEqual(sut.hnk_scaleMode, ImageResizer.ScaleMode.None)
    }
    
    func testScaleMode_BottomLeft() {
        sut.contentMode = .bottomLeft
        XCTAssertEqual(sut.hnk_scaleMode, ImageResizer.ScaleMode.None)
    }
    
    func testScaleMode_BottomRight() {
        sut.contentMode = .bottomRight
        XCTAssertEqual(sut.hnk_scaleMode, ImageResizer.ScaleMode.None)
    }
    
    func testFormatWithSize() {
        let size = CGSize(width: 10, height: 20)
        let scaleMode = ImageResizer.ScaleMode.Fill
        let image = UIImage.imageWithColor(UIColor.red)
        let resizer = ImageResizer(size: size, scaleMode: scaleMode, allowUpscaling: true, compressionQuality: HanekeGlobals.UIKit.DefaultFormat.CompressionQuality)
        
        let format = HanekeGlobals.UIKit.formatWithSize(size, scaleMode: scaleMode)
        
        XCTAssertEqual(format.diskCapacity, HanekeGlobals.UIKit.DefaultFormat.DiskCapacity)
        let result = format.apply(image)
        let expected = resizer.resizeImage(image)
        XCTAssertTrue(result.isEqualPixelByPixel(expected))
    }
    
    func testFormat_Default() {
        let cache = Shared.imageCache
        let resizer = ImageResizer(size: sut.bounds.size, scaleMode: sut.hnk_scaleMode, allowUpscaling: true, compressionQuality: HanekeGlobals.UIKit.DefaultFormat.CompressionQuality)
        let image = UIImage.imageWithColor(UIColor.green)
        
        let format = sut.hnk_format
        
        XCTAssertEqual(format.diskCapacity, HanekeGlobals.UIKit.DefaultFormat.DiskCapacity)
        XCTAssertTrue(cache.formats[format.name] != nil) // Can't use XCTAssertNotNil because it expects AnyObject
        let result = format.apply(image)
        let expected = resizer.resizeImage(image)
        XCTAssertTrue(result.isEqualPixelByPixel(expected))
    }

    // MARK: setImage

    func testSetImage_MemoryMiss() {
        let image = UIImage.imageWithColor(UIColor.green)
        let key = self.name!
        
        sut.hnk_setImage(image, key: key)
        
        XCTAssertNil(sut.image)
        XCTAssertEqual(sut.hnk_fetcher.key, key)
    }
    
    func testSetImage_MemoryHit() {
        let image = UIImage.imageWithColor(UIColor.green)
        let key = self.name!
        let expectedImage = setImage(image, key: key)
        
        sut.hnk_setImage(image, key: key)
        
        XCTAssertTrue(sut.image?.isEqualPixelByPixel(expectedImage) == true)
        XCTAssertTrue(sut.hnk_fetcher == nil)
    }
    
    func testSetImage_ImageSet_MemoryMiss() {
        let previousImage = UIImage.imageWithColor(UIColor.red)
        let image = UIImage.imageWithColor(UIColor.green)
        let key = self.name!
        sut.image = previousImage
        
        sut.hnk_setImage(image, key: key)
        
        XCTAssertEqual(sut.image!, previousImage)
        XCTAssertEqual(sut.hnk_fetcher.key, key)
    }
    
    func testSetImage_UsingPlaceholder_MemoryMiss() {
        let placeholder = UIImage.imageWithColor(UIColor.yellow)
        let image = UIImage.imageWithColor(UIColor.green)
        let key = self.name!
        
        sut.hnk_setImage(image, key: key, placeholder: placeholder)
        
        XCTAssertEqual(sut.image!, placeholder)
        XCTAssertEqual(sut.hnk_fetcher.key, key)
    }
    
    func testSetImage_UsingPlaceholder_MemoryHit() {
        let placeholder = UIImage.imageWithColor(UIColor.yellow)
        let image = UIImage.imageWithColor(UIColor.green)
        let key = self.name!
        let expectedImage = setImage(image, key: key)
        
        sut.hnk_setImage(image, key: key, placeholder: placeholder)
        
        XCTAssertTrue(sut.image?.isEqualPixelByPixel(expectedImage) == true)
        XCTAssertTrue(sut.hnk_fetcher == nil)
    }
    
    func testSetImage_Success() {
        let image = UIImage.imageWithColor(UIColor.green)
        let key = self.name!
        sut.contentMode = .center // No resizing
        let expectation = self.expectation(description: key)
        
        sut.hnk_setImage(image, key: key, success:{resultImage in
            XCTAssertTrue(resultImage.isEqualPixelByPixel(image))
            expectation.fulfill()
        })
        
        XCTAssertNil(sut.image)
        XCTAssertEqual(sut.hnk_fetcher.key, key)
        self.waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testSetImage_UsingFormat() {
        let image = UIImage.imageWithColor(UIColor.red)
        let expectedImage = UIImage.imageWithColor(UIColor.green)
        let key = self.name!
        let format = Format<UIImage>(name: key, diskCapacity: 0) { _ in return expectedImage }
        let expectation = self.expectation(description: key)
        
        sut.hnk_setImage(image, key: key, format: format, success:{resultImage in
            XCTAssertTrue(resultImage.isEqualPixelByPixel(expectedImage))
            expectation.fulfill()
        })
        
        self.waitForExpectations(timeout: 1, handler: nil)
    }
    
    // MARK: setImageFromFetcher

    func testSetImageFromFetcher_MemoryMiss() {
        let image = UIImage.imageWithColor(UIColor.green)
        let key = self.name!
        let fetcher = SimpleFetcher<UIImage>(key: key, value: image)
        
        sut.hnk_setImageFromFetcher(fetcher)

        XCTAssertNil(sut.image)
        XCTAssertTrue(sut.hnk_fetcher === fetcher)
    }
    
    func testSetImageFromFetcher_MemoryHit() {
        let image = UIImage.imageWithColor(UIColor.green)
        let key = self.name!
        let fetcher = SimpleFetcher<UIImage>(key: key, value: image)
        let expectedImage = setImage(image, key: key)
        
        sut.hnk_setImageFromFetcher(fetcher)
        
        XCTAssertTrue(sut.image?.isEqualPixelByPixel(expectedImage) == true)
        XCTAssertTrue(sut.hnk_fetcher == nil)
    }

    func testSetImageFromFetcher_Hit_Animated() {
        let image = UIImage.imageWithColor(UIColor.green)
        let key = self.name!
        let fetcher = AsyncFetcher<UIImage>(key: key, value: image)
        let expectedImage = sut.hnk_format.apply(image)

        sut.hnk_setImageFromFetcher(fetcher)
        XCTAssertTrue(sut.hnk_fetcher === fetcher)
        XCTAssertNil(sut.image)

        self.wait(1) {
            return self.sut.image != nil
        }

        XCTAssertTrue(sut.image?.isEqualPixelByPixel(expectedImage) == true)
        XCTAssertNil(sut.hnk_fetcher)
    }
    
    func testSetImageFromFetcher_ImageSet_MemoryMiss() {
        let previousImage = UIImage.imageWithColor(UIColor.red)
        let image = UIImage.imageWithColor(UIColor.green)
        let key = self.name!
        let fetcher = SimpleFetcher<UIImage>(key: key, value: image)
        sut.image = previousImage
        
        sut.hnk_setImageFromFetcher(fetcher)
        
        XCTAssertEqual(sut.image!, previousImage)
        XCTAssertTrue(sut.hnk_fetcher === fetcher)
    }

    func testSetImageFromFetcher_UsingPlaceholder_MemoryMiss() {
        let placeholder = UIImage.imageWithColor(UIColor.yellow)
        let image = UIImage.imageWithColor(UIColor.green)
        let key = self.name!
        let fetcher = SimpleFetcher<UIImage>(key: key, value: image)
        
        sut.hnk_setImageFromFetcher(fetcher, placeholder:placeholder)
        
        XCTAssertEqual(sut.image!, placeholder)
        XCTAssertTrue(sut.hnk_fetcher === fetcher)
    }
    
    func testSetImageFromFetcher_UsingPlaceholder_MemoryHit() {
        let placeholder = UIImage.imageWithColor(UIColor.yellow)
        let image = UIImage.imageWithColor(UIColor.green)
        let key = self.name!
        let fetcher = SimpleFetcher<UIImage>(key: key, value: image)
        let expectedImage = setImage(image, key: key)
        
        sut.hnk_setImageFromFetcher(fetcher, placeholder:placeholder)
        
        XCTAssertTrue(sut.image?.isEqualPixelByPixel(expectedImage) == true)
        XCTAssertTrue(sut.hnk_fetcher == nil)
    }
    
    func testSetImageFromFetcher_Success() {
        let image = UIImage.imageWithColor(UIColor.green)
        let key = self.name!
        let fetcher = SimpleFetcher<UIImage>(key: key, value: image)
        sut.contentMode = .center // No resizing
        let expectation = self.expectation(description: key)
        
        sut.hnk_setImageFromFetcher(fetcher, success: { resultImage in
            XCTAssertTrue(resultImage.isEqualPixelByPixel(image))
            expectation.fulfill()
        })
        
        XCTAssertNil(sut.image)
        XCTAssertTrue(sut.hnk_fetcher === fetcher)
        self.waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testSetImageFromFetcher_Failure() {
        let key = self.name!
        let fetcher = MockFetcher<UIImage>(key: key)
        let expectation = self.expectation(description: key)
        
        sut.hnk_setImageFromFetcher(fetcher, failure: {error in
            XCTAssertEqual(error!.domain, HanekeGlobals.Domain)
            expectation.fulfill()
        })
        
        XCTAssertNil(sut.image)
        XCTAssertTrue(sut.hnk_fetcher === fetcher)
        self.waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testSetImageFromFetcher_UsingFormat() {
        let image = UIImage.imageWithColor(UIColor.red)
        let expectedImage = UIImage.imageWithColor(UIColor.green)
        let key = self.name!
        let format = Format<UIImage>(name: key, diskCapacity: 0) { _ in return expectedImage }
        let fetcher = SimpleFetcher<UIImage>(key: key, value: image)
        let expectation = self.expectation(description: key)
        
        sut.hnk_setImageFromFetcher(fetcher, format: format, success: { resultImage in
            XCTAssertTrue(resultImage.isEqualPixelByPixel(expectedImage))
            expectation.fulfill()
        })
        
        self.waitForExpectations(timeout: 1, handler: nil)
    }
    
    // MARK: setImageFromFile
    
    func testSetImageFromFile_MemoryMiss() {
        let fetcher = DiskFetcher<UIImage>(path: self.uniquePath())
        
        sut.hnk_setImageFromFile(fetcher.key)
        
        XCTAssertNil(sut.image)
        XCTAssertEqual(sut.hnk_fetcher.key, fetcher.key)
    }
    
    func testSetImageFromFile_MemoryHit() {
        let image = UIImage.imageWithColor(UIColor.orange)
        let fetcher = DiskFetcher<UIImage>(path: self.uniquePath())
        let expectedImage = setImage(image, key: fetcher.key)
        
        sut.hnk_setImageFromFile(fetcher.key)
        
        XCTAssertTrue(sut.image?.isEqualPixelByPixel(expectedImage) == true)
        XCTAssertTrue(sut.hnk_fetcher == nil)
    }
    
    func testSetImageFromFileSuccessFailure_MemoryHit() {
        let image = UIImage.imageWithColor(UIColor.green)
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
        let URL = Foundation.URL(string: "http://haneke.io")!
        let fetcher = NetworkFetcher<UIImage>(URL: URL)
        
        sut.hnk_setImageFromURL(URL)
        
        XCTAssertNil(sut.image)
        XCTAssertEqual(sut.hnk_fetcher.key, fetcher.key)
    }
    
    func testSetImageFromURL_MemoryHit() {
        let image = UIImage.imageWithColor(UIColor.green)
        let URL = Foundation.URL(string: "http://haneke.io")!
        let fetcher = NetworkFetcher<UIImage>(URL: URL)
        let expectedImage = setImage(image, key: fetcher.key)
        
        sut.hnk_setImageFromURL(URL)
        
        XCTAssertTrue(sut.image?.isEqualPixelByPixel(expectedImage) == true)
        XCTAssertTrue(sut.hnk_fetcher == nil)
    }
    
    func testSetImageFromURL_ImageSet_MemoryMiss() {
        let previousImage = UIImage.imageWithColor(UIColor.red)
        let URL = Foundation.URL(string: "http://haneke.io")!
        let fetcher = NetworkFetcher<UIImage>(URL: URL)
        sut.image = previousImage
        
        sut.hnk_setImageFromURL(URL)
        
        XCTAssertEqual(sut.image!, previousImage)
        XCTAssertEqual(sut.hnk_fetcher.key, fetcher.key)
    }
    
    func testSetImageFromURL_UsingPlaceholder_MemoryMiss() {
        let placeholder = UIImage.imageWithColor(UIColor.yellow)
        let URL = Foundation.URL(string: "http://haneke.io")!
        let fetcher = NetworkFetcher<UIImage>(URL: URL)
        
        sut.hnk_setImageFromURL(URL, placeholder: placeholder)
        
        XCTAssertEqual(sut.image!, placeholder)
        XCTAssertEqual(sut.hnk_fetcher.key, fetcher.key)
    }
    
    func testSetImageFromURL_UsingPlaceholder_MemoryHit() {
        let placeholder = UIImage.imageWithColor(UIColor.yellow)
        let image = UIImage.imageWithColor(UIColor.green)
        let URL = Foundation.URL(string: "http://haneke.io")!
        let fetcher = NetworkFetcher<UIImage>(URL: URL)
        let expectedImage = setImage(image, key: fetcher.key)
        
        sut.hnk_setImageFromURL(URL, placeholder: placeholder)
        
        XCTAssertTrue(sut.image?.isEqualPixelByPixel(expectedImage) == true)
        XCTAssertTrue(sut.hnk_fetcher == nil)
    }
    
    func testSetImageFromURL_Success() {
        let image = UIImage.imageWithColor(UIColor.green)
        OHHTTPStubs.stubRequestsPassingTest({ _ in
            return true
            }, withStubResponse: { _ in
                let data = UIImagePNGRepresentation(image)
                return OHHTTPStubsResponse(data: data!, statusCode: 200, headers:nil)
        })
        let URL = Foundation.URL(string: "http://haneke.io")!
        let fetcher = NetworkFetcher<UIImage>(URL: URL)
        sut.contentMode = .center // No resizing
        let expectation = self.expectation(description: self.name!)
        
        sut.hnk_setImageFromURL(URL, success:{resultImage in
            XCTAssertTrue(resultImage.isEqualPixelByPixel(image))
            expectation.fulfill()
        })
        
        XCTAssertNil(sut.image)
        XCTAssertEqual(sut.hnk_fetcher.key, fetcher.key)
        self.waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testSetImageFromURL_WhenPreviousSetImageFromURL() {
        let image = UIImage.imageWithColor(UIColor.green)
        OHHTTPStubs.stubRequestsPassingTest({ _ in
            return true
            }, withStubResponse: { _ in
                let data = UIImagePNGRepresentation(image)
                return OHHTTPStubsResponse(data: data!, statusCode: 200, headers:nil).responseTime(0.1)
        })
        let URL1 = URL(string: "http://haneke.io/1.png")!
        sut.contentMode = .center // No resizing
        sut.hnk_setImageFromURL(URL1, success:{_ in
            XCTFail("unexpected success")
            }, failure:{_ in
            XCTFail("unexpected failure")
        })
        let URL2 = URL(string: "http://haneke.io/2.png")!
        let fetcher2 = NetworkFetcher<UIImage>(URL: URL2)
        let expectation = self.expectation(description: self.name!)
        
        sut.hnk_setImageFromURL(URL2, success:{resultImage in
            XCTAssertTrue(resultImage.isEqualPixelByPixel(image))
            expectation.fulfill()
        })
        
        XCTAssertNil(sut.image)
        XCTAssertEqual(sut.hnk_fetcher.key, fetcher2.key)
        self.waitForExpectations(timeout: 1, handler: nil)
    }
    
    func testSetImageFromURL_Failure() {
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
        
        XCTAssertNil(sut.image)
        XCTAssertEqual(sut.hnk_fetcher.key, fetcher.key)
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
    
    // MARK: cancelSetImage
    
    func testCancelSetImage() {
        sut.hnk_cancelSetImage()
        
        XCTAssertTrue(sut.hnk_fetcher == nil)
    }
    
    func testCancelSetImage_AfterSetImage() {
        let URL = Foundation.URL(string: "http://imgs.xkcd.com/comics/election.png")!
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
    
    func setImage(_ image : UIImage, key: String) -> UIImage {
        let format = sut.hnk_format
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

class MockFetcher<T : DataConvertible> : Fetcher<T> {
    
    override init(key: String) {
        super.init(key: key)
    }
    
    override func fetch(failure fail : ((Error?) -> ()), success succeed : (T.Result) -> ()) {
        let error = errorWithCode(0, description: "test")
        fail(error)
    }
    
    override func cancelFetch() {}
    
}
