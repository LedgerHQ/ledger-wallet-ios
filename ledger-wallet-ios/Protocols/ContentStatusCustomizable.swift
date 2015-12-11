//
//  ContentStatusCustomizable.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 22/09/15.
//  Copyright © 2015 Ledger. All rights reserved.
//

import UIKit
import Foundation

enum ContentStatus {
    
    case Available
    case Loading
    case Empty
    case Error
    
}

protocol ContentStatusCustomizable: class {
    
    var contentStatus: ContentStatus { get }
    
    func setNeedsContentStatus(contentStatus: ContentStatus)
    func updateViewForContentStatus(contentStatus: ContentStatus)
    func contentStatusViewsArea() -> CGRect
    func contentStatusViewFrame(view: UIView?) -> CGRect
    func loadContentStatusViews()
    func insertContentStatusViewsInHierarchy()
    func layoutContentStatusViews()
    
}

extension ContentStatusCustomizable {
  
    func contentStatusViewFrame(view: UIView?) -> CGRect {
        if let view = view {
            let compressedSize = view.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize)
            let viewsArea = contentStatusViewsArea()
            return CGRectMake(
                viewsArea.origin.x + ((viewsArea.size.width - compressedSize.width) / 2),
                viewsArea.origin.y + ((viewsArea.size.height - compressedSize.height) / 2),
                compressedSize.width,
                compressedSize.height
            )
        }
        return CGRectZero
    }
    
}