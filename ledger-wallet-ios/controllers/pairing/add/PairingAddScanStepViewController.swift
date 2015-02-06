//
//  PairingAddScanStepViewController.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 16/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit
import AudioToolbox

class PairingAddScanStepViewController: PairingAddBaseStepViewController {
    
    @IBOutlet private weak var barCodeReader: BarCodeReaderView!
    
    override var stepIndication: String {
        return localizedString("scan_the_pairing_qr_code")
    }
    override var stepNumber: Int {
        return 1
    }

    // MARK: -  Interface
    
    override func configureView() {
        super.configureView()
        
        barCodeReader.delegate = self
        delayOnMainQueue(1.0) {
            self.barCodeReader?.stopCapture()
            self.notifyResult("holymacaroni")
        }
    }
    
    // MARK: -  View lifecycle
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        barCodeReader.startCapture()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        barCodeReader.stopCapture()
    }
    
}

extension PairingAddScanStepViewController: BarCodeReaderViewDelegate {
    
    // MARK: -  Barcode reader delegate
    
    func barCodeReaderView(barCodeReaderView: BarCodeReaderView, didScanCode code: String, withType type: String) {
        // TODO: check that code is correct
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        barCodeReader?.stopCapture()
        notifyResult(code)
    }
    
}