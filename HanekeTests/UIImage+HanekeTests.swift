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
@testable import Haneke

enum ExifOrientation : UInt32 {
    case up = 1
    case down = 3
    case left = 8
    case right = 6
    case upMirrored = 2
    case downMirrored = 4
    case leftMirrored = 5
    case rightMirrored = 7
}

class UIImage_HanekeTests: XCTestCase {

    func testHasAlphaTrue() {
        let image = UIImage.imageWithColor(UIColor.red, false, CGSize(width: 1, height: 1))
        XCTAssertTrue(image.hnk_hasAlpha())
    }
    
    func testHasAlphaFalse() {
        let image = UIImage.imageWithColor(UIColor.red, true, CGSize(width: 1, height: 1))
        XCTAssertFalse(image.hnk_hasAlpha())
    }
    
    func testDataPNG() {
        let image = UIImage.imageWithColor(UIColor.red, false, CGSize(width: 1, height: 1))
        let expectedData = UIImagePNGRepresentation(image)
        
        let data = image.hnk_data()
        
        XCTAssertEqual(data!, expectedData)
    }
    
    func testDataJPEG() {
        let image = UIImage.imageWithColor(UIColor.red, true, CGSize(width: 1, height: 1))
        let expectedData = UIImageJPEGRepresentation(image, 1)
        
        let data = image.hnk_data()
        
        XCTAssertEqual(data!, expectedData)
    }
    
    func testDataNil() {
        let image = UIImage()

        XCTAssertNil(image.hnk_data())
    }
    
    func testDecompressedImage_UIGraphicsContext_Opaque() {
        let image = UIImage.imageWithColor(UIColor.red, CGSize(width: 10, height: 10))

        let decompressedImage = image.hnk_decompressedImage()
        
        XCTAssertNotEqual(image, decompressedImage)
        XCTAssertTrue(decompressedImage.isEqualPixelByPixel(image))
    }
    
    func testDecompressedImage_UIGraphicsContext_NotOpaque() {
        let image = UIImage.imageWithColor(UIColor.red, false, CGSize(width: 10, height: 10))
        
        let decompressedImage = image.hnk_decompressedImage()
        
        XCTAssertNotEqual(image, decompressedImage)
        XCTAssertTrue(decompressedImage.isEqualPixelByPixel(image))
    }
    
    func testDecompressedImage_RGBA() {
        let color = UIColor(red:255, green:0, blue:0, alpha:0.5)
        self._testDecompressedImageUsingColor(color, alphaInfo: .premultipliedLast)
    }
    
    func testDecompressedImage_ARGB() {
        let color = UIColor(red:255, green:0, blue:0, alpha:0.5)
        self._testDecompressedImageUsingColor(color, alphaInfo: .premultipliedFirst)
    }
    
    func testDecompressedImage_RGBX() {
        self._testDecompressedImageUsingColor(alphaInfo: .noneSkipLast)
    }
    
    func testDecompressedImage_XRGB() {
        self._testDecompressedImageUsingColor(alphaInfo: .noneSkipFirst)
    }
    
    func testDecompressedImage_Gray_AlphaNone() {
        let color = UIColor.gray
        let colorSpaceRef = CGColorSpaceCreateDeviceGray()
        self._testDecompressedImageUsingColor(color, colorSpace: colorSpaceRef, alphaInfo: .none)
    }
    
    func testDecompressedImage_OrientationUp() {
        self._testDecompressedImageWithOrientation(.up)
    }
    
    func testDecompressedImage_OrientationDown() {
        self._testDecompressedImageWithOrientation(.down)
    }
    
    func testDecompressedImage_OrientationLeft() {
        self._testDecompressedImageWithOrientation(.left)
    }
    
    func testDecompressedImage_OrientationRight() {
        self._testDecompressedImageWithOrientation(.right)
    }
    
    func testDecompressedImage_OrientationUpMirrored() {
        self._testDecompressedImageWithOrientation(.upMirrored)
    }
    
    func testDecompressedImage_OrientationDownMirrored() {
        self._testDecompressedImageWithOrientation(.downMirrored)
    }
    
    func testDecompressedImage_OrientationLeftMirrored() {
        self._testDecompressedImageWithOrientation(.leftMirrored)
    }
    
    func testDecompressedImage_OrientationRightMirrored() {
        self._testDecompressedImageWithOrientation(.rightMirrored)
    }
    
    func testDataCompressionQuality() {
        let image = UIImage.imageWithColor(UIColor.red, CGSize(width: 10, height: 10))
        let data = image.hnk_data()
        let notExpectedData = image.hnk_data(compressionQuality: 0.5)
        
        XCTAssertNotEqual(data, notExpectedData)
    }
    
    func testDataCompressionQuality_LessThan0() {
        let image = UIImage.imageWithColor(UIColor.red, CGSize(width: 10, height: 10))
        let data = image.hnk_data(compressionQuality: -1.0)
        let expectedData = image.hnk_data(compressionQuality: 0.0)
        
        XCTAssertEqual(data, expectedData, "The min compression quality is 0.0")
    }
    
    func testDataCompressionQuality_MoreThan1() {
        let image = UIImage.imageWithColor(UIColor.red, CGSize(width: 10, height: 10))
        let data = image.hnk_data(compressionQuality: 10.0)
        let expectedData = image.hnk_data(compressionQuality: 1.0)
        
        XCTAssertEqual(data, expectedData, "The min compression quality is 1.0")
    }
    
    // MARK: Helpers
    
    func _testDecompressedImageUsingColor(_ color : UIColor = UIColor.green, colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB(), alphaInfo :CGImageAlphaInfo, bitsPerComponent : size_t = 8) {
        let size = CGSize(width: 10, height: 20) // Using rectangle to check if image is rotated
        let bitmapInfo = CGBitmapInfo().rawValue | alphaInfo.rawValue
        let context = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: bitsPerComponent, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo)
    
        context?.setFillColor(color.cgColor)
        context?.fill(CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let imageRef = context?.makeImage()!
    
        let image = UIImage(cgImage: imageRef!, scale:UIScreen.main.scale, orientation:.up)
        let decompressedImage = image.hnk_decompressedImage()
    
        XCTAssertNotEqual(image, decompressedImage)
        XCTAssertTrue(decompressedImage.isEqualPixelByPixel(image), self.name!)
    }
    
    func _testDecompressedImageWithOrientation(_ orientation : ExifOrientation) {
        // Create a gradient image to truly test orientation
        let gradientImage = UIImage.imageGradientFromColor()
        
        // Use TIFF because PNG doesn't store EXIF orientation
        let exifProperties = NSDictionary(dictionary: [kCGImagePropertyOrientation: Int(orientation.rawValue)])
        let data = NSMutableData()
        let imageDestinationRef = CGImageDestinationCreateWithData(data as CFMutableData, kUTTypeTIFF, 1, nil)!
        CGImageDestinationAddImage(imageDestinationRef, gradientImage.cgImage!, exifProperties as CFDictionary)
        CGImageDestinationFinalize(imageDestinationRef)
        
        let image = UIImage(data:data as Data, scale:UIScreen.main.scale)!
        
        let decompressedImage = image.hnk_decompressedImage()
        
        XCTAssertNotEqual(image, decompressedImage)
        XCTAssertTrue(decompressedImage.isEqualPixelByPixel(image), self.name!)
    }
    
}
