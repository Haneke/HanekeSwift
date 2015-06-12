//
//  DiskFetcher.swift
//  Haneke
//
//  Created by Joan Romano on 9/16/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import Foundation

extension HanekeGlobals {

    // It'd be better to define this in the DiskFetcher class but Swift doesn't allow to declare an enum in a generic type
    public struct DiskFetcher {
        
        public enum ErrorCode : Int {
            case InvalidData = -500
        }
        
    }
    
}

public class DiskFetcher<T : DataLiteralConvertable> : Fetcher<T> {
    
    let path : String
    var cancelled = false
    
    public init(path : String) {
        self.path = path
        let key = path
        super.init(key: key)
    }
    
    // MARK: Fetcher
    
    public override func fetch(failure fail : ((NSError?) -> ()), success succeed : (T) -> ()) {
        self.cancelled = false
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { [weak self] in
            if let strongSelf = self {
                strongSelf.privateFetch(failure: fail, success: succeed)
            }
        })
    }
    
    public override func cancelFetch() {
        self.cancelled = true
    }
    
    // MARK: Private
    
    private func privateFetch(failure fail : ((NSError?) -> ()), success succeed : (T) -> ()) {
        if self.cancelled {
            return
        }
        
        var error: NSError?
        let data = NSData(contentsOfFile: self.path, options: NSDataReadingOptions.allZeros, error: &error)
        if data == nil {
            dispatch_async(dispatch_get_main_queue()) {
                fail(error)
            }
            return
        }
        
        if self.cancelled {
            return
        }
        
        let value = T(data:(data as! T.DataLiteralType))
        
        if value == nil {
            let localizedFormat = NSLocalizedString("Failed to convert value from data at path %@", comment: "Error description")
            let description = String(format:localizedFormat, self.path)
            let error = errorWithCode(HanekeGlobals.DiskFetcher.ErrorCode.InvalidData.rawValue, description: description)
            dispatch_async(dispatch_get_main_queue()) {
                fail(error)
            }
            return
        }
        
        dispatch_async(dispatch_get_main_queue(), {
            if self.cancelled {
                return
            }
            succeed(value!)
        })
    }
}
