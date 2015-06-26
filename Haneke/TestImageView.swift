//
//  TestImageView.swift
//  Haneke
//
//  Created by Paulo Ferreira on 26/06/15.
//  Copyright (c) 2015 Haneke. All rights reserved.
//
import UIKit

class TestImageView: UIImageView {
    deinit {
        NSLog("##oink")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        NSLog("init")
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}