//
//  Fetch.swift
//  Haneke
//
//  Created by Hermes Pique on 9/28/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import Foundation

enum FetchState<T> {
    case pending
    // Using Wrapper as a workaround for error 'unimplemented IR generation feature non-fixed multi-payload enum layout'
    // See: http://swiftradar.tumblr.com/post/88314603360/swift-fails-to-compile-enum-with-two-data-cases
    // See: http://owensd.io/2014/08/06/fixed-enum-layout.html
    case success(Wrapper<T>)
    case failure(Error?)
}

open class Fetch<T> {
    
    public typealias Succeeder = (T) -> ()
    
    public typealias Failer = (Error?) -> ()
    
    fileprivate var onSuccess : Succeeder?
    
    fileprivate var onFailure : Failer?
    
    fileprivate var state : FetchState<T> = FetchState.pending
    
    public init() {}
    
    open func onSuccess(_ onSuccess: @escaping Succeeder) -> Self {
        self.onSuccess = onSuccess
        switch self.state {
        case FetchState.success(let wrapper):
            onSuccess(wrapper.value)
        default:
            break
        }
        return self
    }
    
    open func onFailure(_ onFailure: @escaping Failer) -> Self {
        self.onFailure = onFailure
        switch self.state {
        case FetchState.failure(let error):
            onFailure(error)
        default:
            break
        }
        return self
    }
    
    func succeed(_ value: T) {
        self.state = FetchState.success(Wrapper(value))
        self.onSuccess?(value)
    }
    
    func fail(_ error: Error? = nil) {
        self.state = FetchState.failure(error)
        self.onFailure?(error)
    }
    
    var hasFailed : Bool {
        switch self.state {
        case FetchState.failure(_):
            return true
        default:
            return false
            }
    }
    
    var hasSucceeded : Bool {
        switch self.state {
        case FetchState.success(_):
            return true
        default:
            return false
        }
    }
    
}

open class Wrapper<T> {
    open let value: T
    public init(_ value: T) { self.value = value }
}
