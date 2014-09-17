//
//  UIImageView+Haneke.swift
//  Haneke
//
//  Created by Hermes Pique on 9/17/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import UIKit
import ObjectiveC

public extension Haneke {
    public struct UIKit {
        public struct DefaultFormat {
            public static let DiskCapacity : UInt64 = 10 * 1024 * 1024
            public static let CompressionQuality : Float = 0.75
        }
        static var entityKey = 0
    }
}

public extension UIImageView {
    
    public var hnk_format : Format {
        let viewSize = self.bounds.size
            assert(viewSize.width > 0 && viewSize.height > 0, "[\(reflect(self).summary) \(__FUNCTION__)]: UImageView size is zero. Set its frame, call sizeToFit or force layout first.")
            let scaleMode = self.hnk_scaleMode
            return UIImageView.hnk_formatWithSize(viewSize, scaleMode: scaleMode)
    }
    
    public func hnk_setImageFromEntity(entity : Entity, placeholder : UIImage? = nil, success doSuccess : ((UIImage) -> ())? = nil, failure doFailure : ((NSError?) -> ())? = nil) {

        self.hnk_entity = entity
        
        let didSetImage = self.hnk_fetchImageForEntity(entity, success: doSuccess, failure: doFailure)
        
        if didSetImage { return }
     
        if let placeholder = placeholder {
            self.image = placeholder
        }
    }
    
    // MARK: Internal
    
    var hnk_entity : Entity! {
        get {
            return objc_getAssociatedObject(self, &Haneke.UIKit.entityKey) as? Entity
        }
        set (entity) {
            objc_setAssociatedObject(self, &Haneke.UIKit.entityKey, entity, UInt(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
        }
    }
    
    var hnk_scaleMode : ScaleMode {
        switch (self.contentMode) {
        case .ScaleToFill:
            return .Fill
        case .ScaleAspectFit:
            return .AspectFit
        case .ScaleAspectFill:
            return .AspectFill
        case .Redraw, .Center, .Top, .Bottom, .Left, .Right, .TopLeft, .TopRight, .BottomLeft, .BottomRight:
            return .None
            }
    }
    
    class func hnk_formatWithSize(size : CGSize, scaleMode : ScaleMode) -> Format {
        let name = "auto-\(size.width)x\(size.height)-\(scaleMode.toRaw())"
        let cache = Haneke.sharedCache
        if let (format,_,_) = cache.formats[name] {
            return format
        }
        
        let format = Format(name,
            diskCapacity: Haneke.UIKit.DefaultFormat.DiskCapacity,
            size:size,
            scaleMode:scaleMode,
            compressionQuality: Haneke.UIKit.DefaultFormat.CompressionQuality)
        
        cache.addFormat(format)
        return format
    }
    
    func hnk_fetchImageForEntity(entity : Entity, success doSuccess : ((UIImage) -> ())?, failure doFailure : ((NSError?) -> ())?) -> Bool {
        let format = self.hnk_format
        let cache = Haneke.sharedCache
        var animated = false
        let didSetImage = cache.fetchImageForEntity(entity, formatName: format.name, success: {[weak self] (image) -> () in
            if let strongSelf = self {
                if strongSelf.hnk_shouldCancelForKey(entity.key) { return }
                
                strongSelf.hnk_setImage(image, animated:animated, success:doSuccess)
            }
        }, failure: {[weak self] (error) -> () in
            if let strongSelf = self {
                if strongSelf.hnk_shouldCancelForKey(entity.key) { return }
                
                strongSelf.hnk_entity = nil
                
                doFailure?(error)
            }
        })
        animated = true
        return didSetImage
    }
    
    func hnk_setImage(image : UIImage, animated : Bool, success doSuccess : ((UIImage) -> ())?) {
        self.hnk_entity = nil
        
        if let doSuccess = doSuccess {
            doSuccess(image)
        } else {
            let duration : NSTimeInterval = animated ? 0.1 : 0
            UIView.transitionWithView(self, duration: duration, options: .TransitionCrossDissolve, animations: {
                self.image = image
            }, completion: nil)
        }
    }
    
    func hnk_shouldCancelForKey(key:String) -> Bool {
        if self.hnk_entity.key == key { return false }
        
        NSLog("Cancelled set image for \(key.lastPathComponent)")
        return true
    }
    
}
