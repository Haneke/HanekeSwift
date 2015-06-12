//
//  Data.swift
//  Haneke
//
//  Created by Hermes Pique on 9/19/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import UIKit

public protocol DataLiteralConvertable {
    typealias DataLiteralType
    
    init?(data:DataLiteralType)

    func toData() -> NSData?
}

public typealias DataLiteralType = NSData


extension UIImage : DataLiteralConvertable {
    public typealias DataLiteralType = NSData
    
    public func toData() -> NSData? {
        return self.hnk_data()
    }
}


extension String : DataLiteralConvertable {

    public init?(data value: NSData) {
        var buffer = [UInt8](count:value.length, repeatedValue:0)
        value.getBytes(&buffer, length:value.length)
        self.init(bytes:buffer, encoding:NSUTF8StringEncoding)
    }
    
    public func toData() -> NSData? {
        return self.dataUsingEncoding(NSUTF8StringEncoding)
    }
}

extension NSData : DataLiteralConvertable {
    public typealias DataLiteralType = NSData
    
    public func toData() -> NSData? {
        return self
    }

}


public enum JSON : DataLiteralConvertable {
    
    case Dictionary([String:AnyObject])
    case Array([AnyObject])
    
    
    public init?(data value: NSData) {
        var error : NSError?
        if let object : AnyObject = NSJSONSerialization.JSONObjectWithData(value, options: NSJSONReadingOptions.allZeros, error: &error) {
            switch (object) {
            case let dictionary as [String:AnyObject]:
                self = .Dictionary(dictionary)
            case let array as [AnyObject]:
                self = .Array(array)
            default:
                return nil
            }
        } else {
            Log.error("Invalid JSON data", error)
            return nil
        }
    }
    
    public func toData() -> NSData? {
        switch (self) {
        case .Dictionary(let dictionary):
            return NSJSONSerialization.dataWithJSONObject(dictionary, options: NSJSONWritingOptions.allZeros, error: nil)
        case .Array(let array):
            return NSJSONSerialization.dataWithJSONObject(array, options: NSJSONWritingOptions.allZeros, error: nil)
        }
    }
    
    public var array : [AnyObject]! {
        switch (self) {
        case .Dictionary(let _):
            return nil
        case .Array(let array):
            return array
        }
    }
    
    public var dictionary : [String:AnyObject]! {
        switch (self) {
        case .Dictionary(let dictionary):
            return dictionary
        case .Array(let _):
            return nil
        }
    }
    
}
