//
//  PairingListTableViewCell.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 15/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

class PairingListTableViewCell: TableViewCell {
    
    @IBOutlet private weak var dongleTitleLabel: Label!
    @IBOutlet private weak var pairingDateLabel: Label!
 
    func configureWithPairingItem(pairingItem: PairingKeychainItem) {
        dongleTitleLabel?.text = pairingItem.dongleName!
        pairingDateLabel?.text = String(format: localizedString("paired_on_%@"), NSDateFormatter.localizedStringFromDate(pairingItem.creationDate, dateStyle: NSDateFormatterStyle.ShortStyle, timeStyle: NSDateFormatterStyle.ShortStyle))
    }
    
}
