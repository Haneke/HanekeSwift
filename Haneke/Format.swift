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

    public var allowUpscaling : Bool = false
    
    public var compressionQuality : Float = 1.0

    public let size : CGSize = CGSizeZero
    
    public var scaleMode: ScaleMode = .ScaleModeNone
    
    public init(_ name : String) {
        self.name = name
    }
    
    public func resizedImageFromImage(originalImage: UIImage) -> UIImage {
        return originalImage
    }
}
