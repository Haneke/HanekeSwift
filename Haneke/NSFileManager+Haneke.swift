//
//  NSFileManager+Haneke.swift
//  Haneke
//
//  Created by Hermes Pique on 8/26/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import Foundation

extension NSFileManager {

    func enumerateContentsOfDirectoryAtPath(path : String, orderedByProperty property : String, ascending : Bool, usingBlock block : (NSURL, Int, inout Bool) -> Void ) {

        let directoryURL = NSURL(fileURLWithPath: path)
        if directoryURL == nil { return }
        var error : NSError?
        if let contents = self.contentsOfDirectoryAtURL(directoryURL!, includingPropertiesForKeys: [property], options: NSDirectoryEnumerationOptions.allZeros, error: &error) as? [NSURL] {

            let sortedContents = contents.sorted({(URL1 : NSURL, URL2 : NSURL) -> Bool in

                // Maybe there's a better way to do this. See: http://stackoverflow.com/questions/25502914/comparing-anyobject-in-swift

                var value1 : AnyObject?
                if !URL1.getResourceValue(&value1, forKey: property, error: nil) { return true }
                var value2 : AnyObject?
                if !URL2.getResourceValue(&value2, forKey: property, error: nil) { return false }


                if let string1 = value1 as? String {
                    if let string2 = value2 as? String {
                        return ascending ? string1 < string2 : string2 < string1
                    }
                }
                if let date1 = value1 as? NSDate {
                    if let date2 = value2 as? NSDate {
                        return ascending ? date1 < date2 : date2 < date1
                    }
                }

                if let number1 = value1 as? NSNumber {
                    if let number2 = value2 as? NSNumber {
                        return ascending ? number1 < number2 : number2 < number1
                    }
                }

                return false
            })

            for (i, v) in enumerate(sortedContents) {
                var stop : Bool = false
                block(v, i, &stop)
                if stop { break }
            }
        } else {
            Log.error("Failed to list directory", error)
        }
    }

}

func < (lhs: NSDate, rhs: NSDate) -> Bool {
    return lhs.compare(rhs) == NSComparisonResult.OrderedAscending
}

func < (lhs: NSNumber, rhs: NSNumber) -> Bool {
    return lhs.compare(rhs) == NSComparisonResult.OrderedAscending
}
