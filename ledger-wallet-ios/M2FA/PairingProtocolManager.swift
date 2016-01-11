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

final class PairingProtocolManager: BaseM2FAManager {
    
    enum PairingOutcome {
        
        case DongleSucceeded
        case DongleFailed
        case DongleTerminated
        case DeviceSucceeded
        case DeviceFailed
        case DeviceTerminated
        case ServerDisconnected
        case ServerTimeout
        case WrongData
        
    }

    weak var delegate: PairingProtocolManagerDelegate? = nil
    private var context: PairingProtocolContext! = nil
    private var cryptor: PairingProtocolCryptor! = nil
    private var webSocket: WebSocket! = nil
    
    // MARK: Initialization
    
    init(servicesProvider: ServiceProviderType) {
        super.init()
        ignoresTimeout = false
    }
    
    deinit {
        disconnectWebSocket()
        delegate?.pairingProtocolManager(self, didTerminateWithOutcome: PairingOutcome.DeviceTerminated)
    }
    
}

// MARK: - Pairing management

extension PairingProtocolManager {
    
    func connectToRoomWithId(pairingId: String) {
        if (webSocket != nil) {
            return
        }
        
        // create websocket
        logger.info("Connecting websocket with room id \(pairingId)")
        webSocket = WebSocket(url: NSURL(string: LedgerWebsocketBaseURL)!.URLByAppendingPathComponent("/2fa/channels"))
        webSocket.delegate = self
        webSocket.connect()
        
        // create context and cryptor
        cryptor = PairingProtocolCryptor()
        context = PairingProtocolContext(internalKey: BTCKey())
        
        // retain pairing Id
        context.pairingId = pairingId
    }
    
    private func joinRoom() {
        guard webSocket != nil && context.pairingId != nil else {
            return
        }
        
        // send join message
        let message = messageWithType(MessageType.Join, data: ["room": context.pairingId])
        sendMessage(message, webSocket: webSocket)
    }
    
    private func sendPublicKey() {
        guard webSocket != nil else {
            return
        }
        
        // send public key
        let data = [
            "public_key": BTCHexFromData(context.internalKey.publicKey)!,
            "platform": "ios",
            "uuid": ApplicationManager.sharedInstance.UUID,
            "name": DeviceManager.sharedInstance.deviceName
        ]
        let message = messageWithType(MessageType.Identify, data: data)
        sendMessage(message, webSocket: webSocket)
    }
    
    func sendChallengeResponse(response: String) {
        guard webSocket != nil && context.sessionKey != nil && context.nonce != nil else {
            return
        }
        
        // create encrypted data response
        let encryptedData = cryptor.encryptedChallengeResponseDataFromChallengeString(response, nonce: context.nonce, sessionKey: context.sessionKey)
        
        // send challenge response
        if let encryptedDataBase16String = BTCHexFromData(encryptedData) {
            logger.info("Sending challenge response \"****\"")
            sendMessage(messageWithType(MessageType.Challenge, data: ["data": encryptedDataBase16String]), webSocket: webSocket)
        }
    }
    
    func terminate() {
        guard webSocket != nil else {
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
        if let isConnected = webSocket?.isConnected where isConnected == true {
            webSocket?.disconnect()
        }
        webSocket = nil
    }
    
}

// MARK: - Timeout management

extension PairingProtocolManager {
    
    override func handleWebsocketTimeout() {
        logger.error("Timeout, aborting")
        disconnectWebSocket()
        delegate?.pairingProtocolManager(self, didTerminateWithOutcome: PairingOutcome.ServerTimeout)
    }
    
}

// MARK: - Attestation keys management

extension PairingProtocolManager {
    
    private func fetchLedgerAttestationKeyFromIDs(batchID batchID: UInt32, derivationID: UInt32) -> AttestationKey? {
        for attestationKey in LedgerDeviceAttestationKeys {
            if attestationKey.batchID == batchID && attestationKey.derivationID == derivationID {
                return attestationKey
            }
        }
        return nil
    }
    
}

// MARK: - Messages management

extension PairingProtocolManager {
    
    override func handleChallengeMessage(message: Message, webSocket: WebSocket) {
        guard let
            dataString = message["data"] as? String, blobData = BTCDataFromHex(dataString)
        else {
            disconnectWebSocket()
            logger.info("Received wrong challenge message \"\(message)\"")
            delegate?.pairingProtocolManager(self, didTerminateWithOutcome: .WrongData)
            return
        }
        
        // try to get attestation key from message, or fallback
        let finalAttestationKey: AttestationKey
        if let attestationString = message["attestation"] as? String, attestationData = BTCDataFromHex(attestationString),
            attestationKeyIDs = cryptor.attestationKeyIDsWithData(attestationData),
            attestationKey = fetchLedgerAttestationKeyFromIDs(batchID: attestationKeyIDs.batchID, derivationID: attestationKeyIDs.derivationID) {
            finalAttestationKey = attestationKey
        }
        else {
            finalAttestationKey = fetchLedgerAttestationKeyFromIDs(batchID: 0x02, derivationID: 0x01)!
        }
        
        // compute session + external key
        context.externalKey = BTCKey(publicKey: finalAttestationKey.publicKey)
        context.sessionKey = cryptor.sessionKeyForKeys(internalKey: context.internalKey, externalKey: context.externalKey)
        
        // extract nonce and encrypted data
        context.nonce = cryptor.nonceFromBlob(blobData)
        let encryptedData = cryptor.encryptedDataFromBlob(blobData)
        
        // decrypt data
        let decryptedData = cryptor.decryptData(encryptedData, sessionKey: context.sessionKey)
        
        // extract challenge, pairing key
        let challengeData = cryptor.challengeDataFromDecryptedData(decryptedData)
        context.pairingKey = cryptor.pairingKeyFromDecryptedData(decryptedData)
        
        // test challenge data 
        if !cryptor.challengeDataIsValid(challengeData) {
            disconnectWebSocket()
            logger.info("Decrypted challenge data is invalid")
            delegate?.pairingProtocolManager(self, didTerminateWithOutcome: .WrongData)
            return
        }
        
        // create challenge string
        let challengeString = cryptor.challengeStringFromChallengeData(challengeData)
        
        // notify delegate
        logger.info("Received challenge \"\(challengeString)\"")
        delegate?.pairingProtocolManager(self, didReceiveChallenge: challengeString)
    }
    
    override func handlePairingMessage(message: Message, webSocket: WebSocket) {
        if let isSuccessful = message["is_successful"] as? Bool {
            disconnectWebSocket()
            logger.info("Pairing completed successfully? \(isSuccessful)")
            delegate?.pairingProtocolManager(self, didTerminateWithOutcome: isSuccessful ? PairingOutcome.DongleSucceeded : PairingOutcome.DongleFailed)
        }
        else {
            disconnectWebSocket()
            logger.info("Received wrong pairing message \"\(message)\"")
            delegate?.pairingProtocolManager(self, didTerminateWithOutcome: .WrongData)
        }
    }
    
    override func handleDisconnectMessage(message: Message, webSocket: WebSocket) {
        disconnectWebSocket()
        logger.info("Other peer disconnected, aborting")
        delegate?.pairingProtocolManager(self, didTerminateWithOutcome: PairingOutcome.DongleTerminated)
    }
    
    override func handleRepeatMessage(message: Message, webSocket: WebSocket) {
        if let message = lastSentMessage {
            sendMessage(message, webSocket: webSocket)
        }
    }
    
}

// MARK: - WebSocket messages management

extension PairingProtocolManager {
    
    override func handleWebSocket(webSocket: WebSocket, didDisconnectWithError error: NSError?) {
        logger.info("Websocket disconnected, aborting")
        self.disconnectWebSocket()
        self.delegate?.pairingProtocolManager(self, didTerminateWithOutcome: PairingOutcome.ServerDisconnected)
    }
    
    override func handleWebSocketDidConnect(webSocket: WebSocket) {
        logger.info("Websocket connected, sending identity")
        joinRoom()
        sendPublicKey()
    }
    
}