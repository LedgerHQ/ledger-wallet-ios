//
//  BaseViewController.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 07/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

class BaseViewController: UIViewController {
    
    var loadingView: UIView?
    var emptyView: UIView?
    var errorView: UIView?
    lazy private var _contentStatus: ContentStatus = { return self.initialContentStatus() }()
    private var _keyboardFrame: CGRect?
    
    // MARK: - Presentation
    
    @IBAction func cancel() {
    
    }
    
    @IBAction func complete() {

    }
    
    // MARK: - Status bar style
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    // MARK: - Interface
    
    func updateView() {
        
    }
    
    func configureView() {

    }
    
    // MARK: - Model
    
    func updateModel() {
        
    }
    
    // MARK: - Layout 
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        // resize navigation items
        self.navigationItem.leftBarButtonItem?.customView?.sizeToFit()
        self.navigationItem.rightBarButtonItem?.customView?.sizeToFit()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // update content status views frame
        layoutContentStatusViews()
    }
    
    // MARK: - View lifecycle
    
    override func loadView() {
        super.loadView()
        
        // load content status views
        loadContentStatusViews()
        
        // insert content status views in hierarchy
        insertContentStatusViewsInHierarchy()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // configure main view
        configureView()
        updateView()
        
        // notify about content status
        updateViewForContentStatus(contentStatus)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        observeKeyboardNotifications(true)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        observeKeyboardNotifications(false)
    }
}

extension BaseViewController {
    
    // MARK: - Keyboard management
    
    var keyboardFrame: CGRect {
        if let frame = _keyboardFrame {
            return frame
        }
        return CGRectZero
    }
    var isKeyboardShown: Bool {
        return _keyboardFrame != nil
    }
    
    func keyboardWillShow(userInfo: [NSObject: AnyObject]) {
        
    }
    
    func keyboardWillHide(userInfo: [NSObject: AnyObject]) {
        
    }
    
    private func observeKeyboardNotifications(observe: Bool) {
        if (observe) {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleKeyboardWillShowNotification:", name: UIKeyboardWillShowNotification, object: nil)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleKeyboardWillHideNotification:", name: UIKeyboardWillHideNotification, object: nil)
        }
        else {
            NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
            NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
        }
    }
    
    private dynamic func handleKeyboardWillShowNotification(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            if let frame = userInfo[UIKeyboardFrameEndUserInfoKey]?.CGRectValue {
                _keyboardFrame = frame
            }
            keyboardWillShow(userInfo)
        }
    }
    
    private dynamic func handleKeyboardWillHideNotification(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            keyboardWillHide(userInfo)
        }
        _keyboardFrame = nil
    }
    
}

extension BaseViewController {
    
    // MARK: - Content status
    
    enum ContentStatus {
        case Available
        case Loading
        case Empty
        case Error
    }
    
    var contentStatus: ContentStatus {
        return _contentStatus
    }
    
    func initialContentStatus() -> ContentStatus {
        return ContentStatus.Available
    }
    
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
            return CGRectMake(
                viewsArea.origin.x + ((viewsArea.size.width - compressedSize.width) / 2),
                viewsArea.origin.y + ((viewsArea.size.height - compressedSize.height) / 2),
                compressedSize.width,
                compressedSize.height
            )
        }
        return CGRectZero
    }
    
    func loadContentStatusViews() {
        
    }
    
    private func insertContentStatusViewsInHierarchy() {
        if (loadingView != nil) {
            view.addSubview(loadingView!)
        }
        if (emptyView != nil) {
            view.addSubview(emptyView!)
        }
        if (errorView != nil) {
            view.addSubview(errorView!)
        }
    }
    
    private func layoutContentStatusViews() {
        loadingView?.frame = contentStatusViewFrame(loadingView)
        emptyView?.frame = contentStatusViewFrame(emptyView)
        errorView?.frame = contentStatusViewFrame(errorView)
    }

}