//
//  NetworkEntity.swift
//  Haneke
//
//  Created by Hermes Pique on 9/12/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import UIKit

extension Haneke {
    public struct NetworkEntity {
        // It'd be better to define this in the NetworkEntity class but Swift doesn't allow to declare an enum in a generic type
        public enum ErrorCode : Int {
            case InvalidData = -400
            case MissingData = -401
            case InvalidStatusCode = -402
        }
    }
}

public class NetworkEntity<T : DataConvertible> : Fetcher<T> {
    
    let URL : NSURL
    
    public init(URL : NSURL) {
        self.URL = URL

        let key =  URL.absoluteString!
        super.init(key: key)
    }
    
    public var session : NSURLSession { return NSURLSession.sharedSession() }
    
    var task : NSURLSessionDataTask? = nil
    
    var cancelled = false
    
    // MARK: Entity
    
    public override func fetchWithSuccess(success doSuccess : (T.Result) -> (), failure doFailure : ((NSError?) -> ())) {
        self.cancelled = false
        self.task = self.session.dataTaskWithURL(self.URL) {[weak self] (data : NSData!, response : NSURLResponse!, error : NSError!) -> Void in
            if let strongSelf = self {
                strongSelf.onReceiveData(data, response: response, error: error, success: doSuccess, failure: doFailure)
            }
        }
        self.task?.resume()
    }
    
    public override func cancelFetch() {
        self.task?.cancel()
        self.cancelled = true
    }
    
    // MARK: Private
    
    private func onReceiveData(data : NSData!, response : NSURLResponse!, error : NSError!, success doSuccess : (T.Result) -> (), failure doFailure : ((NSError?) -> ())) {

        if cancelled { return }
        
        let URL = self.URL
        
        if let error = error {
            if (error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled) { return; }
            
            NSLog("Request \(URL.absoluteString!) failed with error \(error)")
            dispatch_async(dispatch_get_main_queue(), { doFailure(error) })
            return
        }
        
        // Intentionally avoiding `if let` to continue in golden path style.
        let httpResponse : NSHTTPURLResponse! = response as? NSHTTPURLResponse
        if httpResponse == nil {
            NSLog("Request \(URL.absoluteString!) received unknown response \(response)")
            return
        }
        
        if httpResponse?.statusCode != 200 {
            let description = NSHTTPURLResponse.localizedStringForStatusCode(httpResponse.statusCode)
            self.failWithCode(.InvalidStatusCode, localizedDescription: description, failure: doFailure)
            return
        }
        
        if !httpResponse.hnk_validateLengthOfData(data) {
            let localizedFormat = NSLocalizedString("Request expected %ld bytes and received %ld bytes", comment: "Error description")
            let description = String(format:localizedFormat, response.expectedContentLength, data.length)
            self.failWithCode(.MissingData, localizedDescription: description, failure: doFailure)
            return
        }
        
        let thing : T.Result? = T.convertFromData(data)
        if thing == nil {
            let localizedFormat = NSLocalizedString("Failed to load image from data at URL %@", comment: "Error description")
            let description = String(format:localizedFormat, URL.absoluteString!)
            self.failWithCode(.InvalidData, localizedDescription: description, failure: doFailure)
            return
        }

        dispatch_async(dispatch_get_main_queue(), { doSuccess(thing!) })

    }
    
    private func failWithCode(code : Haneke.NetworkEntity.ErrorCode, localizedDescription : String, failure doFailure : ((NSError?) -> ())) {
        // TODO: Log error in debug mode
        let error = Haneke.errorWithCode(code.toRaw(), description: localizedDescription)
        dispatch_async(dispatch_get_main_queue(), { doFailure(error) })
    }
}
