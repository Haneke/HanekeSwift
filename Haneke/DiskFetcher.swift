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

public class DiskFetcher<T : DataConvertible> : Fetcher<T> {
    
    let path: String
    var cancelled = false
    
    public init(path: String) {
        self.path = path
        let key = path
        super.init(key: key)
    }
    
    // MARK: Fetcher
    
    public override func fetch(failure fail: ((NSError?) -> ()), success succeed: (T.Result) -> ()) {
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
    
    private func privateFetch(failure fail: ((NSError?) -> ()), success succeed: (T.Result) -> ()) {
        if self.cancelled {
            return
        }
        
        let data : NSData
        do {
            data = try NSData(contentsOfFile: self.path, options: NSDataReadingOptions())
        } catch {
            dispatch_async(dispatch_get_main_queue()) {
                if self.cancelled {
                    return
                }
                fail(error as NSError)
            }
            return
        }
        
        if self.cancelled {
            return
        }
        
        guard let value : T.Result = T.convertFromData(data) else {
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
            succeed(value)
        })
    }
}
