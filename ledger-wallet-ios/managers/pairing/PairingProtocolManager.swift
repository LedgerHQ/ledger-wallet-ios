//
//  PairingProtocolManager.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 27/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

protocol PairingProtocolManagerDelegate: class {
    
    func pairingProtocolManager(pairingProtocolManager: PairingProtocolManager, didReceiveChallenge challenge: String)
    func pairingProtocolManager(pairingProtocolManager: PairingProtocolManager, didTerminateWithOutcome outcome: PairingProtocolManager.PairingOutcome)
    
}

class PairingProtocolManager: BasePairingManager {
    
    enum PairingOutcome {
        case DongleSucceeded
        case DongleFailed
        case DongleTerminated
        case DeviceSucceeded
        case DeviceFailed
        case DeviceTerminated
        case ServerDisconnected
    }
    
    weak var delegate: PairingProtocolManagerDelegate? = nil
    private var webSocket: JFRWebSocket! = nil
    
    // MARK: Pairing management
    
    func joinRoom(roomId: String) {
        if (webSocket != nil) {
            return
        }
        
        // create websocket
        webSocket = JFRWebSocket(URL: NSURL(string: "ws://192.168.2.107:8080"), protocols: nil)
        webSocket.delegate = self
        webSocket.connect()
        
        // send join message
        sendMessage(messageWithType(MessageType.Join, data: ["room": roomId]), webSocket: webSocket)
    }
    
    func sendPublicKey() {
        if (webSocket == nil) {
            return
        }
        
        // send public key
        sendMessage(messageWithType(MessageType.Identity, data: ["public_key": "key"]), webSocket: webSocket)
    }
    
    func sendChallengeResponse() {
        if (webSocket == nil) {
            return
        }
        
        // send challenge response
        sendMessage(messageWithType(MessageType.Challenge, data: ["data": "challenge"]), webSocket: webSocket)
    }
    
    func createNewPairingItemNamed(name: String) -> Bool {
        // TODO:
        return true
    }
    
    func terminate() {
        if (webSocket == nil) {
            return
        }
        
        // destroy websocket
        cleanUp()
        delegate?.pairingProtocolManager(self, didTerminateWithOutcome: PairingOutcome.DeviceTerminated)
    }
    
    // MARK: Initialization
    
    private func cleanUp() {
        webSocket?.delegate = nil
        webSocket?.disconnect()
        webSocket = nil
    }
    
    deinit {
        cleanUp()
        delegate?.pairingProtocolManager(self, didTerminateWithOutcome: PairingOutcome.DeviceTerminated)
    }
    
}

extension PairingProtocolManager {
    
    // MARK: Messages management
    
    override func handleChallengeMessage(message: Message) {
        if let dataString = message["data"] as? String {
            if let data = dataString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true) {
                delegate?.pairingProtocolManager(self, didReceiveChallenge: "1234")
            }
        }
    }
    
    override func handlePairingMessage(message: Message) {
        if let isSuccessful = message["is_successful"] as? Bool {
            cleanUp()
            delegate?.pairingProtocolManager(self, didTerminateWithOutcome: isSuccessful ? PairingOutcome.DongleSucceeded : PairingOutcome.DongleFailed)
        }
    }
    
    override func handleDisconnectMessage(message: Message) {
        cleanUp()
        delegate?.pairingProtocolManager(self, didTerminateWithOutcome: PairingOutcome.DongleTerminated)
    }
    
}

extension PairingProtocolManager {
    
    // MARK: WebSocket delegate
    
    override func handleWebSocket(webSocket: JFRWebSocket, didDisconnectWithError error: NSError?) {
        self.cleanUp()
        self.delegate?.pairingProtocolManager(self, didTerminateWithOutcome: PairingOutcome.ServerDisconnected)
    }
    
    override func handleWebsocket(webSocket: JFRWebSocket, didWriteError error: NSError?) {
        self.cleanUp()
        self.delegate?.pairingProtocolManager(self, didTerminateWithOutcome: PairingOutcome.ServerDisconnected)
    }
    
    override func handleWebSocket(webSocket: JFRWebSocket, didReceiveMessage message: String) {
        // retreive data from string
        if let data = message.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
            // create Message representation from data
            if let message = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.allZeros, error: nil) as? Message {
                self.receiveMessage(message)
            }
        }
    }
    
}