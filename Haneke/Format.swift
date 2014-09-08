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

    public var allowUpscaling : Bool
    
    public var compressionQuality : Float = 1.0

    public var size : CGSize
    
    public var scaleMode: ScaleMode
    
    public let diskCapacity : UInt64
    
    public init(_ name : String, diskCapacity : UInt64 = 0, size : CGSize = CGSizeZero, scaleMode : ScaleMode = .Fill, allowUpscaling: Bool = true) {
        self.name = name
        self.diskCapacity = diskCapacity
        self.size = size
        self.scaleMode = scaleMode
        self.allowUpscaling = allowUpscaling
    }
    
    public func resizedImageFromImage(originalImage: UIImage) -> UIImage {
        var resizeToSize: CGSize
        switch self.scaleMode {
        case .Fill:
            resizeToSize = self.size
        case .AspectFit:
            resizeToSize = originalImage.hnk_aspectFitSize(self.size)
        case .AspectFill:
            resizeToSize = originalImage.hnk_aspectFillSize(self.size)
        case .None:
            return originalImage
        }

        // If does not allow to scale the image
        if (!self.allowUpscaling) {
            if (resizeToSize.width > originalImage.size.width || resizeToSize.height > originalImage.size.height) {
                return originalImage;
            }
        }
        
        // Avoid unnecessary computations
        if (resizeToSize.width == originalImage.size.width && resizeToSize.height == originalImage.size.height)
        {
            return originalImage;
        }
        
        let resizedImage = originalImage.hnk_imageByScalingToSize(resizeToSize)
        return resizedImage
    }
}
