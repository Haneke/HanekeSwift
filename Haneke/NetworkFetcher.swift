//
//  NetworkFetcher.swift
//  Haneke
//
//  Created by Hermes Pique on 9/12/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import UIKit

extension Haneke {
    
    // It'd be better to define this in the NetworkFetcher class but Swift doesn't allow to declare an enum in a generic type
    public struct NetworkFetcherGlobals {

        public enum ErrorCode : Int {
            case InvalidData = -400
            case MissingData = -401
            case InvalidStatusCode = -402
        }
        
    }
    
}

public class NetworkFetcher<T : DataConvertible> : Fetcher<T> {
    
    let URL : NSURL
    
    public init(URL : NSURL) {
        self.URL = URL

        let key =  URL.absoluteString!
        super.init(key: key)
    }
    
    public var session : NSURLSession { return NSURLSession.sharedSession() }
    
    var task : NSURLSessionDataTask? = nil
    
    var cancelled = false
    
    // MARK: Fetcher
    
    public override func fetch(failure fail : ((NSError?) -> ()), success succeed : (T.Result) -> ()) {
        self.cancelled = false
        self.task = self.session.dataTaskWithURL(self.URL) {[weak self] (data : NSData!, response : NSURLResponse!, error : NSError!) -> Void in
            if let strongSelf = self {
                strongSelf.onReceiveData(data, response: response, error: error, failure: fail, success: succeed)
            }
        }
        self.task?.resume()
    }
    
    public override func cancelFetch() {
        self.task?.cancel()
        self.cancelled = true
    }
    
    // MARK: Private
    
    private func onReceiveData(data : NSData!, response : NSURLResponse!, error : NSError!, failure fail : ((NSError?) -> ()), success succeed : (T.Result) -> ()) {

        if cancelled { return }
        
        let URL = self.URL
        
        if let error = error {
            if (error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled) { return }
            
            Log.debug("Request \(URL.absoluteString!) failed", error)
            dispatch_async(dispatch_get_main_queue(), { fail(error) })
            return
        }
        
        // Intentionally avoiding `if let` to continue in golden path style.
        let httpResponse : NSHTTPURLResponse! = response as? NSHTTPURLResponse
        if httpResponse == nil {
            Log.debug("Request \(URL.absoluteString!) received unknown response \(response)")
            return
        }
        
        if httpResponse?.statusCode != 200 {
            let description = NSHTTPURLResponse.localizedStringForStatusCode(httpResponse.statusCode)
            self.failWithCode(.InvalidStatusCode, localizedDescription: description, failure: fail)
            return
        }
        
        if !httpResponse.hnk_validateLengthOfData(data) {
            let localizedFormat = NSLocalizedString("Request expected %ld bytes and received %ld bytes", comment: "Error description")
            let description = String(format:localizedFormat, response.expectedContentLength, data.length)
            self.failWithCode(.MissingData, localizedDescription: description, failure: fail)
            return
        }
        
        let value : T.Result? = T.convertFromData(data)
        if value == nil {
            let localizedFormat = NSLocalizedString("Failed to convert value from data at URL %@", comment: "Error description")
            let description = String(format:localizedFormat, URL.absoluteString!)
            self.failWithCode(.InvalidData, localizedDescription: description, failure: fail)
            return
        }

        dispatch_async(dispatch_get_main_queue()) { succeed(value!) }

    }
    
    private func failWithCode(code : Haneke.NetworkFetcherGlobals.ErrorCode, localizedDescription : String, failure fail : ((NSError?) -> ())) {
        let error = Haneke.errorWithCode(code.rawValue, description: localizedDescription)
        Log.debug(localizedDescription, error)
        dispatch_async(dispatch_get_main_queue()) { fail(error) }
    }
}
