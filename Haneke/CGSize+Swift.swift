//
//  CGSize+Swift.swift
//  Haneke
//
//  Created by Oriol Blanc Gimeno on 09/09/14.
//  Copyright (c) 2014 Haneke. All rights reserved.
//

import UIKit

extension CGSize {

    func hnk_aspectFillSize(_ size: CGSize) -> CGSize {
        let scaleWidth = size.width / self.width
        let scaleHeight = size.height / self.height
        let scale = max(scaleWidth, scaleHeight)

        let resultSize = CGSize(width: self.width * scale, height: self.height * scale)
        return CGSize(width: ceil(resultSize.width), height: ceil(resultSize.height))
    }

    func hnk_aspectFitSize(_ size: CGSize) -> CGSize {
        let targetAspect = size.width / size.height
        let sourceAspect = self.width / self.height
        var resultSize = size

        if (targetAspect > sourceAspect) {
            resultSize.width = size.height * sourceAspect
        }
        else {
            resultSize.height = size.width / sourceAspect
        }
        return CGSize(width: ceil(resultSize.width), height: ceil(resultSize.height))
    }
}
