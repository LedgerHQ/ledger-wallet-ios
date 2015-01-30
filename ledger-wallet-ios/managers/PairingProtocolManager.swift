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

class PairingProtocolManager: BaseManager {
    
    enum PairingOutcome {
        case DongleSucceeded
        case DongleFailed
        case DeviceTerminated
        case DongleTerminated
        case ServerDisconnected
    }
    
    private typealias Message = [String: AnyObject]
    private typealias MessageHandler = (Message) -> Void
    private enum MessageType: String {
        case Join = "join"
        case Identity = "identity"
        case Challenge = "challenge"
        case Pairing = "pairing"
        case Disconnect = "disconnect"
    }
    
    weak var delegate: PairingProtocolManagerDelegate? = nil
    private var webSocket: JFRWebSocket? = nil
    private let messagesHandlers: [MessageType: (PairingProtocolManager) -> MessageHandler] = [
        MessageType.Challenge: handleChallengeMessage,
        MessageType.Pairing: handlePairingMessage,
        MessageType.Disconnect: handleDisconnectMessage
    ]
    
    // MARK: Pairing management
    
    func joinRoom(roomId: String, completion: ((success: Bool) -> Void)? = nil) {
        if (webSocket != nil) {
            return
        }
        
        // create websocket
        webSocket = JFRWebSocket(URL: NSURL(string: "ws://192.168.2.107:8080"), protocols: nil)
        webSocket?.delegate = self
        webSocket?.connect()
        
        // send join message
        sendMessage(messageWithType(MessageType.Join, data: ["room": roomId]))
    }
    
    func sendPublicKey() {
        if (webSocket == nil) {
            return
        }
        
        // send public key
        sendMessage(messageWithType(MessageType.Identity, data: ["public_key": "key"]))
    }
    
    func sendChallengeResponse() {
        if (webSocket == nil) {
            return
        }
        
        // send challenge response
        sendMessage(messageWithType(MessageType.Challenge, data: ["data": "challenge"]))
    }
    
    func createNewPairingItemNamed(name: String) {
        // TODO:
    }
    
    func terminate() {
        if (webSocket == nil) {
            return
        }
        
        // destroy websocket
        cleanUp()
        delegate?.pairingProtocolManager(self, didTerminateWithOutcome: PairingOutcome.DeviceTerminated)
    }

    // MARK: Pairing protocol implementation
    
    private func handleChallengeMessage(message: Message) {
        if let dataString = message["data"] as? String {
            if let data = dataString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true) {
                delegate?.pairingProtocolManager(self, didReceiveChallenge: "1234")
            }
        }
    }
    
    private func handlePairingMessage(message: Message) {
        if let isSuccessful = message["is_successful"] as? Bool {
            cleanUp()
            delegate?.pairingProtocolManager(self, didTerminateWithOutcome: isSuccessful ? PairingOutcome.DongleSucceeded : PairingOutcome.DongleFailed)
        }
    }
    
    private func handleDisconnectMessage(message: Message) {
        cleanUp()
        delegate?.pairingProtocolManager(self, didTerminateWithOutcome: PairingOutcome.DongleTerminated)
    }
    
    private func receiveMessage(message: Message) {
        if let typeString = message["type"] as? String {
            if let messageType = MessageType(rawValue: typeString) {
                // lookup form message table
                if let handler = messagesHandlers[messageType] {
                    handler(self)(message)
                }
            }
        }
    }
    
    private func sendMessage(message: Message) {
        if let JSONData = NSJSONSerialization.dataWithJSONObject(message, options: NSJSONWritingOptions.allZeros, error: nil) {
            webSocket?.writeData(JSONData)
        }
    }
    
    private func messageWithType(type: MessageType, data: [String: AnyObject]? = nil) -> Message {
        var message: Message = ["type": type.rawValue]
        if let data = data {
            for (key, value) in data {
                message.updateValue(value, forKey: key)
            }
        }
        return message
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

extension PairingProtocolManager: JFRWebSocketDelegate {
    
    // MARK: WebSocket delegate
    
    func websocketDidDisconnect(socket: JFRWebSocket!, error: NSError!) {
        dispatch_async(dispatch_get_main_queue()) {
            self.cleanUp()
            self.delegate?.pairingProtocolManager(self, didTerminateWithOutcome: PairingOutcome.ServerDisconnected)
        }
    }
    
    func websocketDidWriteError(socket: JFRWebSocket!, error: NSError!) {
        dispatch_async(dispatch_get_main_queue()) {
            self.cleanUp()
            self.delegate?.pairingProtocolManager(self, didTerminateWithOutcome: PairingOutcome.ServerDisconnected)
        }
    }
    
    func websocket(socket: JFRWebSocket!, didReceiveMessage string: String!) {
        dispatch_async(dispatch_get_main_queue()) {
            // retreive data from string
            if let data = string.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true) {
                // create Message representation from data
                if let message = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.allZeros, error: nil) as? Message {
                    self.receiveMessage(message)
                }
            }
        }
    }
    
}