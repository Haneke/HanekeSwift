//
//  UIImageExtension.swift
//  Haneke
//
//  Created by Oriol Blanc Gimeno on 01/08/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import UIKit

extension UIImage {
    
    func isEqualPixelByPixel(theOtherImage: UIImage!) -> Bool {
        let imageData = UIImagePNGRepresentation(self);
        let theOtherImageData = UIImagePNGRepresentation(theOtherImage);
        
        return imageData.isEqualToData(theOtherImageData);
    }
    
    class func imageWithColor(color: UIColor, _ size: CGSize = CGSize(width: 1, height: 1), _ opaque: Bool = true) -> UIImage{
        UIGraphicsBeginImageContextWithOptions(size, opaque, 0);
        let context = UIGraphicsGetCurrentContext();
        CGContextSetFillColorWithColor(context, color.CGColor);
        CGContextFillRect(context, CGRectMake(0, 0, size.width, size.height));
        let image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return image;
    }
}

