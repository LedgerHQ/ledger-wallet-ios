//
//  WalletTestViewController.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 25/11/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation
import UIKit

class WalletTestViewController: BaseViewController {
    
    var walletManager: WalletAPIManager!
    var timer: NSTimer!
    var stack: CoreDataStack!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        timer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: "t", userInfo: nil, repeats: true)
        NSRunLoop.currentRunLoop().addTimer(timer, forMode: NSRunLoopCommonModes)
    }

    dynamic func t() {
        let context = stack.newEphemeralManagedObjectContext()
        context.performBlock() {
            let request = WalletEntity.fetchRequestWithPredicate("identifier contains '2'")
            let c = context.countForFetchRequest(request, error: nil)
            print("c = \(c)")
        }
    }
    
}