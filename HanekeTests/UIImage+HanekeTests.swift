//
//  UIImage+HanekeTests.swift
//  Haneke
//
//  Created by Hermes Pique on 8/10/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import UIKit
import XCTest
import ImageIO
import MobileCoreServices

enum ExifOrientation : UInt32 {
    case Up = 1
    case Down = 3
    case Left = 8
    case Right = 6
    case UpMirrored = 2
    case DownMirrored = 4
    case LeftMirrored = 5
    case RightMirrored = 7
}

class UIImage_HanekeTests: XCTestCase {

    func testHasAlphaTrue() {
        let image = UIImage.imageWithColor(UIColor.redColor(), CGSize(width: 1, height: 1), false)
        XCTAssertTrue(image.hnk_hasAlpha())
    }
    
    func testHasAlphaFalse() {
        let image = UIImage.imageWithColor(UIColor.redColor(), CGSize(width: 1, height: 1), true)
        XCTAssertFalse(image.hnk_hasAlpha())
    }
    
    func testDataPNG() {
        let image = UIImage.imageWithColor(UIColor.redColor(), CGSize(width: 1, height: 1), false)
        let expectedData = UIImagePNGRepresentation(image)
        
        let data = image.hnk_data()
        
        XCTAssertEqual(data!, expectedData)
    }
    
    func testDataJPEG() {
        let image = UIImage.imageWithColor(UIColor.redColor(), CGSize(width: 1, height: 1), true)
        let expectedData = UIImageJPEGRepresentation(image, 1)
        
        let data = image.hnk_data()
        
        XCTAssertEqual(data!, expectedData)
    }
    
    func testDataNil() {
        let image = UIImage()

        XCTAssertNil(image.hnk_data())
    }
    
    func testDecompressedImage_UIGraphicsContext_Opaque() {
        let image = UIImage.imageWithColor(UIColor.redColor(), CGSizeMake(10, 10))

        let decompressedImage = image.hnk_decompressedImage()
        
        XCTAssertNotEqual(image, decompressedImage)
        XCTAssertTrue(decompressedImage.isEqualPixelByPixel(image))
    }
    
    func testDecompressedImage_UIGraphicsContext_NotOpaque() {
        let image = UIImage.imageWithColor(UIColor.redColor(), CGSizeMake(10, 10), false)
        
        let decompressedImage = image.hnk_decompressedImage()
        
        XCTAssertNotEqual(image, decompressedImage)
        XCTAssertTrue(decompressedImage.isEqualPixelByPixel(image))
    }
    
    func testDecompressedImage_RGBA() {
        let color = UIColor(red:255, green:0, blue:0, alpha:0.5)
        self._testDecompressedImageUsingColor(color: color, alphaInfo: .PremultipliedLast)
    }
    
    func testDecompressedImage_ARGB() {
        let color = UIColor(red:255, green:0, blue:0, alpha:0.5)
        self._testDecompressedImageUsingColor(color: color, alphaInfo: .PremultipliedFirst)
    }
    
    func testDecompressedImage_RGBX() {
        self._testDecompressedImageUsingColor(alphaInfo: .NoneSkipLast)
    }
    
    func testDecompressedImage_XRGB() {
        self._testDecompressedImageUsingColor(alphaInfo: .NoneSkipFirst)
    }
    
    func testDecompressedImage_Gray_AlphaNone() {
        let color = UIColor.grayColor()
        let colorSpaceRef = CGColorSpaceCreateDeviceGray()
        self._testDecompressedImageUsingColor(color: color, colorSpace: colorSpaceRef, alphaInfo: .None)
    }
    
    func testDecompressedImage_OrientationUp() {
        self._testDecompressedImageWithOrientation(.Up)
    }
    
    func testDecompressedImage_OrientationDown() {
        self._testDecompressedImageWithOrientation(.Down)
    }
    
    func testDecompressedImage_OrientationLeft() {
        self._testDecompressedImageWithOrientation(.Left)
    }
    
    func testDecompressedImage_OrientationRight() {
        self._testDecompressedImageWithOrientation(.Right)
    }
    
    func testDecompressedImage_OrientationUpMirrored() {
        self._testDecompressedImageWithOrientation(.UpMirrored)
    }
    
    func testDecompressedImage_OrientationDownMirrored() {
        self._testDecompressedImageWithOrientation(.DownMirrored)
    }
    
    func testDecompressedImage_OrientationLeftMirrored() {
        self._testDecompressedImageWithOrientation(.LeftMirrored)
    }
    
    func testDecompressedImage_OrientationRightMirrored() {
        self._testDecompressedImageWithOrientation(.RightMirrored)
    }
    
    func testDataCompressionQuality() {
        let image = UIImage.imageWithColor(UIColor.redColor(), CGSizeMake(10, 10))
        let data = image.hnk_data()
        let notExpectedData = image.hnk_data(compressionQuality: 0.5)
        
        XCTAssertNotEqual(data, notExpectedData)
    }
    
    func testDataCompressionQuality_LessThan0() {
        let image = UIImage.imageWithColor(UIColor.redColor(), CGSizeMake(10, 10))
        let data = image.hnk_data(compressionQuality: -1.0)
        let expectedData = image.hnk_data(compressionQuality: 0.0)
        
        XCTAssertEqual(data, expectedData, "The min compression quality is 0.0")
    }
    
    func testDataCompressionQuality_MoreThan1() {
        let image = UIImage.imageWithColor(UIColor.redColor(), CGSizeMake(10, 10))
        let data = image.hnk_data(compressionQuality: 10.0)
        let expectedData = image.hnk_data(compressionQuality: 1.0)
        
        XCTAssertEqual(data, expectedData, "The min compression quality is 1.0")
    }
    
    // MARK: Helpers
    
    func _testDecompressedImageUsingColor(color : UIColor = UIColor.greenColor(), colorSpace: CGColorSpaceRef = CGColorSpaceCreateDeviceRGB(), alphaInfo :CGImageAlphaInfo, bitsPerComponent : size_t = 8) {
        let size = CGSizeMake(10, 20) // Using rectangle to check if image is rotated
        let bitmapInfo = CGBitmapInfo.ByteOrderDefault | CGBitmapInfo(alphaInfo.rawValue)
        let context = CGBitmapContextCreate(nil, UInt(size.width), UInt(size.height), bitsPerComponent, 0, colorSpace, bitmapInfo)
    
        CGContextSetFillColorWithColor(context, color.CGColor)
        CGContextFillRect(context, CGRectMake(0, 0, size.width, size.height))
        let imageRef = CGBitmapContextCreateImage(context)
    
        let image = UIImage(CGImage:imageRef, scale:UIScreen.mainScreen().scale, orientation:.Up)!
        let decompressedImage = image.hnk_decompressedImage()
    
        XCTAssertNotEqual(image, decompressedImage)
        XCTAssertTrue(decompressedImage.isEqualPixelByPixel(image), self.name)
    }
    
    func _testDecompressedImageWithOrientation(orientation : ExifOrientation) {
        // Create a gradient image to truly test orientation
        let gradientImage = UIImage.imageGradientFromColor()
        
        // Use TIFF because PNG doesn't store EXIF orientation
        let exifProperties = [kCGImagePropertyOrientation as NSString : Int(orientation.rawValue)] as NSDictionary
        let data = NSMutableData()
        let imageDestinationRef = CGImageDestinationCreateWithData(data as CFMutableDataRef, kUTTypeTIFF, 1, nil)
        CGImageDestinationAddImage(imageDestinationRef, gradientImage.CGImage, exifProperties)
        CGImageDestinationFinalize(imageDestinationRef)
        
        let image = UIImage(data:data, scale:UIScreen.mainScreen().scale)!
        
        let decompressedImage = image.hnk_decompressedImage()
        
        XCTAssertNotEqual(image, decompressedImage)
        XCTAssertTrue(decompressedImage.isEqualPixelByPixel(image), self.name)
    }
    
}
