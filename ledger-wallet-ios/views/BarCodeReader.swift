//
//  BarCodeReader.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 19/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit
import AVFoundation

protocol BarCodeReader {
    
    @optional func barCodeReader(barCodeReader: BarCodeReader, didScanCode: String,
    
}

class BarCodeReader: View, AVCaptureMetadataOutputObjectsDelegate {
    
    var isCapturing: Bool {
        return _isCapturing
    }
    private var previewLayer: AVCaptureVideoPreviewLayer {
        return layer as AVCaptureVideoPreviewLayer
    }
    private var _isCapturing = false
    private var captureDevice: AVCaptureDevice?
    private var captureSession: AVCaptureSession?
    private var captureDeviceInput: AVCaptureDeviceInput?
    private var captureMetadataOutput: AVCaptureMetadataOutput?
    private var captureDispatchQueue: dispatch_queue_t?

    
    //MARK: Video Capture
    
    func startCapture() {
        if (isCapturing) {
            return
        }
        
        captureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        if (captureDevice == nil) {
            return
        }
        
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
        
        captureSession = AVCaptureSession()
        previewLayer.session = captureSession
        captureSession?.addInput(captureDeviceInput)
        captureSession?.addOutput(captureMetadataOutput)
        
        captureDispatchQueue = dispatch_queue_create("co.ledger.barcodereader.captureQueue", DISPATCH_QUEUE_SERIAL)
        captureMetadataOutput?.setMetadataObjectsDelegate(self, queue: captureDispatchQueue)
        captureMetadataOutput?.metadataObjectTypes = [AVMetadataObjectTypeQRCode]

        captureSession?.startRunning()
        
        _isCapturing = true
    }
    
    func stopCapture() {
        if (!isCapturing) {
            return
        }
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
    
    //MARK: Metadata objects delegate
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        if let metadataObjects = metadataObjects {
            if (metadataObjects.count > 0) {
                if let metadataObject = metadataObjects[0] as? AVMetadataMachineReadableCodeObject {
                    if (metadataObject.type == AVMetadataObjectTypeQRCode) {
                        dispatch_async(dispatch_get_main_queue(), {
                            
                        })
                    }
                }
            }
        }
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
    }
    
}
