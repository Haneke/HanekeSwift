//
//  Format.swift
//  Haneke
//
//  Created by Hermes Pique on 8/27/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import Foundation

public struct Format {
    
    public let name : String
    
    public var diskCapacity : UInt64 = 0
    
    public init(_ name : String) {
        self.name = name
    }
    
}
