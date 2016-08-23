//
//  Log.swift
//  Haneke
//
//  Created by Hermes Pique on 11/10/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import Foundation

struct Log {
    
    fileprivate static let Tag = "[HANEKE]"
    
    fileprivate enum Level : String {
        case Debug = "[DEBUG]"
        case Error = "[ERROR]"
    }
    
    fileprivate static func log(_ level: Level, _ message: @autoclosure () -> String, _ error: Error? = nil) {
        if let error = error {
            print("\(Tag)\(level.rawValue) \(message()) with error \(error)")
        } else {
            print("\(Tag)\(level.rawValue) \(message())")
        }
    }
    
    static func debug(message: @autoclosure () -> String, error: Error? = nil) {
        #if DEBUG
            log(.Debug, message, error)
        #endif
    }
    
    static func error(message: @autoclosure () -> String, error: Error? = nil) {
        log(.Error, message, error)
    }
    
}
