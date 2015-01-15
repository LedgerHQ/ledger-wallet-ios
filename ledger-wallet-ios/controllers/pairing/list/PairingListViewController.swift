//
//  PairingListViewController.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 13/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

class PairingListViewController: ViewController {
    
    @IBOutlet weak var actionBar: ActionBarView!
    
    //MARK: Interface
    
    override func configureView() {
        super.configureView()
        
        actionBar.borderPosition = ActionBarView.BorderPosition.Top
    }
    
    override func updateView() {
        super.updateView()
        
        
    }
    
}

extension PairingListViewController: UITableViewDelegate, UITableViewDataSource {
    
    //MARK: Tableview methods
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("PairingListTableViewCell", forIndexPath: indexPath) as PairingListTableViewCell
        return cell
    }
    
}