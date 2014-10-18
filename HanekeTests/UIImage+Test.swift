//
//  UIImageExtension.swift
//  Haneke
//
//  Created by Oriol Blanc Gimeno on 01/08/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import UIKit

extension UIImage {
    
    func isEqualPixelByPixel(theOtherImage: UIImage) -> Bool {
        let imageData = self.normalizedData()
        let theOtherImageData = theOtherImage.normalizedData()
        return imageData.isEqualToData(theOtherImageData)
    }
    
    func normalizedData() -> NSData {
        let pixelSize = CGSize(width : self.size.width * self.scale, height : self.size.height * self.scale)
        NSLog(NSStringFromCGSize(pixelSize))
        UIGraphicsBeginImageContext(pixelSize)
        self.drawInRect(CGRect(x: 0, y: 0, width: pixelSize.width, height: pixelSize.height))
        let drawnImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        let provider = CGImageGetDataProvider(drawnImage.CGImage)
        let data = CGDataProviderCopyData(provider)
        return data
    }
    
    class func imageWithColor(color: UIColor, _ size: CGSize = CGSize(width: 1, height: 1), _ opaque: Bool = true) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, opaque, 0)
        let context = UIGraphicsGetCurrentContext()
        CGContextSetFillColorWithColor(context, color.CGColor)
        CGContextFillRect(context, CGRectMake(0, 0, size.width, size.height))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    class func imageGradientFromColor(fromColor : UIColor = UIColor.redColor(), toColor : UIColor = UIColor.greenColor(), size : CGSize = CGSizeMake(10, 20)) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false /* opaque */, 0 /* scale */)
        let context = UIGraphicsGetCurrentContext()
        let colorspace = CGColorSpaceCreateDeviceRGB()
        let gradientNumberOfLocations : size_t = 2
        let gradientLocations : [CGFloat] = [ 0.0, 1.0 ]
        var r1 : CGFloat = 0, g1 : CGFloat = 0, b1 : CGFloat = 0, a1 : CGFloat = 0
        fromColor.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        var r2 : CGFloat = 0, g2 : CGFloat = 0 , b2 : CGFloat = 0, a2 : CGFloat = 0
        toColor.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        let gradientComponents = [r1, g1, b1, a1, r2, g2, b2, a2]
        let gradient = CGGradientCreateWithColorComponents (colorspace, gradientComponents, gradientLocations, gradientNumberOfLocations)
        CGContextDrawLinearGradient(context, gradient, CGPointMake(0, 0), CGPointMake(0, size.height), 0)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
}

