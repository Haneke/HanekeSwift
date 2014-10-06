//
//  UIButton+Haneke.swift
//  Haneke
//
//  Created by Joan Romano on 10/1/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import UIKit

public extension UIButton {
    
    public var hnk_backgroundImageFormat : Format<UIImage> {
        let bounds = self.bounds
            assert(bounds.size.width > 0 && bounds.size.height > 0, "[\(reflect(self).summary) \(__FUNCTION__)]: UIButton size is zero. Set its frame, call sizeToFit or force layout first.")
            let backgroundRect = self.backgroundRectForBounds(bounds)
            let imageSize = backgroundRect.size
            
            return UIButton.hnk_formatWithSize(imageSize, scaleMode: ScaleMode.Fill)
    }
    
    public func hnk_setBackgroundImageFromURL(URL : NSURL, state : UIControlState, placeholder : UIImage? = nil, failure fail : ((NSError?) -> ())? = nil, success succeed : ((UIImage) -> ())? = nil) {
        let fetcher = NetworkFetcher<UIImage>(URL: URL)
        self.hnk_setBackgroundImageFromFetcher(fetcher, state: state, placeholder: placeholder, failure: fail, success: succeed)
    }
    
    public func hnk_setBackgroundImage(image : UIImage, key : String, state : UIControlState, placeholder : UIImage? = nil, failure fail : ((NSError?) -> ())? = nil, success succeed : ((UIImage) -> ())? = nil) {
        let fetcher = SimpleFetcher<UIImage>(key: key, thing: image)
        self.hnk_setBackgroundImageFromFetcher(fetcher, state: state, placeholder: placeholder, failure : fail, success: succeed)
    }
    
    public func hnk_setBackgroundImageFromFile(path : String, state : UIControlState, placeholder : UIImage? = nil, failure fail : ((NSError?) -> ())? = nil, success succeed : ((UIImage) -> ())? = nil) {
        let fetcher = DiskFetcher<UIImage>(path: path)
        self.hnk_setBackgroundImageFromFetcher(fetcher, state: state, placeholder: placeholder, failure: fail, success: succeed)
    }
    
    public func hnk_setBackgroundImageFromFetcher(fetcher : Fetcher<UIImage>, state : UIControlState, placeholder : UIImage? = nil, failure fail : ((NSError?) -> ())? = nil, success succeed : ((UIImage) -> ())? = nil){
        self.hnk_cancelSetBackgroundImage()
        self.hnk_backgroundImageFetcher = fetcher
        
        let didSetImage = self.hnk_fetchBackgroundImageForFetcher(fetcher, state: state, failure: fail, success: succeed)
     
        if didSetImage { return }
        
        if let placeHolder = placeholder {
            self.setBackgroundImage(placeholder, forState: state)
        }
    }
    
    public func hnk_cancelSetBackgroundImage() {
        if let fetcher = self.hnk_backgroundImageFetcher {
            fetcher.cancelFetch()
            self.hnk_backgroundImageFetcher = nil
        }
    }
    
    // MARK: Internal
    
    // See: http://stackoverflow.com/questions/25907421/associating-swift-things-with-nsobject-instances
    var hnk_backgroundImageFetcher : Fetcher<UIImage>! {
        get {
            let wrapper = objc_getAssociatedObject(self, &Haneke.UIKit.SetImageFetcherKey) as? ObjectWrapper
            let fetcher = wrapper?.value as? Fetcher<UIImage>
            return fetcher
        }
        set (fetcher) {
            var wrapper : ObjectWrapper?
            if let fetcher = fetcher {
                wrapper = ObjectWrapper(value: fetcher)
            }
            objc_setAssociatedObject(self, &Haneke.UIKit.SetImageFetcherKey, wrapper, UInt(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
        }
    }
    
    class func hnk_formatWithSize(size : CGSize, scaleMode : ScaleMode) -> Format<UIImage> {
        let name = "auto-\(size.width)x\(size.height)-\(scaleMode.toRaw())"
        let cache = Haneke.sharedImageCache
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
    
    func hnk_fetchBackgroundImageForFetcher(fetcher : Fetcher<UIImage>, state : UIControlState, failure fail : ((NSError?) -> ())?, success succeed : ((UIImage) -> ())?) -> Bool {
        let format = self.hnk_backgroundImageFormat
        let cache = Haneke.sharedImageCache
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
                    
                    strongSelf.hnk_setBackgroundImage(image, state: state, animated: false, success: succeed)
                }
        }
        animated = true
        return fetch.hasSucceeded
    }
    
    func hnk_setBackgroundImage(image : UIImage, state : UIControlState, animated : Bool, success succeed : ((UIImage) -> ())?) {
        self.hnk_backgroundImageFetcher = nil
        
        if let succeed = succeed {
            succeed(image)
        } else {
            let duration : NSTimeInterval = animated ? 0.1 : 0
            UIView.transitionWithView(self, duration: duration, options: .TransitionCrossDissolve, animations: {
                self.setBackgroundImage(image, forState: state)
                }, completion: nil)
        }
    }
    
    func hnk_shouldCancelBackgroundImageForKey(key:String) -> Bool {
        if self.hnk_backgroundImageFetcher?.key == key { return false }
        
        NSLog("Cancelled set background image for \(key.lastPathComponent)")
        return true
    }
}
