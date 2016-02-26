//
//  RemoteDevicesListViewController.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 22/01/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

final class RemoteDevicesListViewController: BaseViewController {
    
    var devicesCommunicator: RemoteDeviceCommunicator!
    private var devices: [RemoteDeviceType] = []
    @IBOutlet private weak var startButton: UIButton!
    @IBOutlet private weak var stopButton: UIButton!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var statusLabel: UILabel!
    @IBOutlet private weak var sendButton: UIButton!
    @IBOutlet private weak var disconnectButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        startScanning()
    }
    
    private func updateUI() {
        guard let devicesCommunicator = devicesCommunicator else { return }
        
        startButton.enabled = !devicesCommunicator.isScanning
        stopButton.enabled = !startButton.enabled
        tableView.reloadData()
        
        if devicesCommunicator.connectionState != .Disconnected {
            startButton.enabled = false
            stopButton.enabled = false
        }
        
        switch devicesCommunicator.connectionState {
        case .Connecting:
            statusLabel.text = "Connecting"
        case .Connected:
            statusLabel.text = "Connected to \(devicesCommunicator.activeDevice!.name)"
        case .Disconnected:
            statusLabel.text = "Disconnected"
        }
        
        sendButton.enabled = devicesCommunicator.connectionState == .Connected
        disconnectButton.enabled = devicesCommunicator.connectionState == .Connected || devicesCommunicator.connectionState == .Connecting
    }
    
    @IBAction private func startScanning() {
        devicesCommunicator?.startScanningWithHandlerQueue(NSOperationQueue.mainQueue()) { device, isFound in
            if isFound {
                self.devices.append(device)
                self.updateUI()
            }
            else if let index = self.devices.indexOf({ $0 === device }) {
                self.devices.removeAtIndex(index)
                self.updateUI()
            }
        }
        updateUI()
    }
    
    @IBAction private func stopScanning() {
        devicesCommunicator?.stopScanning()
        devices.removeAll()
        updateUI()
    }
    
    @IBAction private func sendHello() {
        devicesCommunicator?.deviceAPI?.verifyPIN(nil, completionQueue: NSOperationQueue.mainQueue()) { isVerified, remainingAttempts, error in
            print(isVerified, remainingAttempts, error)
        }
        let trustedInputs = [
            BTCDataFromHex("3200b9d62e1fe37ab16ff7a2b6e83e7216b4a25e033380e4be041d0748498c33f1ea6fa20000000000e1f5050000000041b0cdb6f877455d")!,
            BTCDataFromHex("3200dabc2e1fe37ab16ff7a2b6e83e7216b4a25e033380e4be041d0748498c33f1ea6fa2010000004a0d26ae000000009894f8d4eaf4471e")!
        ]
        self.devicesCommunicator?.deviceAPI?.startUntrustedHashTransactionInput(trustedInputs: trustedInputs, trustedInputIndex: 0, outputScript: BTCDataFromHex("76a914516360da56dc120dfbf10772c32c6c4d5955568a88ac"), completionQueue: NSOperationQueue.mainQueue()) { success, error in
            print(success, error)
        }
        self.devicesCommunicator?.deviceAPI?.startUntrustedHashTransactionInput(trustedInputs: trustedInputs, trustedInputIndex: 1, outputScript: BTCDataFromHex("76a91453e8ef1ab2db47b8e31fdfeeccd021cc09ab82c488ac"), completionQueue: NSOperationQueue.mainQueue()) { success, error in
            print(success, error)
        }
        
    }

    @IBAction private func disconnect() {
        devicesCommunicator?.disconnect()
    }
    
}

extension RemoteDevicesListViewController: UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return devices.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("device-cell", forIndexPath: indexPath)
        return cell
    }
    
}

extension RemoteDevicesListViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        let device = devices[indexPath.row]
        cell.textLabel?.text = device.name
        cell.detailTextLabel?.text = String(device.transportType)
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let device = devices[indexPath.row]
        stopScanning()
        devicesCommunicator?.connect(device, handlerQueue: NSOperationQueue.mainQueue()) { device, isConnected, error in
            if !isConnected {
                self.startScanning()
            }
            self.updateUI()
        }
        updateUI()
    }
    
}