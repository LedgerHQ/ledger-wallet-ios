//
//  BarCodeReaderView.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 19/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit
import AVFoundation

protocol BarCodeReaderViewDelegate: class {
    
    func barCodeReaderView(barCodeReaderView: BarCodeReaderView, didScanCode code: String, withType type: String)

}

class BarCodeReaderView: View {
    
    private var previewLayer: AVCaptureVideoPreviewLayer {
        return layer as AVCaptureVideoPreviewLayer
    }
    weak var delegate: BarCodeReaderViewDelegate?
    var listensAppNotifications = true
    private(set) var isCapturing = false
    private var captureDevice: AVCaptureDevice?
    private var captureSession: AVCaptureSession?
    private var captureDeviceInput: AVCaptureDeviceInput?
    private var captureMetadataOutput: AVCaptureMetadataOutput?
    private var captureDispatchQueue: dispatch_queue_t?
    
    // MARK: Video Capture
    
    func startCapture() {
        if (isCapturing) {
            return
        }
        
        captureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        if (captureDevice == nil || captureDevice!.lockForConfiguration(nil) == false) {
            return
        }
        if (captureDevice!.focusPointOfInterestSupported) {
            captureDevice!.focusPointOfInterest = CGPointMake(0.5, 0.5)
        }
        captureDevice!.unlockForConfiguration()
        
        captureDeviceInput = AVCaptureDeviceInput.deviceInputWithDevice(captureDevice, error: nil) as? AVCaptureDeviceInput
        if (captureDeviceInput == nil) {
            cleanUp()
            return
        }
        
        captureMetadataOutput = AVCaptureMetadataOutput()
        if (captureMetadataOutput == nil) {
            cleanUp()
            return
        }
        captureMetadataOutput?.rectOfInterest = CGRectMake(0.1, 0.1, 0.7, 0.7)
        
        captureSession = AVCaptureSession()
        previewLayer.session = captureSession
        captureSession?.addInput(captureDeviceInput)
        captureSession?.addOutput(captureMetadataOutput)
        
        captureDispatchQueue = dispatch_get_main_queue()
        captureMetadataOutput?.setMetadataObjectsDelegate(self, queue: captureDispatchQueue)
        captureMetadataOutput?.metadataObjectTypes = [AVMetadataObjectTypeQRCode]

        captureSession?.startRunning()
        
        isCapturing = true
    }
    
    func stopCapture() {
        if (!isCapturing) {
            return
        }
        
        captureSession?.stopRunning()
        cleanUp()
        
        isCapturing = false
    }
    
    private func cleanUp() {
        captureDevice = nil
        captureDeviceInput = nil
        captureMetadataOutput = nil
        captureSession = nil
        captureDispatchQueue = nil
        previewLayer.session = nil
    }
    
    override class func layerClass() -> AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }

    // MARK: Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        initialize()
    }
    
    override init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        initialize()
    }
    
    private func initialize() {
        clipsToBounds = true
        backgroundColor = UIColor.blackColor()
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        listenNotifications(true)
    }
    
    deinit {
        listenNotifications(false)
    }
    
}

extension BarCodeReaderView {
    
    // MARK: Notifications
    
    private func listenNotifications(listen: Bool) {
        if (listen) {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleWillResignActiveNotification:", name: UIApplicationWillResignActiveNotification, object: UIApplication.sharedApplication())
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleDidBecomeActiveNotification:", name: UIApplicationDidBecomeActiveNotification, object: UIApplication.sharedApplication())
        }
        else {
            NSNotificationCenter.defaultCenter().removeObserver(self)
        }
    }
    
    private dynamic func handleWillResignActiveNotification(notification: NSNotification) {
        if (window != nil && listensAppNotifications) {
            stopCapture()
        }
    }
    
    private dynamic func handleDidBecomeActiveNotification(notification: NSNotification) {
        if (window != nil && listensAppNotifications) {
            startCapture()
        }
    }
    
}

extension BarCodeReaderView: AVCaptureMetadataOutputObjectsDelegate {
    
    // MARK: Metadata objects delegate
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        if let metadataObjects = metadataObjects {
            if (metadataObjects.count > 0) {
                if let metadataObject = metadataObjects[0] as? AVMetadataMachineReadableCodeObject {
                    if (metadataObject.type == AVMetadataObjectTypeQRCode) {
                        self.delegate?.barCodeReaderView(self, didScanCode: metadataObject.stringValue, withType: AVMetadataObjectTypeQRCode)
                    }
                }
            }
        }
    }
    
}
