//
//  NSData.swift
//  Haneke
//
//  Created by Hermes Pique on 8/23/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import Foundation

extension NSData {
    
    class func dataWithLength(length : Int) -> NSData {
        var buffer: [UInt8] = [UInt8](count:length, repeatedValue:0)
        return NSData(bytes:&buffer, length: length)
    }
    
}