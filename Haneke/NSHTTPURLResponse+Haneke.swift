//
//  NSHTTPURLResponse+Haneke.swift
//  Haneke
//
//  Created by Hermes Pique on 1/2/16.
//  Copyright © 2016 Haneke. All rights reserved.
//

import Foundation

extension NSHTTPURLResponse {

    func hnk_isValidStatusCode() -> Bool {
        switch self.statusCode {
        case 200...201:
            return true
        default:
            return false
        }
    }

}