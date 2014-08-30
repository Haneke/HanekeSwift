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
        let encoding = CFStringBuiltInEncodings.UTF8.toRaw()
        let escapedPath = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, originalString, charactersToLeaveUnescaped, legalURLCharactersToBeEscaped, encoding)
        return escapedPath as NSString as String
    }

}