//
//  NetworkFetcher.swift
//  Haneke
//
//  Created by Hermes Pique on 9/12/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import UIKit

extension HanekeGlobals {
    
    // It'd be better to define this in the NetworkFetcher class but Swift doesn't allow to declare an enum in a generic type
    public struct NetworkFetcher {

        public enum ErrorCode : Int {
            case InvalidData = -400
            case MissingData = -401
            case InvalidStatusCode = -402
        }
        
    }
    
}

public class NetworkFetcher<T : DataConvertible> : Fetcher<T> {
    
    let URL : Foundation.URL
    
    public init(URL : Foundation.URL) {
        self.URL = URL

        let key =  URL.absoluteString
        super.init(key: key)
    }
    
    public var session : URLSession { return URLSession.shared }
    
    var task : URLSessionDataTask? = nil
    
    var cancelled = false
    
    // MARK: Fetcher
    
    
    public override func fetch(failure fail : @escaping ((Error?) -> ()), success succeed : @escaping (T.Result) -> ()) {
        self.cancelled = false
        self.task = self.session.dataTask(with: self.URL as URL) {[weak self] (data, response, error) -> Void in
            if let strongSelf = self {
                strongSelf.onReceiveData(data: data , response: response, error: error , failure: fail, success: succeed)
            }
        }
        self.task?.resume()
    }
    
    public override func cancelFetch() {
        self.task?.cancel()
        self.cancelled = true
    }
    
    // MARK: Private
    
    internal func onReceiveData(data: Data!, response: URLResponse!, error: Error?, failure fail: @escaping ((Error?) -> ()), success succeed: @escaping (T.Result) -> ()) {

        if cancelled { return }
        
        let URL = self.URL
        
        if let error = error as? URLError   {
            
            if  error.code == URLError.cancelled  {
                return }
            
           Log.debug(message: "Request \(error.failureURLString ?? URL.absoluteString) failed", error: error)
            DispatchQueue.main.async { fail(error) }
            return
        }
        
        if let httpResponse = response as? HTTPURLResponse , !httpResponse.hnk_isValidStatusCode() {
            let description = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
            self.failWithCode(code: .InvalidStatusCode, localizedDescription: description, failure: fail)
            return
        }

        if !response.hnk_validateLengthOfData(data: data) {
            let localizedFormat = NSLocalizedString("Request expected %ld bytes and received %ld bytes", comment: "Error description")
            let description = String(format:localizedFormat, response.expectedContentLength, data.count)
            self.failWithCode(code: .MissingData, localizedDescription: description, failure: fail)
            return
        }
        
        guard let value = T.convertFromData(data: data) else {
            let localizedFormat = NSLocalizedString("Failed to convert value from data at URL %@", comment: "Error description")
            let description = String(format:localizedFormat, URL.absoluteString)
            self.failWithCode(code: .InvalidData, localizedDescription: description, failure: fail)
            return
        }

         DispatchQueue.main.async  { succeed(value) }

    }
    
    internal func failWithCode(code: HanekeGlobals.NetworkFetcher.ErrorCode, localizedDescription: String, failure fail: @escaping ((Error?) -> ())) {
        let error = errorWithCode(code: code.rawValue, description: localizedDescription)
        Log.debug(message: localizedDescription, error: error)
        DispatchQueue.main.async { fail(error) }
    }
}
