//
//  UIButton+Haneke.swift
//  Haneke
//
//  Created by Joan Romano on 10/1/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import UIKit

public extension UIButton {
    
    public var hnk_imageFormat : Format<UIImage> {
        let bounds = self.bounds
        assert(bounds.size.width > 0 && bounds.size.height > 0, "[\(Mirror(reflecting: self).description) \(__FUNCTION__)]: UIButton size is zero. Set its frame, call sizeToFit or force layout first. You can also set a custom format with a defined size if you don't want to force layout.")
            let contentRect = self.contentRectForBounds(bounds)
            let imageInsets = self.imageEdgeInsets
            let scaleMode = self.contentHorizontalAlignment != UIControlContentHorizontalAlignment.Fill || self.contentVerticalAlignment != UIControlContentVerticalAlignment.Fill ? ImageResizer.ScaleMode.AspectFit : ImageResizer.ScaleMode.Fill
            let imageSize = CGSizeMake(CGRectGetWidth(contentRect) - imageInsets.left - imageInsets.right, CGRectGetHeight(contentRect) - imageInsets.top - imageInsets.bottom)
            
            return HanekeGlobals.UIKit.formatWithSize(imageSize, scaleMode: scaleMode, allowUpscaling: scaleMode == ImageResizer.ScaleMode.AspectFit ? false : true)
    }
    
    public func hnk_setImageFromURL(URL: NSURL, state: UIControlState = .Normal, placeholder: UIImage? = nil, format: Format<UIImage>? = nil, failure fail: ((NSError?) -> ())? = nil, success succeed: ((UIImage) -> ())? = nil) {
        let fetcher = NetworkFetcher<UIImage>(URL: URL)
        self.hnk_setImageFromFetcher(fetcher, state: state, placeholder: placeholder, format: format, failure: fail, success: succeed)
    }
    
    public func hnk_setImage(image: UIImage, key: String, state: UIControlState = .Normal, placeholder: UIImage? = nil, format: Format<UIImage>? = nil, success succeed: ((UIImage) -> ())? = nil) {
        let fetcher = SimpleFetcher<UIImage>(key: key, value: image)
        self.hnk_setImageFromFetcher(fetcher, state: state, placeholder: placeholder, format: format, success: succeed)
    }
    
    public func hnk_setImageFromFile(path: String, state: UIControlState = .Normal, placeholder: UIImage? = nil, format: Format<UIImage>? = nil, failure fail: ((NSError?) -> ())? = nil, success succeed: ((UIImage) -> ())? = nil) {
        let fetcher = DiskFetcher<UIImage>(path: path)
        self.hnk_setImageFromFetcher(fetcher, state: state, placeholder: placeholder, format: format, failure: fail, success: succeed)
    }
    
    public func hnk_setImageFromFetcher(fetcher: Fetcher<UIImage>, state: UIControlState = .Normal, placeholder: UIImage? = nil, format: Format<UIImage>? = nil, failure fail: ((NSError?) -> ())? = nil, success succeed: ((UIImage) -> ())? = nil){
        self.hnk_cancelSetImage()
        self.hnk_imageFetcher = fetcher
        
        let didSetImage = self.hnk_fetchImageForFetcher(fetcher, state: state, format : format, failure: fail, success: succeed)
        
        if didSetImage { return }
        
        if let placeholder = placeholder {
            self.setImage(placeholder, forState: state)
        }
    }
    
    public func hnk_cancelSetImage() {
        if let fetcher = self.hnk_imageFetcher {
            fetcher.cancelFetch()
            self.hnk_imageFetcher = nil
        }
    }
    
    // MARK: Internal Image
    
    // See: http://stackoverflow.com/questions/25907421/associating-swift-things-with-nsobject-instances
    var hnk_imageFetcher : Fetcher<UIImage>! {
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
    
    func hnk_fetchImageForFetcher(fetcher : Fetcher<UIImage>, state : UIControlState = .Normal, format : Format<UIImage>? = nil, failure fail : ((NSError?) -> ())?, success succeed : ((UIImage) -> ())?) -> Bool {
        let format = format ?? self.hnk_imageFormat
        let cache = Shared.imageCache
        if cache.formats[format.name] == nil {
            cache.addFormat(format)
        }
        var animated = false
        let fetch = cache.fetch(fetcher: fetcher, formatName: format.name, failure: {[weak self] error in
            if let strongSelf = self {
                if strongSelf.hnk_shouldCancelImageForKey(fetcher.key) { return }
                
                strongSelf.hnk_imageFetcher = nil
                
                fail?(error)
            }
            }) { [weak self] image in
                if let strongSelf = self {
                    if strongSelf.hnk_shouldCancelImageForKey(fetcher.key) { return }
                    
                    strongSelf.hnk_setImage(image, state: state, animated: animated, success: succeed)
                }
        }
        animated = true
        return fetch.hasSucceeded
    }
    
    
    func hnk_setImage(image : UIImage, state : UIControlState, animated : Bool, success succeed : ((UIImage) -> ())?) {
        self.hnk_imageFetcher = nil
        
        if let succeed = succeed {
            succeed(image)
        } else if animated {
            UIView.transitionWithView(self, duration: HanekeGlobals.UIKit.SetImageAnimationDuration, options: .TransitionCrossDissolve, animations: {
                self.setImage(image, forState: state)
                }, completion: nil)
        } else {
            self.setImage(image, forState: state)
        }
    }
    
    func hnk_shouldCancelImageForKey(key:String) -> Bool {
        if self.hnk_imageFetcher?.key == key { return false }
        
        Log.debug("Cancelled set image for \((key as NSString).lastPathComponent)")
        return true
    }
    
    // MARK: Background image
        
    public var hnk_backgroundImageFormat : Format<UIImage> {
        let bounds = self.bounds
        assert(bounds.size.width > 0 && bounds.size.height > 0, "[\(Mirror(reflecting: self).description) \(__FUNCTION__)]: UIButton size is zero. Set its frame, call sizeToFit or force layout first. You can also set a custom format with a defined size if you don't want to force layout.")
            let imageSize = self.backgroundRectForBounds(bounds).size
            
            return HanekeGlobals.UIKit.formatWithSize(imageSize, scaleMode: .Fill)
    }
    
    public func hnk_setBackgroundImageFromURL(URL : NSURL, state : UIControlState = .Normal, placeholder : UIImage? = nil, format : Format<UIImage>? = nil, failure fail : ((NSError?) -> ())? = nil, success succeed : ((UIImage) -> ())? = nil) {
        let fetcher = NetworkFetcher<UIImage>(URL: URL)
        self.hnk_setBackgroundImageFromFetcher(fetcher, state: state, placeholder: placeholder, format: format, failure: fail, success: succeed)
    }
    
    public func hnk_setBackgroundImage(image : UIImage, key: String, state : UIControlState = .Normal, placeholder : UIImage? = nil, format : Format<UIImage>? = nil, success succeed : ((UIImage) -> ())? = nil) {
        let fetcher = SimpleFetcher<UIImage>(key: key, value: image)
        self.hnk_setBackgroundImageFromFetcher(fetcher, state: state, placeholder: placeholder, format: format, success: succeed)
    }
    
    public func hnk_setBackgroundImageFromFile(path: String, state : UIControlState = .Normal, placeholder : UIImage? = nil, format : Format<UIImage>? = nil, failure fail : ((NSError?) -> ())? = nil, success succeed : ((UIImage) -> ())? = nil) {
        let fetcher = DiskFetcher<UIImage>(path: path)
        self.hnk_setBackgroundImageFromFetcher(fetcher, state: state, placeholder: placeholder, format: format, failure: fail, success: succeed)
    }
    
    public func hnk_setBackgroundImageFromFetcher(fetcher : Fetcher<UIImage>, state : UIControlState = .Normal, placeholder : UIImage? = nil, format : Format<UIImage>? = nil, failure fail : ((NSError?) -> ())? = nil, success succeed : ((UIImage) -> ())? = nil){
        self.hnk_cancelSetBackgroundImage()
        self.hnk_backgroundImageFetcher = fetcher
        
        let didSetImage = self.hnk_fetchBackgroundImageForFetcher(fetcher, state: state, format : format, failure: fail, success: succeed)
     
        if didSetImage { return }
        
        if let placeholder = placeholder {
            self.setBackgroundImage(placeholder, forState: state)
        }
    }
    
    public func hnk_cancelSetBackgroundImage() {
        if let fetcher = self.hnk_backgroundImageFetcher {
            fetcher.cancelFetch()
            self.hnk_backgroundImageFetcher = nil
        }
    }
    
    // MARK: Internal Background image
    
    // See: http://stackoverflow.com/questions/25907421/associating-swift-things-with-nsobject-instances
    var hnk_backgroundImageFetcher : Fetcher<UIImage>! {
        get {
            let wrapper = objc_getAssociatedObject(self, &HanekeGlobals.UIKit.SetBackgroundImageFetcherKey) as? ObjectWrapper
            let fetcher = wrapper?.value as? Fetcher<UIImage>
            return fetcher
        }
        set (fetcher) {
            var wrapper : ObjectWrapper?
            if let fetcher = fetcher {
                wrapper = ObjectWrapper(value: fetcher)
            }
            objc_setAssociatedObject(self, &HanekeGlobals.UIKit.SetBackgroundImageFetcherKey, wrapper, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func hnk_fetchBackgroundImageForFetcher(fetcher: Fetcher<UIImage>, state: UIControlState = .Normal, format: Format<UIImage>? = nil, failure fail: ((NSError?) -> ())?, success succeed : ((UIImage) -> ())?) -> Bool {
        let format = format ?? self.hnk_backgroundImageFormat
        let cache = Shared.imageCache
        if cache.formats[format.name] == nil {
            cache.addFormat(format)
        }
        var animated = false
        let fetch = cache.fetch(fetcher: fetcher, formatName: format.name, failure: {[weak self] error in
            if let strongSelf = self {
                if strongSelf.hnk_shouldCancelBackgroundImageForKey(fetcher.key) { return }
                
                strongSelf.hnk_backgroundImageFetcher = nil
                
                fail?(error)
            }
            }) { [weak self] image in
                if let strongSelf = self {
                    if strongSelf.hnk_shouldCancelBackgroundImageForKey(fetcher.key) { return }
                    
                    strongSelf.hnk_setBackgroundImage(image, state: state, animated: animated, success: succeed)
                }
        }
        animated = true
        return fetch.hasSucceeded
    }
    
    func hnk_setBackgroundImage(image: UIImage, state: UIControlState, animated: Bool, success succeed: ((UIImage) -> ())?) {
        self.hnk_backgroundImageFetcher = nil
        
        if let succeed = succeed {
            succeed(image)
        } else if animated {
            UIView.transitionWithView(self, duration: HanekeGlobals.UIKit.SetImageAnimationDuration, options: .TransitionCrossDissolve, animations: {
                self.setBackgroundImage(image, forState: state)
                }, completion: nil)
        } else {
            self.setBackgroundImage(image, forState: state)
        }
    }
    
    func hnk_shouldCancelBackgroundImageForKey(key: String) -> Bool {
        if self.hnk_backgroundImageFetcher?.key == key { return false }
        
        Log.debug("Cancelled set background image for \((key as NSString).lastPathComponent)")
        return true
    }
}
