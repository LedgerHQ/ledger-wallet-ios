//
//  ViewController.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 07/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    var loadingView: UIView?
    var emptyView: UIView?
    var errorView: UIView?
    lazy private var _contentStatus: ContentStatus = { return self.initialContentStatus() }()
    private var _keyboardFrame: CGRect?
    
    //MARK: Presentation
    
    @IBAction func cancel() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func complete() {
        dismissViewControllerAnimated(true, completion: nil)
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
        layoutContentStatusViews()
    }
    
    //MARK: View lifecycle
    
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

}

extension ViewController {
    
    //MARK: Keyboard management
    
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
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleKeyboardWillShowNotification", name: UIKeyboardWillShowNotification, object: UIApplication.sharedApplication())
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleKeyboardWillHideNotification", name: UIKeyboardWillHideNotification, object: UIApplication.sharedApplication())
        }
        else {
            NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: UIApplication.sharedApplication())
            NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: UIApplication.sharedApplication())
        }
    }
    
    private func handleKeyboardWillShowNotification(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            if let frame = userInfo[UIKeyboardFrameEndUserInfoKey]?.CGRectValue() {
                _keyboardFrame = frame
            }
            keyboardWillShow(userInfo)
        }
    }
    
    private func handleKeyboardWillHideNotification(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            keyboardWillHide(userInfo)
        }
        _keyboardFrame = nil
    }
    
}

extension ViewController {
    
    //MARK: Content status
    
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