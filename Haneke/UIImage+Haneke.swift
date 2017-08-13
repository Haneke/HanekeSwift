//
//  UIImage+Haneke.swift
//  Haneke
//
//  Created by Hermes Pique on 8/10/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import UIKit

extension UIImage {

    func hnk_imageByScaling(toSize size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, !hnk_hasAlpha(), 0.0)
        draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage!
    }

    func hnk_hasAlpha() -> Bool {
        guard let alphaInfo = self.cgImage?.alphaInfo else { return false }
        switch alphaInfo {
        case .first, .last, .premultipliedFirst, .premultipliedLast, .alphaOnly:
            return true
        case .none, .noneSkipFirst, .noneSkipLast:
            return false
        }
    }
    
    func hnk_data(compressionQuality: Float = 1.0) -> Data! {
        let hasAlpha = self.hnk_hasAlpha()
        let data = hasAlpha ? UIImagePNGRepresentation(self) : UIImageJPEGRepresentation(self, CGFloat(compressionQuality))
        return data
    }
    
    func hnk_decompressedImage() -> UIImage! {
        let originalImageRef = self.cgImage
        let originalBitmapInfo = originalImageRef?.bitmapInfo
        guard let alphaInfo = originalImageRef?.alphaInfo else { return UIImage() }
        
        // See: http://stackoverflow.com/questions/23723564/which-cgimagealphainfo-should-we-use
        var bitmapInfo = originalBitmapInfo
        switch alphaInfo {
        case .none:
            let rawBitmapInfoWithoutAlpha = (bitmapInfo?.rawValue)! & ~CGBitmapInfo.alphaInfoMask.rawValue
            let rawBitmapInfo = rawBitmapInfoWithoutAlpha | CGImageAlphaInfo.noneSkipFirst.rawValue
            bitmapInfo = CGBitmapInfo(rawValue: rawBitmapInfo)
        case .premultipliedFirst, .premultipliedLast, .noneSkipFirst, .noneSkipLast:
            break
        case .alphaOnly, .last, .first: // Unsupported
            return self
        }
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let pixelSize = CGSize(width: self.size.width * self.scale, height: self.size.height * self.scale)
        guard let context = CGContext(data: nil, width: Int(ceil(pixelSize.width)), height: Int(ceil(pixelSize.height)), bitsPerComponent: (originalImageRef?.bitsPerComponent)!, bytesPerRow: 0, space: colorSpace, bitmapInfo: (bitmapInfo?.rawValue)!) else {
            return self
        }

        let imageRect = CGRect(x: 0, y: 0, width: pixelSize.width, height: pixelSize.height)
        UIGraphicsPushContext(context)
        
        // Flip coordinate system. See: http://stackoverflow.com/questions/506622/cgcontextdrawimage-draws-image-upside-down-when-passed-uiimage-cgimage
        context.translateBy(x: 0, y: pixelSize.height)
        context.scaleBy(x: 1.0, y: -1.0)
        
        // UIImage and drawInRect takes into account image orientation, unlike CGContextDrawImage.
        self.draw(in: imageRect)
        UIGraphicsPopContext()
        
        guard let decompressedImageRef = context.makeImage() else {
            return self
        }
        
        let scale = UIScreen.main.scale
        let image = UIImage(cgImage: decompressedImageRef, scale:scale, orientation:UIImageOrientation.up)
        return image
    }

}
