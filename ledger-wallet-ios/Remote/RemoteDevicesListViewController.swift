//
//  RemoteDevicesListViewController.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 22/01/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

final class RemoteDevicesListViewController: BaseViewController {
    
    var devicesManager: RemoteDevicesManager?
    @IBOutlet private weak var startButton: UIButton!
    @IBOutlet private weak var stopButton: UIButton!
    @IBOutlet private weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        startScanning()
        updateUI()
    }
    
    private func updateUI() {
        guard let devicesManager = devicesManager else { return }
        
        startButton.enabled = !devicesManager.isScanning
        stopButton.enabled = !startButton.enabled
    }
    
    @IBAction private func startScanning() {
        devicesManager?.startScanning()
        updateUI()
    }
    
    @IBAction private func stopScanning() {
        devicesManager?.stopScanning()
        updateUI()
    }
    
}