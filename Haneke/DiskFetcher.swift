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
            case invalidData = -500
        }
        
    }
    
}

open class DiskFetcher<T : DataConvertible> : Fetcher<T> {
    
    let path: String
    var cancelled = false
    
    public init(path: String) {
        self.path = path
        let key = path
        super.init(key: key)
    }
    
    // MARK: Fetcher
    
    
    open override func fetch(failure fail: @escaping ((Error?) -> ()), success succeed: @escaping (T.Result) -> ()) {
        self.cancelled = false
        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async(execute: { [weak self] in
            if let strongSelf = self {
                strongSelf.privateFetch(failure: fail, success: succeed)
            }
        })
    }
    
    open override func cancelFetch() {
        self.cancelled = true
    }
    
    // MARK: Private
    
    fileprivate func privateFetch(failure fail: @escaping ((Error?) -> ()), success succeed: @escaping (T.Result) -> ()) {
        if self.cancelled {
            return
        }
        
        let data : Data
        do {
            data = try Data(contentsOf: URL(fileURLWithPath: self.path), options: Data.ReadingOptions())
        } catch {
            DispatchQueue.main.async {
                if self.cancelled {
                    return
                }
                fail(error)
            }
            return
        }
        
        if self.cancelled {
            return
        }
        
        guard let value : T.Result = T.convertFromData(data) else {
            let localizedFormat = NSLocalizedString("Failed to convert value from data at path %@", comment: "Error description")
            let description = String(format:localizedFormat, self.path)
            let error = errorWithCode(HanekeGlobals.DiskFetcher.ErrorCode.invalidData.rawValue, description: description)
            DispatchQueue.main.async {
                fail(error)
            }
            return
        }
        
        DispatchQueue.main.async(execute: {
            if self.cancelled {
                return
            }
            succeed(value)
        })
    }
}
