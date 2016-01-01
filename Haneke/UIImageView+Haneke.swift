//
//  UIImageView+Haneke.swift
//  Haneke
//
//  Created by Hermes Pique on 9/17/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import UIKit

public extension UIImageView {
    
    public var hnk_format : Format<UIImage> {
        let viewSize = self.bounds.size
            assert(viewSize.width > 0 && viewSize.height > 0, "[\(Mirror(reflecting: self).description) \(__FUNCTION__)]: UImageView size is zero. Set its frame, call sizeToFit or force layout first.")
            let scaleMode = self.hnk_scaleMode
            return HanekeGlobals.UIKit.formatWithSize(viewSize, scaleMode: scaleMode)
    }
    
    public func hnk_setImageFromURL(URL: NSURL, placeholder : UIImage? = nil, format : Format<UIImage>? = nil, failure fail : ((NSError?) -> ())? = nil, success succeed : ((UIImage) -> ())? = nil) {
        let fetcher = NetworkFetcher<UIImage>(URL: URL)
        self.hnk_setImageFromFetcher(fetcher, placeholder: placeholder, format: format, failure: fail, success: succeed)
    }
    
    public func hnk_setImage(@autoclosure(escaping) image: () -> UIImage, key: String, placeholder : UIImage? = nil, format : Format<UIImage>? = nil, success succeed : ((UIImage) -> ())? = nil) {
        let fetcher = SimpleFetcher<UIImage>(key: key, value: image)
        self.hnk_setImageFromFetcher(fetcher, placeholder: placeholder, format: format, success: succeed)
    }
    
    public func hnk_setImageFromFile(path: String, placeholder : UIImage? = nil, format : Format<UIImage>? = nil, failure fail : ((NSError?) -> ())? = nil, success succeed : ((UIImage) -> ())? = nil) {
        let fetcher = DiskFetcher<UIImage>(path: path)
        self.hnk_setImageFromFetcher(fetcher, placeholder: placeholder, format: format, failure: fail, success: succeed)
    }
    
    public func hnk_setImageFromFetcher(fetcher : Fetcher<UIImage>,
        placeholder : UIImage? = nil,
        format : Format<UIImage>? = nil,
        failure fail : ((NSError?) -> ())? = nil,
        success succeed : ((UIImage) -> ())? = nil) {

        self.hnk_cancelSetImage()
        
        self.hnk_fetcher = fetcher
        
        let didSetImage = self.hnk_fetchImageForFetcher(fetcher, format: format, failure: fail, success: succeed)
        
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
    
    // See: http://stackoverflow.com/questions/25907421/associating-swift-things-with-nsobject-instances
    var hnk_fetcher : Fetcher<UIImage>! {
        get {
            let wrapper = objc_getAssociatedObject(self, &HanekeGlobals.UIKit.SetImageFetcherKey) as? ObjectWrapper
            let fetcher = wrapper?.value as? Fetcher<UIImage>
            return fetcher
        }
        set (fetcher) {
            var wrapper : ObjectWrapper?
            if let fetcher = fetcher {
                wrapper = ObjectWrapper(value: fetcher)
            }
            objc_setAssociatedObject(self, &HanekeGlobals.UIKit.SetImageFetcherKey, wrapper, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    public var hnk_scaleMode : ImageResizer.ScaleMode {
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

    func hnk_fetchImageForFetcher(fetcher : Fetcher<UIImage>, format : Format<UIImage>? = nil, failure fail : ((NSError?) -> ())?, success succeed : ((UIImage) -> ())?) -> Bool {
        let cache = Shared.imageCache
        let format = format ?? self.hnk_format
        if cache.formats[format.name] == nil {
            cache.addFormat(format)
        }
        var animated = false
        let fetch = cache.fetch(fetcher: fetcher, formatName: format.name, failure: {[weak self] error in
            if let strongSelf = self {
                if strongSelf.hnk_shouldCancelForKey(fetcher.key) { return }
                
                strongSelf.hnk_fetcher = nil
                
                fail?(error)
            }
        }) { [weak self] image in
            if let strongSelf = self {
                if strongSelf.hnk_shouldCancelForKey(fetcher.key) { return }
                
                strongSelf.hnk_setImage(image, animated: animated, success: succeed)
            }
        }
        animated = true
        return fetch.hasSucceeded
    }
    
    func hnk_setImage(image : UIImage, animated : Bool, success succeed : ((UIImage) -> ())?) {
        self.hnk_fetcher = nil
        
        if let succeed = succeed {
            succeed(image)
        } else if animated {
            UIView.transitionWithView(self, duration: HanekeGlobals.UIKit.SetImageAnimationDuration, options: .TransitionCrossDissolve, animations: {
                self.image = image
            }, completion: nil)
        } else {
            self.image = image
        }
    }
    
    func hnk_shouldCancelForKey(key:String) -> Bool {
        if self.hnk_fetcher?.key == key { return false }
        
        Log.debug("Cancelled set image for \((key as NSString).lastPathComponent)")
        return true
    }
    
}
