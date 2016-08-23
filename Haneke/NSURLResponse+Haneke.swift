//
//  NSHTTPURLResponse+Haneke.swift
//  Haneke
//
//  Created by Hermes Pique on 9/12/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import Foundation

extension URLResponse {
    
    func hnk_validateLength(ofData data: Data) -> Bool {
        let expectedContentLength = self.expectedContentLength
        if (expectedContentLength > -1) {
            let dataLength = data.count
            return Int64(dataLength) >= expectedContentLength
        }
        return true
    }
    
}
