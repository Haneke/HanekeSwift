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
    var cancelled = false
    
    public init(path : NSString) {
        self.path = path
    }
    
    // MARK: Entity
    
    public var key : String { return path }
    
    public func fetchImageWithSuccess(success doSuccess : (UIImage) -> (), failure doFailure : ((NSError?) -> ())) {
        self.cancelled = false
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { [weak self] in
            
            if let strongSelf = self {
                if strongSelf.cancelled {
                    return
                }
                
                var error: NSError? = nil
                let data = NSData.dataWithContentsOfFile(strongSelf.path, options: NSDataReadingOptions.allZeros, error: &error)
                if (data == nil) {
                    dispatch_async(dispatch_get_main_queue(), {
                        doFailure(error)
                    })
                    return
                }
                
                if strongSelf.cancelled {
                    return
                }
                
                let image : UIImage? = UIImage(data : data)
                
                if (image == nil) {
                    let localizedFormat = NSLocalizedString("Failed to load image from data at path \(strongSelf.path)", comment: "Error description")
                    let error = Haneke.errorWithCode(DiskEntity.ErrorCode.InvalidData.toRaw(), description: localizedFormat)
                    dispatch_async(dispatch_get_main_queue(), {
                        doFailure(error)
                    })
                    return
                }
                
                dispatch_async(dispatch_get_main_queue(), {
                    if strongSelf.cancelled {
                        return
                    }
                    doSuccess(image!)
                })
            }
        
        })
    }
    
    public func cancelFetch() {
        self.cancelled = true
    }
}
