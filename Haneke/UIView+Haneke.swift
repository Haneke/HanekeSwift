//
//  UIView+Haneke.swift
//  Haneke
//
//  Created by Joan Romano on 15/10/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import UIKit

public extension HanekeGlobals {
    
    public struct UIKit {
        
        static func formatWithSize(_ size : CGSize, scaleMode : ImageResizer.ScaleMode, allowUpscaling: Bool = true) -> Format<UIImage> {
            let name = "auto-\(size.width)x\(size.height)-\(scaleMode.rawValue)"
            let cache = Shared.imageCache
            if let (format,_,_) = cache.formats[name] {
                return format
            }
            
            var format = Format<UIImage>(name: name,
                diskCapacity: HanekeGlobals.UIKit.DefaultFormat.DiskCapacity) {
                    let resizer = ImageResizer(size:size,
                        scaleMode: scaleMode,
                        allowUpscaling: allowUpscaling,
                        compressionQuality: HanekeGlobals.UIKit.DefaultFormat.CompressionQuality)
                    return resizer.resizeImage($0)
            }
            format.convertToData = {(image : UIImage) -> Data in
                image.hnk_data(compressionQuality: HanekeGlobals.UIKit.DefaultFormat.CompressionQuality) as Data
            }
            return format
        }
        
        public struct DefaultFormat {
            
            public static let DiskCapacity : UInt64 = 50 * 1024 * 1024
            public static let CompressionQuality : Float = 0.75
            
        }
        
        static var SetImageAnimationDuration = 0.1
        static var SetImageFetcherKey = 0
        static var SetBackgroundImageFetcherKey = 1
    }
    
}
