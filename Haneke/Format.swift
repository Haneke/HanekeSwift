//
//  Format.swift
//  Haneke
//
//  Created by Hermes Pique on 8/27/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import Foundation

public enum ScaleMode {
    case Fill, AspectFit, AspectFill, None
}

public struct Format {
    
    public let name : String

    public let allowUpscaling : Bool
    
    public let compressionQuality : CGFloat = 1.0

    public let size : CGSize
    
    public let scaleMode: ScaleMode
    
    public let diskCapacity : UInt64
    
    public init(_ name : String, diskCapacity : UInt64 = 0, size : CGSize = CGSizeZero, scaleMode : ScaleMode = .None, allowUpscaling: Bool = true, compressionQuality : CGFloat = 1.0) {
        self.name = name
        self.diskCapacity = diskCapacity
        self.size = size
        self.scaleMode = scaleMode
        self.allowUpscaling = allowUpscaling
        self.compressionQuality = compressionQuality
    }
    
    // With Format<T> this could be func apply(object : T) -> T
    public func apply(image : UIImage) -> UIImage {
        // TODO: Pre-apply closure
        let resizedImage = self.resizedImageFromImage(image)
        // TODO: Post-apply closure
        return resizedImage
    }
    
    public func resizedImageFromImage(originalImage: UIImage) -> UIImage {
        var resizeToSize: CGSize
        switch self.scaleMode {
        case .Fill:
            resizeToSize = self.size
        case .AspectFit:
            resizeToSize = originalImage.size.hnk_aspectFitSize(self.size)
        case .AspectFill:
            resizeToSize = originalImage.size.hnk_aspectFillSize(self.size)
        case .None:
            return originalImage
        }
        assert(self.size.width > 0 && self.size.height > 0, "Expected non-zero size. Use ScaleMode.None to avoid resizing.")

        // If does not allow to scale up the image
        if (!self.allowUpscaling) {
            if (resizeToSize.width > originalImage.size.width || resizeToSize.height > originalImage.size.height) {
                return originalImage
            }
        }
        
        // Avoid unnecessary computations
        if (resizeToSize.width == originalImage.size.width && resizeToSize.height == originalImage.size.height) {
            return originalImage
        }
        
        let resizedImage = originalImage.hnk_imageByScalingToSize(resizeToSize)
        return resizedImage
    }
}
