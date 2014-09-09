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
}

