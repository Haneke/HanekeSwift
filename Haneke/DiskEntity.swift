//
//  DiskEntity.swift
//  Haneke
//
//  Created by Joan Romano on 9/16/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import Foundation

public class DiskEntity : Entity {
    
    public enum ErrorCode : Int {
        case InvalidData = -500
    }
    
    let path : NSString
    
    public init(path : NSString) {
        self.path = path
    }
    
    public var key : String { return path }
    
    public func fetchImageWithSuccess(success doSuccess : (UIImage) -> (), failure doFailure : ((NSError?) -> ())) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            
            var error: NSError? = nil
            let data = NSData.dataWithContentsOfFile(self.path, options: NSDataReadingOptions.allZeros, error: &error)
            if (data == nil) {
                dispatch_async(dispatch_get_main_queue(), {
                    doFailure(error)
                })
                return;
            }
            
            let image : UIImage? = UIImage(data : data)
            
            if (image == nil) {
                let localizedFormat = NSLocalizedString("Failed to load image from data at path \(self.path)", comment: "Error description")
                let error = Haneke.errorWithCode(DiskEntity.ErrorCode.InvalidData.toRaw(), description: localizedFormat)
                dispatch_async(dispatch_get_main_queue(), {
                    doFailure(error)
                })
                return;
            }
            
            dispatch_async(dispatch_get_main_queue(), {
                doSuccess(image!)
            })
        })
    }
    
    public func cancelFetch() {
        
    }
}
