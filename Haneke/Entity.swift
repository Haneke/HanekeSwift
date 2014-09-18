//
//  Entity.swift
//  Haneke
//
//  Created by Hermes Pique on 9/9/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import UIKit

public protocol Entity {

    var key : String { get }
    
    func fetchImageWithSuccess(success doSuccess : (UIImage) -> (), failure doFailure : ((NSError?) -> ()))
    
    func cancelFetch()
}

class SimpleEntity : Entity {
    
    let key : String
    let getImage : () -> UIImage
    
    init(key : String, image getImage : @autoclosure () -> UIImage) {
        self.key = key
        self.getImage = getImage
    }
    
    func fetchImageWithSuccess(success doSuccess : (UIImage) -> (), failure doFailure : ((NSError?) -> ())) {
        let image = getImage()
        doSuccess(image)
    }
    
    func cancelFetch() {}
    
}
