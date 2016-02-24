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
    private var accounts: [WalletAccount] = []
    private var accountsFetchRequest: WalletFetchRequest<WalletVisibleAccountsFetchRequestProvider>?
    private var formatter = BTCNumberFormatter(bitcoinUnit: .BTC, symbolStyle: .None)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        formatter.locale = NSLocale(localeIdentifier: "en-US")
        updateUI()
    }
    
    @IBAction private func sendButtonTouched() {
        guard let selectedIndex = accountControl?.selectedSegmentIndex else { return }
        let fees = formatter.amountFromString(feesControl.titleForSegmentAtIndex(selectedIndex))
        let amount = formatter.amountFromString(amountTextField.text!)
        guard fees > 0 && amount > 0 else { return }
        
        disableUI(true)
        context?.transactionsManager.collectUnspentOutputsFromAccountAtIndex(selectedIndex, amount: fees + amount) { [weak self] outputs, error in
            guard let strongSelf = self else { return }
            guard let outputs = outputs where error == nil else {
                strongSelf.alert("Unable to collect UTXO \(error)")
                strongSelf.disableUI(false)
                return
            }
            
            
        }
    }
    
    private func disableUI(disable: Bool) {
        sendButton.enabled = !disable
        accountControl.enabled = !disable
        feesControl.enabled = !disable
        addressTextField.enabled = !disable
        amountTextField.enabled = !disable
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