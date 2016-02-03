//
//  RemoteDevicesListViewController.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 22/01/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

final class RemoteDevicesListViewController: BaseViewController {
    
    var devicesManager: RemoteDevicesManagerType!
    private var devices: [RemoteDeviceType] = []
    @IBOutlet private weak var startButton: UIButton!
    @IBOutlet private weak var stopButton: UIButton!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var statusLabel: UILabel!
    @IBOutlet private weak var sendButton: UIButton!
    @IBOutlet private weak var disconnectButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        devicesManager?.delegate = self
        startScanning()
    }
    
    private func updateUI() {
        guard let devicesManager = devicesManager else { return }
        
        startButton.enabled = !devicesManager.isScanning
        stopButton.enabled = !startButton.enabled
        tableView.reloadData()
        
        if devicesManager.connectionState != .Disconnected {
            startButton.enabled = false
            stopButton.enabled = false
        }
        
        switch devicesManager.connectionState {
        case .Connecting:
            statusLabel.text = "Connecting"
        case .Connected:
            statusLabel.text = "Connected"
        case .Disconnected:
            statusLabel.text = "Disconnected"
        }
        
        sendButton.enabled = devicesManager.connectionState == .Connected
        disconnectButton.enabled = sendButton.enabled
    }
    
    @IBAction private func startScanning() {
        devicesManager?.startScanning()
        updateUI()
    }
    
    @IBAction private func stopScanning() {
        devicesManager?.stopScanning()
        devices.removeAll()
        updateUI()
    }
    
    @IBAction private func sendHello() {
    }

    @IBAction private func disconnect() {
        devicesManager.disconnect()
    }
    
}

extension RemoteDevicesListViewController: RemoteDevicesManagerDelegate {
    
    func devicesManager(devicesManager: RemoteDevicesManagerType, didFindDevice device: RemoteDeviceType) {
        devices.append(device)
        updateUI()

    }
    
    func devicesManager(devicesManager: RemoteDevicesManagerType, didLoseDevice device: RemoteDeviceType) {
        if let index = devices.indexOf({ $0.uid == device.uid }) {
            devices.removeAtIndex(index)
            updateUI()
        }
    }
    
    func devicesManager(devicesManager: RemoteDevicesManagerType, didConnectDevice device: RemoteDeviceType) {
        updateUI()
    }
    
    func devicesManager(devicesManager: RemoteDevicesManagerType, didFailToConnectDevice device: RemoteDeviceType) {
        startScanning()
        updateUI()
    }
    
    func devicesManager(devicesManager: RemoteDevicesManagerType, didDisconnectDevice device: RemoteDeviceType, withError error: RemoteDevicesManagerError?) {
        startScanning()
        updateUI()
    }
    
    func devicesManager(devicesManager: RemoteDevicesManagerType, didSendData data: NSData, toDevice device: RemoteDeviceType) {
        print("SENT \(data)")
    }
    
    func devicesManager(devicesManager: RemoteDevicesManagerType, didReceiveData data: NSData, fromDevice device: RemoteDeviceType) {
        print("RECEIVED \(data)")
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
        devicesManager?.connect(device)
        updateUI()
    }
    
}