//
//  DataConvertible.swift
//  Haneke
//
//  Created by Hermes Pique on 9/19/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import UIKit

public protocol DataConvertible {
    typealias Result
    
    class func convertFromData(data:NSData) -> Result?
}

public protocol DataRepresentable {
    
    func asData() -> NSData?
}

extension UIImage : DataConvertible, DataRepresentable {
    
    public typealias Result = UIImage
    
    public class func convertFromData(data:NSData) -> Result? {
        let image : UIImage? = UIImage(data: data)
        return image
    }
    
    public func asData() -> NSData? {
        return self.hnk_data()
    }
    
}

