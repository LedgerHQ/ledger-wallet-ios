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

final class PairingProtocolManager: BasePairingManager {
    
    enum PairingOutcome {
        case DongleSucceeded
        case DongleFailed
        case DongleTerminated
        case DeviceSucceeded
        case DeviceFailed
        case DeviceTerminated
        case ServerDisconnected
        case ServerTimeout
    }

    weak var delegate: PairingProtocolManagerDelegate? = nil
    private var context: PairingProtocolContext! = nil
    private lazy var cryptor = PairingProtocolCryptor()
    private var webSocket: WebSocket! = nil
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        ignoresTimeout = false
    }
    
    deinit {
        disconnectWebSocket()
        delegate?.pairingProtocolManager(self, didTerminateWithOutcome: PairingOutcome.DeviceTerminated)
    }
    
}

extension PairingProtocolManager {
    
    // MARK: - Pairing management
    
    func connectToRoomWithId(pairingId: String) {
        if (webSocket != nil) {
            return
        }
        
        // create websocket
        webSocket = WebSocket(url: NSURL(string: LedgerWebSocketBaseURL)!.URLByAppendingPathComponent("/2fa/channels"))
        webSocket.delegate = self
        webSocket.connect()
        
        // create context
        context = PairingProtocolContext(internalKey: Crypto.Key(), attestationKey: Crypto.Key(publicKey: LedgerDongleAttestationKeyData))
        
        // compute session key
        context.sessionKey = cryptor.sessionKeyForKeys(internalKey: context.internalKey, attestationKey: context.attestationKey)
        
        // retain pairing Id
        context.pairingId = pairingId

    }
    
    private func joinRoom() {
        if (webSocket == nil) {
            return
        }
        
        // send join message
        let message = messageWithType(MessageType.Join, data: ["room": context.pairingId])
        sendMessage(message, webSocket: webSocket)
    }
    
    private func sendPublicKey() {
        if (webSocket == nil) {
            return
        }
        
        // send public key
        let data = [
            "public_key": Crypto.Encode.base16StringFromData(context.internalKey.publicKey)!,
            "platform": "ios",
            "uuid": ApplicationManager.sharedInstance().UUID,
            "name": DeviceManager.sharedInstance().deviceName
        ]
        let message = messageWithType(MessageType.Identify, data: data)
        sendMessage(message, webSocket: webSocket)
    }
    
    func sendChallengeResponse(response: String) {
        if (webSocket == nil) {
            return
        }
        
        // create encrypted data response
        let encryptedData = cryptor.encryptedChallengeResponseDataFromChallengeString(response, nonce: context.nonce, sessionKey: context.sessionKey)
        
        // send challenge response
        if let encryptedDataBase16String = Crypto.Encode.base16StringFromData(encryptedData) {
            sendMessage(messageWithType(MessageType.Challenge, data: ["data": encryptedDataBase16String]), webSocket: webSocket)
        }
    }
    
    func terminate() {
        if (webSocket == nil) {
            return
        }
        
        // destroy websocket
        disconnectWebSocket()
        delegate?.pairingProtocolManager(self, didTerminateWithOutcome: PairingOutcome.DeviceTerminated)
    }
    
    func createNewPairingItemNamed(name: String) -> PairingKeychainItem? {
        return context.createPairingKeychainItemNamed(name)
    }
    
    private func disconnectWebSocket() {
        webSocket?.delegate = nil
        ignoresWebSocketDelegate = true
        if let isConnected = webSocket?.isConnected {
            if isConnected == true {
                webSocket?.disconnect()
            }
        }
        webSocket = nil
    }
    
}

extension PairingProtocolManager {
    
    // MARK: - Timeout management
    
    override func handleWebsocketTimeout() {
        disconnectWebSocket()
        delegate?.pairingProtocolManager(self, didTerminateWithOutcome: PairingOutcome.ServerTimeout)
    }
    
}

extension PairingProtocolManager {
    
    // MARK: - Messages management
    
    override func handleChallengeMessage(message: Message, webSocket: WebSocket) {
        if let dataString = message["data"] as? String {
            // get data
            if let blob = Crypto.Encode.dataFromBase16String(dataString) {
                // extract nonce and encrypted data
                context.nonce = cryptor.nonceFromBlob(blob)
                let encryptedData = cryptor.encryptedDataFromBlob(blob)
                
                // decrypt data
                let decryptedData = cryptor.decryptData(encryptedData, sessionKey: context.sessionKey)
                
                // extract challenge, pairing key
                let challengeData = cryptor.challengeDataFromDecryptedData(decryptedData)
                context.pairingKey = cryptor.pairingKeyFromDecryptedData(decryptedData)
                
                // create challenge string
                let challengeString = cryptor.challengeStringFromChallengeData(challengeData)
                
                // notify delegate
                delegate?.pairingProtocolManager(self, didReceiveChallenge: challengeString)
            }
        }
    }
    
    override func handlePairingMessage(message: Message, webSocket: WebSocket) {
        if let isSuccessful = message["is_successful"] as? Bool {
            disconnectWebSocket()
            delegate?.pairingProtocolManager(self, didTerminateWithOutcome: isSuccessful ? PairingOutcome.DongleSucceeded : PairingOutcome.DongleFailed)
        }
    }
    
    override func handleDisconnectMessage(message: Message, webSocket: WebSocket) {
        disconnectWebSocket()
        delegate?.pairingProtocolManager(self, didTerminateWithOutcome: PairingOutcome.DongleTerminated)
    }
    
    override func handleRepeatMessage(message: Message, webSocket: WebSocket) {
        if let message = lastSentMessage {
            sendMessage(message, webSocket: webSocket)
        }
    }
    
}

extension PairingProtocolManager {
    
    // MARK: - WebSocket messages management
    
    override func handleWebSocket(webSocket: WebSocket, didDisconnectWithError error: NSError?) {
        self.disconnectWebSocket()
        self.delegate?.pairingProtocolManager(self, didTerminateWithOutcome: PairingOutcome.ServerDisconnected)
    }
    
    override func handleWebSocketDidConnect(webSocket: WebSocket) {
        joinRoom()
        sendPublicKey()
    }
    
}