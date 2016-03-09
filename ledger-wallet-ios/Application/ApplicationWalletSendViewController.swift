//
//  ApplicationWalletSendViewController.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 19/02/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

final class ApplicationWalletSendViewController: ApplicationViewController {
    
    @IBOutlet private weak var sendButton: UIButton!
    @IBOutlet private weak var accountControl: UISegmentedControl!
    @IBOutlet private weak var feesControl: UISegmentedControl!
    @IBOutlet private weak var addressTextField: UITextField!
    @IBOutlet private weak var amountTextField: UITextField!
    @IBOutlet private weak var cameraButton: UIBarButtonItem!
    private var builder: WalletTransactionBuilder?
    private var accounts: [WalletAccount] = []
    private var accountsFetchRequest: WalletFetchRequest<WalletVisibleAccountsFetchRequestProvider>?
    private var formatter = BTCNumberFormatter(bitcoinUnit: .BTC, symbolStyle: .None)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        formatter.locale = NSLocale(localeIdentifier: "en-US")
        updateUI()
    }
    
    @IBAction private func cameraButtonTouched() {
        let vc = ApplicationWalletScanViewController.instantiateFromMainStoryboard()
        vc.delegate = self
        presentViewController(vc, animated: true, completion: nil)
    }
    
    @IBAction private func sendButtonTouched() {
        guard let selectedAccountIndex = accountControl?.selectedSegmentIndex where selectedAccountIndex >= 0 else { return }
        guard let selectedFeesIndex = feesControl?.selectedSegmentIndex where selectedFeesIndex >= 0 else { return }
        let fees = formatter.amountFromString(feesControl.titleForSegmentAtIndex(selectedFeesIndex))
        let amount = formatter.amountFromString(amountTextField.text!)
        guard fees > 0 && amount > 0 else { return }
        guard let address = BTCAddress(string: addressTextField.text)?.string else { return }
        
        disableUI(true)
        ensureDeviceIsConnected() { [weak self] deviceAPI in
            guard let strongSelf = self else { return }
            
            guard let _ = deviceAPI else {
                strongSelf.disableUI(false)
                return
            }

            strongSelf.builder = WalletTransactionBuilder(servicesProvider: strongSelf.context!.servicesProvider, transactionsManager: strongSelf.context!.transactionsManager, deviceCommunicator: strongSelf.context!.deviceCommunicator)
            strongSelf.builder?.startTransaction(accountIndex: selectedAccountIndex, address: address, amount: amount, fees: fees, completionQueue: NSOperationQueue.mainQueue()) { [weak self] success, error in
                guard let strongSelf = self else { return }
                
                guard success else {
                    strongSelf.alert("Unable to start transaction, got error \(error)")
                    strongSelf.disableUI(false)
                    strongSelf.builder = nil
                    return
                }
            
                strongSelf.builder?.finalizeTransaction(completionQueue: NSOperationQueue.mainQueue()) { [weak self] rawTransaction, error in
                    guard let strongSelf = self else { return }
                    
                    guard let rawTransaction = rawTransaction else {
                        strongSelf.alert("Unable to finalize transaction, got error \(error)")
                        strongSelf.disableUI(false)
                        strongSelf.builder = nil
                        return
                    }
                    
                    strongSelf.builder?.pushTransaction(rawTransaction, completionQueue: NSOperationQueue.mainQueue()) { [weak self] success, error in
                        guard let strongSelf = self else { return }

                        if success == false {
                            strongSelf.alert("Unable to push raw transaction")
                        }
                        else {
                            strongSelf.alert("Successfully pushed raw transaction")
                        }
                        strongSelf.disableUI(false)
                        strongSelf.builder = nil
                    }
                }
            }
        }
    }
    
    private func disableUI(disable: Bool) {
        sendButton.enabled = !disable
        accountControl.enabled = !disable
        feesControl.enabled = !disable
        addressTextField.enabled = !disable
        amountTextField.enabled = !disable
        cameraButton.enabled = !disable
    }
    
    @IBAction private func accountControlDidChange() {
        
    }
    
    @IBAction private func feesControlDidChange() {
        
    }
    
    override func handleNewContext(context: ApplicationContext?) {
        handleDidUpdateAccounts()
    }
    
    override func handleDidUpdateAccounts() {
        updateModel()
    }
    
    private func updateModel() {
        accounts = []
        accountsFetchRequest = nil
        context?.transactionsManager.fetchRequestBuilder.accountsFetchRequestWithIncrementSize(20, order: .Ascending) { [weak self] fetchRequest in
            guard let strongSelf = self else { return }
            guard let fetchRequest = fetchRequest else { return }
            
            strongSelf.accountsFetchRequest = fetchRequest
            strongSelf.accountsFetchRequest?.allObjects() { [weak self] accounts in
                guard let strongSelf = self else { return }
                guard let accounts = accounts else { return }
            
                strongSelf.accounts = accounts
                strongSelf.updateUI()
            }
        }
        updateUI()
    }
    
    private func updateUI() {
        var selectedIndex = accountControl?.selectedSegmentIndex
        accountControl?.removeAllSegments()
        for (index, account) in accounts.enumerate() {
            accountControl?.insertSegmentWithTitle(String(account.index), atIndex: index, animated: false)
        }
        if selectedIndex == nil || selectedIndex == -1 { selectedIndex = 0 }
        if let selectedIndex = selectedIndex where accountControl?.numberOfSegments > selectedIndex {
            accountControl?.selectedSegmentIndex = selectedIndex
        }
        accountControlDidChange()
    }
    
    private func alert(message: String) {
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
        presentViewController(alertController, animated: true, completion: nil)
    }
    
}

extension ApplicationWalletSendViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension ApplicationWalletSendViewController: ApplicationWalletScanViewControllerDelegate {
    
    func walletScanViewController(walletScanViewController: ApplicationWalletScanViewController, didScanAddressAddress address: String, amount: Int64?) {
        addressTextField.text = address
        if let amount = amount {
            amountTextField.text = formatter.stringFromAmount(amount)
        }
    }
}