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
        return [ "\0":"%00", ":":"%3A", "/":"%2F" ]
            .reduce(self.componentsSeparatedByString("%").joinWithSeparator("%25")) {
                str, m in str.componentsSeparatedByString(m.0).joinWithSeparator(m.1)
        }
    }
    
    func MD5String() -> String {
        guard let data = self.dataUsingEncoding(NSUTF8StringEncoding) else {
            return self
        }

        let MD5Calculator = MD5(data)
        let MD5Data = MD5Calculator.calculate()
        let resultBytes = UnsafeMutablePointer<CUnsignedChar>(MD5Data.bytes)
        let resultEnumerator = UnsafeBufferPointer<CUnsignedChar>(start: resultBytes, count: MD5Data.length)
        let MD5String = NSMutableString()
        for c in resultEnumerator {
            MD5String.appendFormat("%02x", c)
        }
        return MD5String as String
    }
    
    func MD5Filename() -> String {
        let MD5String = self.MD5String()

        // NSString.pathExtension alone could return a query string, which can lead to very long filenames.
        let pathExtension = NSURL(string: self)?.pathExtension ?? (self as NSString).pathExtension

        if pathExtension.characters.count > 0 {
            return (MD5String as NSString).stringByAppendingPathExtension(pathExtension) ?? MD5String
        } else {
            return MD5String
        }
    }

}