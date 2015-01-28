//
//  PairingAddManager.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 27/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

@objc protocol PairingAddManagerDelegate: class {
    
    func pairingAddManagerDidJoinRoom(pairingAddManager: PairingAddManager)
    func pairingAddManagerDidReceiveChallenge(pairingAddManager: PairingAddManager, challenge: String)
    func pairingAddManager(pairingAddManager: PairingAddManager, didTerminateWithError hasError: Bool)
    func pairingAddManager(pairingAddManager: PairingAddManager, didPairWithKey key: String?)
    
}

class PairingAddManager: BaseManager {
    
    typealias Message = [String: AnyObject]
    private enum MessageType: String {
        case Join = "join"
        case Identity = "identity"
        case Challenge = "challenge"
        case Pairing = "pairing"
    }
    
    weak var delegate: PairingAddManagerDelegate? = nil
    private var webSocket: JFRWebSocket? = nil
    
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
        delegate?.pairingAddManagerDidJoinRoom(self)
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
    
    func terminate() {
        if (webSocket == nil) {
            return
        }
        
        // destroy websocket
        cleanUp()
        delegate?.pairingAddManager(self, didTerminateWithError: false)
    }

    // MARK: Pairing protocol implementation
    
    private func handleChallengeMessage(message: Message) {
        if let dataString = message["data"] as? String {
            if let data = dataString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true) {
                delegate?.pairingAddManagerDidReceiveChallenge(self, challenge: "1234")
            }
        }
    }
    
    private func handlePairingMessage(message: Message) {
        if let isSuccessful = message["is_successful"] as? Bool {
            delegate?.pairingAddManager(self, didPairWithKey: isSuccessful ? "pairingkey" : nil)
        }
    }
    
    private func receiveMessage(message: Message) {
        if let typeString = message["type"] as? String {
            if let messageType = MessageType(rawValue: typeString) {
                // lookup for message type
                if messageType == MessageType.Challenge {
                    handleChallengeMessage(message)
                }
                else if messageType == MessageType.Pairing {
                    handlePairingMessage(message)
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
        delegate?.pairingAddManager(self, didTerminateWithError: false)
    }
    
}

extension PairingAddManager: JFRWebSocketDelegate {
    
    // MARK: WebSocket delegate
    
    func websocketDidDisconnect(socket: JFRWebSocket!, error: NSError!) {
        dispatch_async(dispatch_get_main_queue()) {
            self.cleanUp()
            self.delegate?.pairingAddManager(self, didTerminateWithError: error != nil)
        }
    }
    
    func websocketDidWriteError(socket: JFRWebSocket!, error: NSError!) {
        dispatch_async(dispatch_get_main_queue()) {
            self.cleanUp()
            self.delegate?.pairingAddManager(self, didTerminateWithError: true)
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