//
//  UIView+Haneke.swift
//  Haneke
//
//  Created by Joan Romano on 15/10/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import UIKit

public extension Haneke {
    
    public struct UIKitGlobals {
        
        public struct DefaultFormat {
            
            public static let DiskCapacity : UInt64 = 10 * 1024 * 1024
            public static let CompressionQuality : Float = 0.75
            
        }
        
        static var SetImageFetcherKey = 0
        static var SetBackgroundImageFetcherKey = 1
    }
    
}
