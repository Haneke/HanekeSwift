//
//  String+Haneke.swift
//  Haneke
//
//  Created by Hermes Pique on 8/30/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import Foundation

extension String {

    func escapedFilename() -> String {
        let originalString = self as NSString as CFString
        let charactersToLeaveUnescaped = " \\" as NSString as CFString // TODO: Add more characters that are valid in paths but not in URLs
        let legalURLCharactersToBeEscaped = "/:" as NSString as CFString
        let encoding = CFStringBuiltInEncodings.UTF8.rawValue
        let escapedPath = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, originalString, charactersToLeaveUnescaped, legalURLCharactersToBeEscaped, encoding)!
        var escapedPathNSString = escapedPath as NSString
        return escapedPathNSString as String 
    }
    
    func MD5String() -> String {
        guard let data = self.data(using: String.Encoding.utf8) else {
            return self
        }

        let MD5Calculator = MD5(Array(data))
        let MD5Data = MD5Calculator.calculate()
        let resultBytes = UnsafeMutablePointer<CUnsignedChar>(mutating: MD5Data)
        let resultEnumerator = UnsafeBufferPointer<CUnsignedChar>(start: resultBytes, count: MD5Data.count)
        let MD5String = NSMutableString()
        for c in resultEnumerator {
            MD5String.appendFormat("%02x", c)
        }
        return MD5String as String
    }
    
    func MD5Filename() -> String {
        let MD5String = self.MD5String()
        let pathExtension = (self as NSString).pathExtension
        if pathExtension.characters.count > 0 {
            return (MD5String as NSString).appendingPathExtension(pathExtension) ?? MD5String
        } else {
            return MD5String
        }
    }

}
