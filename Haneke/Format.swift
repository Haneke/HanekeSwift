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

    public typealias ResizeTransform = (UIImage) -> (UIImage)
    
    public let name : String

    public let allowUpscaling : Bool
    
    public let compressionQuality : Float = 1.0

    public let size : CGSize
    
    public let scaleMode: ScaleMode
    
    public let diskCapacity : UInt64
    
    public let preResizeTransform : ResizeTransform?

    public let postResizeTransform : ResizeTransform?
    
    public init(_ name : String, diskCapacity : UInt64 = 0, size : CGSize = CGSizeZero, scaleMode : ScaleMode = .None, allowUpscaling: Bool = true, compressionQuality : Float = 1.0, preResizeTransform : ResizeTransform? = nil, postResizeTransform : ResizeTransform? = nil) {
        
        self.name = name
        self.diskCapacity = diskCapacity
        self.size = size
        self.scaleMode = scaleMode
        self.allowUpscaling = allowUpscaling
        self.compressionQuality = compressionQuality
        
        self.preResizeTransform = preResizeTransform
        self.postResizeTransform = postResizeTransform
    }
    
    // With Format<T> this could be func apply(object : T) -> T
    public func apply(OriginalImage : UIImage) -> UIImage {
        var image = OriginalImage
        if let preResizeClosure = self.preResizeTransform {
            image = preResizeClosure(image)
        }
        image = self.resizedImageFromImage(image)
        if let postResizeClosure = self.postResizeTransform {
            image = postResizeClosure(image)
        }
        
        return image
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
