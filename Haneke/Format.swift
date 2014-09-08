//
//  Format.swift
//  Haneke
//
//  Created by Hermes Pique on 8/27/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import Foundation

public enum ScaleMode {
    case ScaleModeFill, ScaleModeAspectFit, ScaleModeAspectFill, ScaleModeNone
}

public struct Format {
    
    public let name : String

    public var allowUpscaling : Bool = true
    
    public var compressionQuality : Float = 1.0

    public var size : CGSize = CGSizeZero
    
    public var scaleMode: ScaleMode = .ScaleModeFill
    
    public let diskCapacity : UInt64
    
    public init(_ name : String, diskCapacity : UInt64 = 0) {
        self.name = name
        self.diskCapacity = diskCapacity
    }
    
    public func resizedImageFromImage(originalImage: UIImage) -> UIImage {
        var resizedSize: CGSize
        switch self.scaleMode {
        case .ScaleModeFill:
            resizedSize = self.size
        case .ScaleModeAspectFit:
            resizedSize = originalImage.hnk_aspectFitSize(self.size)
        case .ScaleModeAspectFill:
            resizedSize = originalImage.hnk_aspectFillSize(self.size)
        case .ScaleModeNone:
            return originalImage
        }
        
        // TODO: Scaling
        
        return originalImage
    }
}
