//
//  Data.swift
//  Haneke
//
//  Created by Hermes Pique on 9/19/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import UIKit

// See: http://stackoverflow.com/questions/25922152/not-identical-to-self
public protocol DataConvertible {
    typealias Result
    
    static func convertFromData(data:NSData) -> Result?
}

public protocol DataRepresentable {
    
    func asData() -> NSData!
}

private let imageSync = NSLock()

extension UIImage : DataConvertible, DataRepresentable {
    
    public typealias Result = UIImage

    // HACK: UIImage data initializer is no longer thread safe. See: https://github.com/AFNetworking/AFNetworking/issues/2572#issuecomment-115854482
    static func safeImageWithData(data:NSData) -> Result? {
        imageSync.lock()
        let image = UIImage(data:data as Data)
        imageSync.unlock()
        return image
    }
    
    public class func convertFromData(data: NSData) -> Result? {
        let image = UIImage.safeImageWithData(data: data)
        return image
    }
    
    public func asData() -> NSData! {
        return self.hnk_data()
    }
    
}

extension String : DataConvertible, DataRepresentable {
    
    public typealias Result = String
    
    public static func convertFromData(data: NSData) -> Result? {
        let string = NSString(data: data as Data, encoding: String.Encoding.utf8.rawValue)
        return string as? Result
    }
    
    public func asData() -> NSData! {
        return self.data(using: String.Encoding.utf8)
    }
    
}

extension NSData : DataConvertible, DataRepresentable {
    
    public typealias Result = NSData
    
    public class func convertFromData(data: NSData) -> Result? {
        return data
    }
    
    public func asData() -> NSData! {
        return self
    }
    
}

public enum JSON : DataConvertible, DataRepresentable {
    public typealias Result = JSON
    
    case Dictionary([String:AnyObject])
    case Array([AnyObject])
    
    public static func convertFromData(data: NSData) -> Result? {
        do {
            let object : AnyObject = try JSONSerialization.jsonObject(with: data as Data, options: JSONSerialization.ReadingOptions())
            switch (object) {
            case let dictionary as [String:AnyObject]:
                return JSON.Dictionary(dictionary)
            case let array as [AnyObject]:
                return JSON.Array(array)
            default:
                return nil
            }
        } catch {
            Log.error(message: "Invalid JSON data", error: error as NSError)
            return nil
        }
    }
    
    public func asData() -> NSData! {
        switch (self) {
        case .Dictionary(let dictionary):
            return try? JSONSerialization.data(withJSONObject: dictionary, options: JSONSerialization.WritingOptions())
        case .Array(let array):
            return try? JSONSerialization.data(withJSONObject: array, options: JSONSerialization.WritingOptions())
        }
    }
    
    public var array : [AnyObject]! {
        switch (self) {
        case .Dictionary(_):
            return nil
        case .Array(let array):
            return array
        }
    }
    
    public var dictionary : [String:AnyObject]! {
        switch (self) {
        case .Dictionary(let dictionary):
            return dictionary
        case .Array(_):
            return nil
        }
    }
    
}
