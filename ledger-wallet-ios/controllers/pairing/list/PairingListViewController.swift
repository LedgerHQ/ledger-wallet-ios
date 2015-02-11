//
//  PairingListViewController.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 13/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

class PairingListViewController: BaseViewController {
    
    @IBOutlet private weak var actionBar: ActionBarView!
    @IBOutlet private weak var tableView: TableView!
    
    private var pairingKeychainItems: [PairingKeychainItem] = []

    // MARK: - Interface
    
    override func configureView() {
        super.configureView()
        
        actionBar.borderPosition = ActionBarView.BorderPosition.Bottom
    }

    // MARK: - Model
    
    override func updateModel() {
        
    }
    
    // MARK: - View lifecycle
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        updateModel()
        updateView()
    }
    
}

extension PairingListViewController: UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - UITableview delegate, data source
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(PairingListTableViewCell.className(), forIndexPath: indexPath) as! PairingListTableViewCell
        return cell
    }
    
}