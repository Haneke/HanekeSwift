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
    
}

class SimpleEntity : Entity {
    
    let key : String
    let image : UIImage
    
    init(key : String, image : UIImage) {
        self.key = key
        self.image = image
    }
    
    func fetchImageWithSuccess(success doSuccess : (UIImage) -> (), failure doFailure : ((NSError?) -> ())) {
       doSuccess(image)
    }
    
}
