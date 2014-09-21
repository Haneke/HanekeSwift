![Haneke](https://raw.githubusercontent.com/Haneke/HanekeSwift/master/Assets/github-header.png)

Haneke is lightweight generic cache for iOS written in Swift. It also includes a zero-config image cache with automatic resizing.

Haneke resizes images and caches the result on memory and disk. Everything is done in background, allowing for fast, responsive scrolling. Asking Haneke to load, resize, cache and display an *appropriately sized image* is as simple as:

```swift
imageView.hnk_setImageFromURL(url)
```

_Really._

##Features

* First-level memory cache using `NSCache`.
* Second-level LRU disk cache using the file system.
* Asynchronous fetching.
* All disk access is performed in background.
* Thread-safe.
* Automatic cache eviction on memory warnings or disk capacity reached.

For images:

* Zero-config `UIImageView` category to use the cache, optimized for `UITableView` and `UICollectionView` cell reuse.
* Background image resizing.


##UIImageView category

Haneke provides convenience methods for `UIImageView` with optimizations for `UITableView` and `UICollectionView` cell reuse. Images will be resized appropriately and cached in a shared cache.

```swift
// Setting a remote image
imageView.hnk_setImageFromURL(url)

// Setting an image manually. Requires you to provide a key.
imageView.hnk_setImage(image, key: key)
```

The above lines take care of:

1. If cached, retrieving an appropriately sized image (based on the `bounds` and `contentMode` of the `UIImageView`) from the memory or disk cache. Disk access is performed in background.
2. If not cached, loading the original image from web/memory and producing an appropriately sized image, both in background. Remote images will be retrieved from the shared `NSURLCache` if available.
3. Setting the image and animating the change if appropriate.
4. Or doing nothing if the `UIImageView` was reused during any of the above steps.
5. Caching the resulting image.
6. If needed, evicting the least recently used images in the cache.

##Roadmap

Haneke Swift is in initial development and its public API should not be considered stable.

##License

 Copyright 2014 Hermes Pique ([@hpique](https://twitter.com/hpique))    
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2014 Joan Romano ([@joanromano](https://twitter.com/joanromano))   
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2014 Luis Lascorbe ([@lascorbe](https://twitter.com/Lascorbe))   
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2014 Oriol Blanc ([@oriolblanc](https://twitter.com/oriolblanc))   
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
