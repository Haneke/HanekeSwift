//
//  NSObject+Haneke.swift
//  Haneke
//
//  Created by Hermes Pique on 9/19/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

@objc protocol HasAssociatedSwift : class {
    
    func hnk_clearSwiftAssociations()
}

extension Haneke {
    struct NSObject {
        static var denitiObserverKey : UInt8 = 0
    }
}

class DeallocWitness : NSObject {
    
    weak var object : HasAssociatedSwift!
    
    init (object: HasAssociatedSwift) {
        self.object = object
    }
    
    deinit {
        object.hnk_clearSwiftAssociations()
    }
}

extension NSObject {
    
    var hnk_pointer : COpaquePointer {
        return Unmanaged<AnyObject>.passUnretained(self).toOpaque()
    }
    
    class func hnk_setDeinitObserverIfNeeded(object : HasAssociatedSwift) {
        var witness = objc_getAssociatedObject(object, &Haneke.NSObject.denitiObserverKey) as DeallocWitness?
        if (witness == nil) {
            witness = DeallocWitness(object: object)
            objc_setAssociatedObject(object, &Haneke.NSObject.denitiObserverKey, witness, UInt(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
        }
    }
    
}
