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
    associatedtype Result
    
    static func convertFromData(data:Data) -> Result?
}

public protocol DataRepresentable {
    
    func asData() -> Data!
}

private let imageSync = NSLock()

extension UIImage : DataConvertible, DataRepresentable {
    
    public typealias Result = UIImage

    // HACK: UIImage data initializer is no longer thread safe. See: https://github.com/AFNetworking/AFNetworking/issues/2572#issuecomment-115854482
    static func safeImageWithData(data:Data) -> Result? {
        imageSync.lock()
        let image = UIImage(data:data )
        imageSync.unlock()
        return image
    }
    
    public class func convertFromData(data: Data) -> Result? {
        let image = UIImage.safeImageWithData(data: data)
        return image
    }
    
    public func asData() -> Data! {
        return self.hnk_data()
    }
    
}

extension String : DataConvertible, DataRepresentable {
    
    public typealias Result = String
    
    public static func convertFromData(data: Data) -> Result? {
        let string = NSString(data: data , encoding: String.Encoding.utf8.rawValue)
        return string as? Result
    }
    
    public func asData() -> Data! {
        return self.data(using: String.Encoding.utf8)
    }
    
}

extension Data : DataConvertible, DataRepresentable {
    
    public typealias Result = Data
    
    public static func convertFromData(data: Data) -> Result? {
        return data as Result
    }
    
    public func asData() -> Data! {
        return self
    }
    
}

public enum JSON : DataConvertible, DataRepresentable {
    public typealias Result = JSON
    
    case Dictionary([String:Any])
    case Array([Any])
    
    public static func convertFromData(data: Data) -> Result? {
        do {
            let object = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions())
            switch (object) {
            case let dictionary as [String:Any]:
                return JSON.Dictionary(dictionary)
            case let array as [Any]:
                return JSON.Array(array)
            default:
                return nil
            }
        } catch {
            Log.error(message: "Invalid JSON data", error: error as Error)
            return nil
        }
    }
    
    public func asData() -> Data! {
        switch (self) {
        case .Dictionary(let dictionary):
            return try? JSONSerialization.data(withJSONObject: dictionary, options: JSONSerialization.WritingOptions())
        case .Array(let array):
            return try? JSONSerialization.data(withJSONObject: array, options: JSONSerialization.WritingOptions())
        }
    }
    
    public var array : [Any]! {
        switch (self) {
        case .Dictionary(_):
            return nil
        case .Array(let array):
            return array
        }
    }
    
    public var dictionary : [String:Any]! {
        switch (self) {
        case .Dictionary(let dictionary):
            return dictionary
        case .Array(_):
            return nil
        }
    }
    
}
