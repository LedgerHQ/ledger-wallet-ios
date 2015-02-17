//
//  BasePairingManager.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 02/02/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

class BasePairingManager: BaseManager {
    
    typealias Message = [String: AnyObject]
    typealias MessageHandler = (Message, WebSocket) -> Void
    
    enum MessageType: String {
        case Join = "join"
        case Identify = "identify"
        case Accept = "accept"
        case Repeat = "repeat"
        case Request = "request"
        case Response = "response"
        case Challenge = "challenge"
        case Pairing = "pairing"
        case Connect = "connect"
        case Disconnect = "disconnect"
    }
    private var messagesHandlers: [MessageType: MessageHandler] = [:]
    private(set) var lastSentMessage: Message? = nil
    
    // MARK: - Messages management

    dynamic func handleChallengeMessage(message: Message, webSocket: WebSocket) {
        
    }
    
    dynamic func handlePairingMessage(message: Message, webSocket: WebSocket) {
        
    }
    
    dynamic func handleDisconnectMessage(message: Message, webSocket: WebSocket) {
        
    }
    
    dynamic func handleConnectMessage(message: Message, webSocket: WebSocket) {
        
    }
    
    dynamic func handleRepeatMessage(message: Message, webSocket: WebSocket) {

    }
    
    dynamic func handleRequestMessage(message: Message, webSocket: WebSocket) {
        
    }
    
    // MARK: - Initialization
    
    required init() {
        super.init()
        
        unowned let me = self
        messagesHandlers.updateValue({ message, webSocket in me.handleChallengeMessage(message, webSocket: webSocket) }, forKey: MessageType.Challenge)
        messagesHandlers.updateValue({ message, webSocket in me.handleConnectMessage(message, webSocket: webSocket) }, forKey: MessageType.Connect)
        messagesHandlers.updateValue({ message, webSocket in me.handleDisconnectMessage(message, webSocket: webSocket) }, forKey: MessageType.Disconnect)
        messagesHandlers.updateValue({ message, webSocket in me.handlePairingMessage(message, webSocket: webSocket) }, forKey: MessageType.Pairing)
        messagesHandlers.updateValue({ message, webSocket in me.handleRepeatMessage(message, webSocket: webSocket) }, forKey: MessageType.Repeat)
    }
    
}

extension BasePairingManager {
    
    // MARK: - Messages management
    
    func receiveMessage(message: Message, webSocket: WebSocket) {
        if let typeString = message["type"] as? String {
            if let messageType = MessageType(rawValue: typeString) {
                // lookup form message table
                if let handler = messagesHandlers[messageType] {
                    handler(message, webSocket)
                }
            }
        }
    }
    
    func sendMessage(message: Message, webSocket: WebSocket) {
        if let JSONData = JSON.dataFromJSONObject(message) {
            webSocket.writeString(Crypto.Data.stringFromData(JSONData))
            lastSentMessage = message
        }
    }
    
    func messageWithType(type: MessageType, data: [String: AnyObject]? = nil) -> Message {
        var message: Message = ["type": type.rawValue]
        if let data = data {
            for (key, value) in data {
                message.updateValue(value, forKey: key)
            }
        }
        return message
    }
    
}

extension BasePairingManager: WebSocketDelegate {

     // MARK: - WebSocket delegate

    func websocketDidConnect(socket: WebSocket) {
        dispatchAsyncOnMainQueue() {
            self.handleWebSocketDidConnect(socket)
        }
    }
    
    func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        dispatchAsyncOnMainQueue() {
            self.handleWebSocket(socket, didDisconnectWithError: error)
        }
    }
    
    func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        dispatchAsyncOnMainQueue() {
            self.handleWebSocket(socket, didReceiveMessage: text)
        }
    }
    
    func websocketDidReceiveData(socket: WebSocket, data: NSData) {
        
    }
    
    func handleWebSocket(webSocket: WebSocket, didReceiveMessage message: String) {
        // retreive data from string
        if let data = message.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
            // create Message representation from data
            if let message = JSON.JSONObjectFromData(data) as? Message {
                self.receiveMessage(message, webSocket: webSocket)
            }
        }
    }
    
    func handleWebSocketDidConnect(webSocket: WebSocket) {
        
    }
    
    func handleWebSocket(webSocket: WebSocket, didDisconnectWithError error: NSError?) {
        
    }

}