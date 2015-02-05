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
    private var webSocketURL = LedgerWebSocketURL
    private var pairingId: String? = nil
    private let peerPublicKey = LedgerDongleAttestationKeyData
    private var publicKey: NSData? = nil
    private var privateKey: NSData? = nil
    private var pairingSecret: NSData? = nil
    private var sessionKey: NSData? = nil
    
    // MARK: Pairing management
    
    func joinRoom(pairingId: String) {
        if (webSocket != nil) {
            return
        }
        
        // create websocket
        webSocket = JFRWebSocket(URL: NSURL(string: webSocketURL), protocols: nil)
        webSocket.delegate = self
        webSocket.connect()
        
        // send join message
        self.pairingId = pairingId
        let message = messageWithType(MessageType.Join, data: ["room": pairingId])
        sendMessage(message, webSocket: webSocket)
    }
    
    func sendPublicKey() {
        if (webSocket == nil) {
            return
        }
        
        // generate public key
        if (publicKey == nil || privateKey == nil) {
            let key = Crypto.Key()
            publicKey = key.publicKey
            privateKey = key.privateKey
        }
        
        // compute secret
        
        
        // send public key
        let message = messageWithType(MessageType.Identity, data: ["public_key": Crypto.Encode.base16StringFromData(publicKey!)])
        sendMessage(message, webSocket: webSocket)
    }
    
    func sendChallengeResponse(response: String) {
        if (webSocket == nil) {
            return
        }
        
        // send challenge response
        sendMessage(messageWithType(MessageType.Challenge, data: ["data": response]), webSocket: webSocket)
    }
    
    func canCreatePairingItemNamed(name: String) -> Bool {
        let allItems = PairingKeychainItem.fetchAll() as [PairingKeychainItem]
        
        for item in allItems {
            if item.dongleName == name {
                return false
            }
        }
        return true
    }
    
    func createNewPairingItemNamed(name: String) -> Bool {
        if (canCreatePairingItemNamed(name) == false) {
            return false
        }
        
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
    
    // MARK: Testing
    
    func setTestKeys(#publicKey: NSData, privateKey: NSData) {
        self.publicKey = publicKey
        self.privateKey = privateKey
    }
    
    func setTestWebSocketURL(url: String) {
        self.webSocketURL = url
    }
    
    func setEnvironementIsTest(value: Bool) {
        PairingKeychainItem.testEnvironment = value
    }
    
    // MARK: Initialization
    
    private func cleanUp() {
        webSocket?.delegate = nil
        webSocket?.disconnect()
        webSocket = nil
        publicKey = nil
        privateKey = nil
        pairingId = nil
        pairingSecret = nil
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
    
    override func handleRepeatMessage(message: Message) {
        if let message = lastSentMessage {
            sendMessage(message, webSocket: webSocket)
        }
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