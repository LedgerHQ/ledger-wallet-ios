//
//  RemoteDevicesListViewController.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 22/01/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

final class RemoteDevicesListViewController: BaseViewController {
    
    var devicesCoordinator: RemoteDevicesCoordinator!
    private var devices: [RemoteDeviceType] = []
    @IBOutlet private weak var startButton: UIButton!
    @IBOutlet private weak var stopButton: UIButton!
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var statusLabel: UILabel!
    @IBOutlet private weak var sendButton: UIButton!
    @IBOutlet private weak var disconnectButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        devicesCoordinator?.delegate = self
        startScanning()
    }
    
    private func updateUI() {
        guard let devicesManager = devicesCoordinator else { return }
        
        startButton.enabled = !devicesCoordinator.isScanning
        stopButton.enabled = !startButton.enabled
        tableView.reloadData()
        
        if devicesManager.connectionState != .Disconnected {
            startButton.enabled = false
            stopButton.enabled = false
        }
        
        switch devicesCoordinator.connectionState {
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
        devicesCoordinator?.startScanning()
        updateUI()
    }
    
    @IBAction private func stopScanning() {
        devicesCoordinator?.stopScanning()
        devices.removeAll()
        updateUI()
    }
    
    @IBAction private func sendHello() {
        devicesCoordinator?.send(RemoteAPDU(hexString: "E0C4000000")!)
    }

    @IBAction private func disconnect() {
        devicesCoordinator.disconnect()
    }
    
}

extension RemoteDevicesListViewController: RemoteDevicesCoordinatorDelegate {
    
    func devicesCoordinator(devicesCoordinator: RemoteDevicesCoordinator, didFindDevice device: RemoteDeviceType) {
        devices.append(device)
        updateUI()
    }
    
    func devicesCoordinator(devicesCoordinator: RemoteDevicesCoordinator, didLoseDevice device: RemoteDeviceType) {
        if let index = devices.indexOf({ $0 === device }) {
            devices.removeAtIndex(index)
            updateUI()
        }
    }
    
    func devicesCoordinator(devicesCoordinator: RemoteDevicesCoordinator, didConnectDevice device: RemoteDeviceType) {
        updateUI()
    }
    
    func devicesCoordinator(devicesCoordinator: RemoteDevicesCoordinator, didFailToConnectDevice device: RemoteDeviceType) {
        startScanning()
        updateUI()
    }
    
    func devicesCoordinator(devicesCoordinator: RemoteDevicesCoordinator, didDisconnectDevice device: RemoteDeviceType, withError error: RemoteDeviceError?) {
        startScanning()
        updateUI()
    }
    
    func devicesCoordinator(devicesCoordinator: RemoteDevicesCoordinator, didSendAPDU APDU: RemoteAPDU, toDevice device: RemoteDeviceType) {

    }
    
    func devicesCoordinator(devicesCoordinator: RemoteDevicesCoordinator, didFailToSendAPDUToDevice device: RemoteDeviceType) {
        
    }
    
    func devicesCoordinator(devicesCoordinator: RemoteDevicesCoordinator, didReceiveAPDU APDU: RemoteAPDU, fromDevice device: RemoteDeviceType) {

    }
    
    func devicesCoordinator(devicesCoordinator: RemoteDevicesCoordinator, didFailToReceiveAPDUFromDevice device: RemoteDeviceType) {
        
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
        devicesCoordinator?.connect(device)
        updateUI()
    }
    
}