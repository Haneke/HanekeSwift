//
//  UIImage+Haneke.swift
//  Haneke
//
//  Created by Hermes Pique on 8/10/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import UIKit

extension UIImage {

    func hnk_aspectFillSize(size: CGSize) -> CGSize {
        let scaleWidth: CGFloat = size.width / self.size.width
        let scaleHeight: CGFloat = size.height / self.size.height
        let scale: CGFloat = max(scaleWidth, scaleHeight)

        var resultSize: CGSize = CGSizeMake(self.size.width * scale, self.size.height * scale)
        return CGSizeMake(ceil(resultSize.width), ceil(resultSize.height))
    }

    func hnk_aspectFitSize(size: CGSize) -> CGSize {
        let targetAspect: CGFloat = size.width / size.height
        let sourceAspect: CGFloat = self.size.width / self.size.height
        var resultSize = size;

        if (targetAspect > sourceAspect) {
            resultSize.width = size.height * sourceAspect
        }
        else {
            resultSize.height = size.width / sourceAspect
        }
        return CGSizeMake(ceil(resultSize.width), ceil(resultSize.height))
    }

    func hnk_imageByScalingToSize(toSize: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(toSize, !hnk_hasAlpha(), 0.0);
        drawInRect(CGRectMake(0, 0, toSize.width, toSize.height))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return resizedImage
    }

    func hnk_hasAlpha() -> Bool {
        let alpha = CGImageGetAlphaInfo(self.CGImage)
        switch alpha {
        case .First, .Last, .PremultipliedFirst, .PremultipliedLast, .Only:
            return true
        case .None, .NoneSkipFirst, .NoneSkipLast:
            return false
        }
    }
    
    func hnk_data() -> NSData? {
        let hasAlpha = self.hnk_hasAlpha()
        let data = hasAlpha ? UIImagePNGRepresentation(self) : UIImageJPEGRepresentation(self, 1)
        return data
    }
    
}
