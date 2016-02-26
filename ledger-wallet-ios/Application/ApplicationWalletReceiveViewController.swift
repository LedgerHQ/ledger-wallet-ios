//
//  ApplicationWalletReceiveViewController.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 19/02/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

final class ApplicationWalletReceiveViewController: ApplicationViewController {
    
    private var accounts: [WalletAccount] = []
    private var accountsFetchRequest: WalletFetchRequest<WalletVisibleAccountsFetchRequestProvider>?

    @IBOutlet private weak var accountsControl: UISegmentedControl!
    @IBOutlet private weak var addressImageView: UIImageView!
    @IBOutlet private weak var addressLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateUI()
    }
    
    override func handleNewContext(context: ApplicationContext?) {
        handleDidUpdateAccounts()
    }
    
    override func handleDidUpdateAccounts() {
        updateModel()
    }
    
    override func handleDidUpdateOperations() {
        updateModel()
    }
    
    @IBAction func accountsControlDidChange() {
        updateQRCode()
    }
    
    private func updateUI() {
        var selectedIndex = accountsControl?.selectedSegmentIndex
        accountsControl?.removeAllSegments()
        for (index, account) in accounts.enumerate() {
            accountsControl?.insertSegmentWithTitle(String(account.index), atIndex: index, animated: false)
        }
        if selectedIndex == nil || selectedIndex == -1 { selectedIndex = 0 }
        if let selectedIndex = selectedIndex where accountsControl?.numberOfSegments > selectedIndex {
            accountsControl?.selectedSegmentIndex = selectedIndex
        }
        accountsControlDidChange()
    }
    
    private func updateQRCode() {
        guard let selectedIndex = accountsControl?.selectedSegmentIndex where selectedIndex >= 0 else {
            return
        }
        
        context?.transactionsManager.getCurrentAddress(accountIndex: selectedIndex, external: true) { [weak self] address in
            guard let strongSelf = self else { return }
            guard let address = address else { return }
            
            let filter = CIFilter(name: "CIQRCodeGenerator")
            filter?.setValue(address.dataUsingEncoding(NSISOLatin1StringEncoding)!, forKey: "inputMessage")
            filter?.setValue("Q", forKey: "inputCorrectionLevel")
            
            guard var image = filter?.outputImage else { return }
            image = image.imageByApplyingTransform(CGAffineTransformMakeScale(5.0, 5.0))
            
            strongSelf.addressImageView?.image = UIImage(CIImage: image)
            strongSelf.addressLabel?.text = address
        }
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
    
}