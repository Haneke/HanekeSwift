//
//  DiskFetcher.swift
//  Haneke
//
//  Created by Joan Romano on 9/16/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import Foundation

extension Haneke {
    public struct DiskFetcher {
        // It'd be better to define this in the DiskFetcher class but Swift doesn't allow to declare an enum in a generic type
        public enum ErrorCode : Int {
            case InvalidData = -500
        }
    }
}

public class DiskFetcher<T : DataConvertible> : Fetcher<T> {
    
    let path : NSString
    var cancelled = false
    
    public init(path : NSString) {
        self.path = path
        let key = path
        super.init(key: key)
    }
    
    // MARK: Entity
    
    public override func fetchWithSuccess(success doSuccess : (T.Result) -> (), failure doFailure : ((NSError?) -> ())) {
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
                
                let thing : T.Result? = T.convertFromData(data)
                
                if (thing == nil) {
                    let localizedFormat = NSLocalizedString("Failed to load image from data at path \(strongSelf.path)", comment: "Error description")
                    let error = Haneke.errorWithCode(Haneke.DiskFetcher.ErrorCode.InvalidData.toRaw(), description: localizedFormat)
                    dispatch_async(dispatch_get_main_queue(), {
                        doFailure(error)
                    })
                    return
                }
                
                dispatch_async(dispatch_get_main_queue(), {
                    if strongSelf.cancelled {
                        return
                    }
                    doSuccess(thing!)
                })
            }
            
        })
    }
    
    public override func cancelFetch() {
        self.cancelled = true
    }
}
