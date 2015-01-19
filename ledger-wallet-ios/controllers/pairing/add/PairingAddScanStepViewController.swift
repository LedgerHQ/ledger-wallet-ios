//
//  PairingAddScanStepViewController.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 16/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

class PairingAddScanStepViewController: PairingAddBaseStepViewController {
    
    @IBOutlet private weak var barCodeReader: BarCodeReaderView!
    
    override var stepIndication: String {
        return localizedString("scan_the_pairing_qr_code")
    }
    override var stepNumber: Int {
        return 1
    }

    //MARK: Interface
    
    override func configureView() {
        super.configureView()
        
        barCodeReader.delegate = self
    }
    
    //MARK: View lifecycle
    
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
    
    //MARK: Barcode reader delegate
    
    func barCodeReader(barCodeReader: BarCodeReaderView, didScanCode code: String, withType type: String) {
        println("\(code) in \(NSThread.currentThread())")
    }
    
}