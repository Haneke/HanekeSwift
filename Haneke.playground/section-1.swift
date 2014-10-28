// Open this playground from the Haneke workspace after building the Haneke framework. See: http://stackoverflow.com/a/24049021/143378
// The playground will compile and offer code completion. Unfortunately, as of Xcode 6.0.1 there appears to be a bug that prevents the playground to execute.

import Haneke

/// Initialize a JSON cache and fetch/cache a JSON response.
func example1() {
    let cache = Cache<JSON>(name: "github")
    let URL = NSURL(string: "https://api.github.com/users/haneke")!
    
    cache.fetch(URL: URL).onSuccess { JSON in
        println(JSON.dictionary?["bio"])
    }
}

/// Set a image view image from a url using the shared image cache and resizing.
func example2() {
    let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
    let URL = NSURL(string: "https://avatars.githubusercontent.com/u/8600207?v=2")!

    imageView.hnk_setImageFromURL(URL)
}

/// Set and fetch data from the shared data cache
func example3() {
    let cache = Haneke.sharedDataCache
    let data = "SGVscCEgSSdtIHRyYXBwZWQgaW4gYSBCYXNlNjQgc3RyaW5nIQ==".asData()
    
    cache.set(value: data, key: "secret")
    
    cache.fetch(key: "secret").onSuccess { data in
        println(NSString(data:data, encoding:NSUTF8StringEncoding))
    }
}
