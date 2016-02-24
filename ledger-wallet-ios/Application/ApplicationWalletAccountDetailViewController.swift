//
//  ApplicationWalletAccountDetailViewController.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 23/02/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

final class ApplicationWalletAccountDetailViewController: ApplicationViewController {
    
    var account: WalletAccount?
    private var fetchRequest: WalletFetchRequest<WalletVisibleAccountOperationsFetchRequestProvider>?
    private var operations: [WalletAccountOperationContainer] = []
    @IBOutlet private weak var tableView: UITableView!
    private var formatter = BTCNumberFormatter(bitcoinUnit: .BTC, symbolStyle: .Code)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        formatter.locale = NSLocale(localeIdentifier: "en-US")
        handleDidUpdateOperations()
    }
    
    override func handleDidUpdateOperations() {
        operations = []
        fetchRequest = nil
        context?.transactionsManager.fetchRequestBuilder.accountOperationsFetchRequestForAccountAtIndex(account!.index, incrementSize: 20, order: .Descending) { [weak self] fetchRequest in
            guard let strongSelf = self else { return }
            
            strongSelf.fetchRequest = fetchRequest
            strongSelf.updateModel()
        }
        updateUI()
    }
    
    private func updateModel(wantsNew: Bool = false) {
        fetchRequest?.objectsInRange((wantsNew ? self.operations.count : 0) ..< (wantsNew ? self.operations.count + 20 : 20)) { [weak self] objects in
            guard let strongSelf = self else { return }
            
            strongSelf.operations.appendContentsOf(objects!)
            strongSelf.updateUI()
        }
        updateUI()
    }
    
    private func updateUI() {
        navigationItem.title = "Account #\(account!.index)"
        tableView.reloadData()
    }
    
}

extension ApplicationWalletAccountDetailViewController: UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return operations.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("OperationCell", forIndexPath: indexPath)
        return cell
    }
    
}

extension ApplicationWalletAccountDetailViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        let operation = operations[indexPath.row]
        cell.textLabel?.text = operation.operationContainer.transactionContainer.transaction.receiveAt
        cell.detailTextLabel?.text = (operation.operationContainer.operation.kind == .Receive ? "+" : "-") + formatter.stringFromAmount(operation.operationContainer.operation.amount)
        
        if indexPath.row == operations.count - 1 && operations.count < fetchRequest!.numberOfObjects {
            updateModel(true)
        }
    }
    
}