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
        static var fetcherKey = 0
    }
}

var _associations : [COpaquePointer: Fetcher<UIImage>] = [:]

@objc protocol HasAssociatedSwift : class {
    
    func clearSwiftAssociations()
}

class DeallocWitness : NSObject {
    
    weak var object : HasAssociatedSwift!
    
    init (object: HasAssociatedSwift) {
        self.object = object
    }
    
    deinit {
        object.clearSwiftAssociations()
    }
}

var _DeallocWitnessKey: UInt8 = 0

func _setDeallocWitnessIfNeeded(object : NSObject) {
    var witness = objc_getAssociatedObject(object, &_DeallocWitnessKey) as DeallocWitness?
    if (witness == nil) {
        witness = DeallocWitness(object: object)
        objc_setAssociatedObject(object, &_DeallocWitnessKey, witness, UInt(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
    }
    
}

extension NSObject : HasAssociatedSwift {
    
    var associatedThing : Fetcher<UIImage>! {
        get {
            let key = getKey()
            return _associations[key]
        }
        set(thing) {
            let witness = DeallocWitness(object: self)
            objc_setAssociatedObject(self, &_DeallocWitnessKey, witness, UInt(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
            
            let key = getKey()
            _associations[key] = thing
        }
    }
    
    func getKey() -> COpaquePointer {
        let ptr: COpaquePointer =
        Unmanaged<AnyObject>.passUnretained(self).toOpaque()
        return ptr
    }
    
    func clearSwiftAssociations() {
        let key = getKey()
        _associations[key] = nil
    }
}

public extension UIImageView {
    
    public var hnk_format : Format<UIImage> {
        let viewSize = self.bounds.size
            assert(viewSize.width > 0 && viewSize.height > 0, "[\(reflect(self).summary) \(__FUNCTION__)]: UImageView size is zero. Set its frame, call sizeToFit or force layout first.")
            let scaleMode = self.hnk_scaleMode
            return UIImageView.hnk_formatWithSize(viewSize, scaleMode: scaleMode)
    }
    
    public func hnk_setImageFromURL(URL: NSURL, placeholder : UIImage? = nil, success doSuccess : ((UIImage) -> ())? = nil, failure doFailure : ((NSError?) -> ())? = nil) {
        let fetcher = NetworkFetcher<UIImage>(URL: URL)
        self.hnk_setImageFromFetcher(fetcher, placeholder: placeholder, success: doSuccess, failure: doFailure)
    }
    
    public func hnk_setImage(image: @autoclosure () -> UIImage, key : String, placeholder : UIImage? = nil, success doSuccess : ((UIImage) -> ())? = nil) {
        let fetcher = SimpleFetcher<UIImage>(key: key, thing: image)
        self.hnk_setImageFromFetcher(fetcher, placeholder: placeholder, success: doSuccess)
    }
    
    public func hnk_setImageFromFetcher(fetcher : Fetcher<UIImage>, placeholder : UIImage? = nil, success doSuccess : ((UIImage) -> ())? = nil, failure doFailure : ((NSError?) -> ())? = nil) {

        self.hnk_cancelSetImage()
        
        self.hnk_fetcher = fetcher
        
        let didSetImage = self.hnk_fetchImageForFetcher(fetcher, success: doSuccess, failure: doFailure)
        
        if didSetImage { return }
     
        if let placeholder = placeholder {
            self.image = placeholder
        }
    }
    
    public func hnk_cancelSetImage() {
        if let fetcher = self.hnk_fetcher {
            fetcher.cancelFetch()
            self.hnk_fetcher = nil
        }
    }
    
    // MARK: Internal
    
    var hnk_fetcher : Fetcher<UIImage>! {
        get {
            return self.associatedThing
        }
        set (fetcher) {
            self.associatedThing = fetcher
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
    
    class func hnk_formatWithSize(size : CGSize, scaleMode : ScaleMode) -> Format<UIImage> {
        let name = "auto-\(size.width)x\(size.height)-\(scaleMode.toRaw())"
        let cache = Haneke.sharedCache
        if let (format,_,_) = cache.formats[name] {
            return format
        }
        
        var format = Format<UIImage>(name,
            diskCapacity: Haneke.UIKit.DefaultFormat.DiskCapacity) {
                let resizer = ImageResizer(size:size,
                scaleMode:scaleMode,
                compressionQuality: Haneke.UIKit.DefaultFormat.CompressionQuality)
                return resizer.resizeImage($0)
        }
        format.convertToData = {(image : UIImage) -> NSData in
            image.hnk_data(compressionQuality: Haneke.UIKit.DefaultFormat.CompressionQuality)
        }
        cache.addFormat(format)
        return format
    }
    
    func hnk_fetchImageForFetcher(fetcher : Fetcher<UIImage>, success doSuccess : ((UIImage) -> ())?, failure doFailure : ((NSError?) -> ())?) -> Bool {
        let format = self.hnk_format
        let cache = Haneke.sharedCache
        var animated = false
        let didSetImage = cache.fetchValueForFetcher(fetcher, formatName: format.name, success: {[weak self] (image) -> () in
            if let strongSelf = self {
                if strongSelf.hnk_shouldCancelForKey(fetcher.key) { return }
                
                strongSelf.hnk_setImage(image, animated:animated, success:doSuccess)
            }
        }, failure: {[weak self] (error) -> () in
            if let strongSelf = self {
                if strongSelf.hnk_shouldCancelForKey(fetcher.key) { return }
                
                strongSelf.hnk_fetcher = nil
                
                doFailure?(error)
            }
        })
        animated = true
        return didSetImage
    }
    
    func hnk_setImage(image : UIImage, animated : Bool, success doSuccess : ((UIImage) -> ())?) {
        self.hnk_fetcher = nil
        
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
        if self.hnk_fetcher?.key == key { return false }
        
        NSLog("Cancelled set image for \(key.lastPathComponent)")
        return true
    }
    
}
