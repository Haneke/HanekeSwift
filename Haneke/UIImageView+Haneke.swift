//
//  UIImageView+Haneke.swift
//  Haneke
//
//  Created by Hermes Pique on 9/17/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import UIKit

public extension Haneke {
    public struct UIKit {
        public struct DefaultFormat {
            public static let DiskCapacity : UInt64 = 10 * 1024 * 1024
            public static let CompressionQuality : Float = 0.75
        }
    }
}

public extension UIImageView {
    
    public var hnk_scaleMode : ScaleMode {
        switch (self.contentMode) {
        case .ScaleToFill:
            return .Fill
        case .ScaleAspectFit:
            return .AspectFit
        case .ScaleAspectFill:
            return .AspectFill
        case .Redraw, .Center, .Top, .Bottom, .Left, .Right, .TopLeft, .TopRight, .BottomLeft, .BottomRight:
            return .None
            }
    }
    
    public class func hnk_formatWithSize(size : CGSize, scaleMode : ScaleMode) -> Format {
        let name = "auto-\(size.width)x\(size.height)-\(scaleMode.toRaw())"
        let cache = Haneke.sharedCache
        if let (format,_,_) = cache.formats[name] {
            return format
        }
        
        let format = Format(name,
            diskCapacity: Haneke.UIKit.DefaultFormat.DiskCapacity,
            size:size,
            scaleMode:scaleMode,
            compressionQuality: Haneke.UIKit.DefaultFormat.CompressionQuality)
        
        cache.addFormat(format)
        return format
    }

    public var hnk_format : Format {
        let viewSize = self.bounds.size
        assert(viewSize.width > 0 && viewSize.height > 0, "[\(reflect(self).summary) \(__FUNCTION__)]: UImageView size is zero. Set its frame, call sizeToFit or force layout first.")
        let scaleMode = self.hnk_scaleMode;
        return UIImageView.hnk_formatWithSize(viewSize, scaleMode: scaleMode)
    }
    
}
