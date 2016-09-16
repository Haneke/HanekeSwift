//
//  NSData.swift
//  Haneke
//
//  Created by Hermes Pique on 8/23/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import Foundation

extension Data {
    
    static func dataWithLength(_ length : Int) -> Data {
        var buffer: [UInt8] = [UInt8](repeating: 0, count: length)
        return Data(bytes: UnsafePointer<UInt8>(&buffer), count: length)
    }
    
}
