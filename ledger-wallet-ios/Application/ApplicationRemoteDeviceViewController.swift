//
//  ApplicationRemoteDeviceViewController.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 19/02/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

final class ApplicationRemoteDeviceViewController: ApplicationViewController {
    
    var deviceCommunicator: RemoteDeviceCommunicator?
    var acceptableIdentifier: String?
    var completionBlock: ((success: Bool, deviceCommunicator: RemoteDeviceCommunicator?, identifier: String?) -> Void)?
    @IBOutlet private weak var cancelButton: UIButton?
    @IBOutlet private weak var statusLabel: UILabel?
    @IBOutlet private weak var tableView: UITableView?
    @IBOutlet private weak var commentLabel: UILabel?
    private var devices: [RemoteDeviceType] = []

    @IBAction private func cancelButtonTouched() {
        guard acceptableIdentifier != nil else { return }
        
        completeWithSuccess(false, identifier: nil)
    }
    
    private func completeWithSuccess(success: Bool, identifier: String?) {
        if !success { stopAllRemoteDeviceActivity() }
        completionBlock?(success: success, deviceCommunicator: success ? deviceCommunicator : nil, identifier: success ? identifier : nil)
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    private func updateUI() {
        tableView?.reloadData()
        cancelButton?.hidden = acceptableIdentifier == nil
        if let deviceCommunicator = deviceCommunicator {
            statusLabel?.text = deviceCommunicator.isScanning ? "Scanning..." : "Connecting..."
            tableView?.userInteractionEnabled = deviceCommunicator.isScanning
        }
        else {
            statusLabel?.text = "Unknown"
            tableView?.userInteractionEnabled = true
        }
        
        if acceptableIdentifier != nil {
            commentLabel?.text = "Please reconnect your Ledger Blue to continue using your wallet on this device."
        }
        else {
            commentLabel?.text = "Please connect your Ledger Blue to open your wallet on this device."
        }
    }
    
    private func startScanning() {
        deviceCommunicator?.startScanningWithHandlerQueue(NSOperationQueue.mainQueue()) { [weak self] device, isFound in
            guard let strongSelf = self else { return }
            guard !strongSelf.isBeingDismissed() && !strongSelf.isBeingPresented() else { return }

            if isFound {
                strongSelf.devices.append(device)
                strongSelf.updateUI()
            }
            else if let index = strongSelf.devices.indexOf({ $0 === device }) {
                strongSelf.devices.removeAtIndex(index)
                strongSelf.updateUI()
            }
        }
    }
    
    private func stopAllRemoteDeviceActivity() {
        deviceCommunicator?.stopScanning()
        deviceCommunicator?.disconnect()
    }
    
    private func checkOrGetDeviceIdentifier() {
        deviceCommunicator?.deviceAPI?.verifyPIN(nil, timeoutInterval: 0, completionQueue: NSOperationQueue.mainQueue()) { [weak self] isVerified, remainingAttempts, error in
            guard let strongSelf = self else { return }
            guard isVerified else {
                strongSelf.alert("Wrong PIN code (remaining attemps = \(remainingAttempts)), disconnecting.\nPlease reboot device.")
                strongSelf.stopAllRemoteDeviceActivity()
                return
            }
            
            strongSelf.deviceCommunicator?.deviceAPI?.getIdentifier(completionQueue: NSOperationQueue.mainQueue()) { [weak self] identifier, error in
                guard let strongSelf = self else { return }
                guard let identifier = identifier where error == nil else {
                    strongSelf.alert("Unable to determine identifier, disconnecting")
                    strongSelf.stopAllRemoteDeviceActivity()
                    return
                }
                
                if let acceptedIdentifier = strongSelf.acceptableIdentifier {
                    if acceptedIdentifier == identifier {
                        strongSelf.completeWithSuccess(true, identifier: identifier)
                    }
                    else {
                        strongSelf.alert("Device identifier is not the expected one, disconnecting")
                        strongSelf.stopAllRemoteDeviceActivity()
                    }
                }
                else {
                    strongSelf.completeWithSuccess(true, identifier: identifier)
                }
            }
        }
    }
    
    private func connectDevice(device: RemoteDeviceType) {
        deviceCommunicator?.connect(device, handlerQueue: NSOperationQueue.mainQueue()) { [weak self] device, isConnected, error in
            guard let strongSelf = self else { return }
            guard !strongSelf.isBeingDismissed() && !strongSelf.isBeingPresented() else { return }
            
            if !isConnected {
                strongSelf.startScanning()
            }
            else {
                strongSelf.checkOrGetDeviceIdentifier()
            }
            strongSelf.updateUI()
        }
    }
    
    private func alert(message: String) {
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        startScanning()
        updateUI()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateUI()
    }
}

extension ApplicationRemoteDeviceViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        let device = devices[indexPath.row]
        cell.textLabel?.text = device.name
        cell.detailTextLabel?.text = String(device.transportType)
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let device = devices[indexPath.row]
        stopAllRemoteDeviceActivity()
        connectDevice(device)
        devices = []
        updateUI()
    }
    
}

extension ApplicationRemoteDeviceViewController: UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return devices.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("DeviceCell", forIndexPath: indexPath)
        return cell
    }
    
}