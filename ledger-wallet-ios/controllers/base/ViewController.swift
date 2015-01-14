//
//  ViewController.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 07/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    //MARK: Content status
    
    enum ContentStatus {
        case Default
        case Available
        case Loading
        case Empty
        case Error
    }
    
    private var _contentStatus = ContentStatus.Available
    var contentStatus: ContentStatus {
        return _contentStatus
    }
    var loadingView: UIView?
    var emptyView: UIView?
    var errorView: UIView?
    
    func updateViewForContentStatus(contentStatus: ContentStatus) {
        loadingView?.hidden = contentStatus != ContentStatus.Loading
        emptyView?.hidden = contentStatus != ContentStatus.Empty
        errorView?.hidden = contentStatus != ContentStatus.Error
    }
    
    func setNeedsContentStatus(contentStatus: ContentStatus) {
        if (contentStatus != self.contentStatus) {
            updateViewForContentStatus(contentStatus)
            _contentStatus = contentStatus
        }
    }
    
    func contentStatusViewsArea() -> CGRect {
        return self.view.bounds
    }
    
    func contentStatusViewFrame(view: UIView?) -> CGRect {
        if let view = view {
            let compressedSize = view.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize)
            let viewsArea = contentStatusViewsArea()
            return CGRectMake(viewsArea.origin.x, viewsArea.position.x, compressedSize.width, compressedSize.height)
        }
        return CGRectZero
    }
    
    //MARK: Status bar style
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    //MARK: Interface
    
    func updateView() {
        
    }
    
    func configureView() {

    }
    
    //MARK: Layout 
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // update content status views frame
        loadingView?.frame = contentStatusViewFrame(loadingView)
        emptyView?.frame = contentStatusViewFrame(emptyView)
        errorView?.frame = contentStatusViewFrame(errorView)
    }
    
    //MARK: View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // notify about content status
        let contentStatus = self.contentStatus
        configureView()
        if (self.contentStatus == contentStatus) {
            updateViewForContentStatus(contentStatus)
        }
    }

}

