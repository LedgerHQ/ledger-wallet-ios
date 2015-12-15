//
//  PairingAddScanStepViewController.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 16/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

final class PairingAddScanStepViewController: PairingAddBaseStepViewController {
    
    @IBOutlet private weak var barCodeReader: BarCodeReaderView!
    
    override var stepIndication: String {
        return localizedString("scan_the_pairing_qr_code")
    }
    override var stepNumber: Int {
        return 1
    }

    // MARK: Interface
    
    override func configureView() {
        super.configureView()
        
        barCodeReader.delegate = self
    }
    
    // MARK: View lifecycle
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        barCodeReader.startCapture()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        barCodeReader.stopCapture()
    }
    
}

// MARK: - BarCodeReaderViewDelegate

extension PairingAddScanStepViewController: BarCodeReaderViewDelegate {
    
    func barCodeReaderView(barCodeReaderView: BarCodeReaderView, didScanCode code: String, withType type: String) {
        // check that code is correct
        if let data = BTCDataFromHex(code) {
            if data.length == 17 {
                let subData = data.subdataWithRange(NSMakeRange(0, 16))
                let checksum = data.subdataWithRange(NSMakeRange(16, 1))
                let computedChecksum = BTCSHA256(subData)
                if (computedChecksum.length == 32 && computedChecksum.subdataWithRange(NSMakeRange(0, 1)) == checksum) {
                    DeviceManager.sharedInstance.vibrate()
                    barCodeReader?.stopCapture()
                    notifyResult(code)
                }
            }
        }
    }
    
}