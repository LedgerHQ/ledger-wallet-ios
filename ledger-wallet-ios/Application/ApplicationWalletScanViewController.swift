//
//  ApplicationWalletScanViewController.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 08/03/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

protocol ApplicationWalletScanViewControllerDelegate: class {
    
    func walletScanViewController(walletScanViewController: ApplicationWalletScanViewController, didScanAddressAddress address: String, amount: Int64?)
    
}

final class ApplicationWalletScanViewController: ApplicationViewController {

    weak var delegate: ApplicationWalletScanViewControllerDelegate?
    @IBOutlet private weak var scanView: BarCodeReaderView?
    
    @IBAction private func cancelButtonTouched() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scanView?.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        scanView?.startCapture()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        scanView?.stopCapture()
    }
    
}

extension ApplicationWalletScanViewController: BarCodeReaderViewDelegate {
    
    func barCodeReaderView(barCodeReaderView: BarCodeReaderView, didScanCode code: String, withType type: String) {
        let code = code.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        if let _ = BTCAddress(string: code) {
            delegate?.walletScanViewController(self, didScanAddressAddress: code, amount: nil)
            cancelButtonTouched()
            DeviceManager.sharedInstance.vibrate()
        }
        else if let URL = BTCBitcoinURL(URL: NSURL(string: code)), address = URL.address?.string {
            delegate?.walletScanViewController(self, didScanAddressAddress: address, amount: URL.amount == 0 ? nil : URL.amount)
            cancelButtonTouched()
            DeviceManager.sharedInstance.vibrate()
        }
    }
    
}