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
    typealias MessageHandler = (Message, JFRWebSocket) -> Void
    
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

    dynamic func handleChallengeMessage(message: Message, webSocket: JFRWebSocket) {
        
    }
    
    dynamic func handlePairingMessage(message: Message, webSocket: JFRWebSocket) {
        
    }
    
    dynamic func handleDisconnectMessage(message: Message, webSocket: JFRWebSocket) {
        
    }
    
    dynamic func handleConnectMessage(message: Message, webSocket: JFRWebSocket) {
        
    }
    
    dynamic func handleRepeatMessage(message: Message, webSocket: JFRWebSocket) {

    }
    
    dynamic func handleRequestMessage(message: Message, webSocket: JFRWebSocket) {
        
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
    
    func receiveMessage(message: Message, webSocket: JFRWebSocket) {
        if let typeString = message["type"] as? String {
            if let messageType = MessageType(rawValue: typeString) {
                // lookup form message table
                if let handler = messagesHandlers[messageType] {
                    handler(message, webSocket)
                }
            }
        }
    }
    
    func sendMessage(message: Message, webSocket: JFRWebSocket) {
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

extension BasePairingManager: JFRWebSocketDelegate {

     // MARK: - WebSocket delegate

    func websocket(socket: JFRWebSocket!, didReceiveData data: NSData!) {
        dispatchAsyncOnMainQueue() {
            self.handleWebSocket(socket, didReceiveData: data)
        }
    }
    
    func websocket(socket: JFRWebSocket!, didReceiveMessage string: String!) {
        dispatchAsyncOnMainQueue() {
            self.handleWebSocket(socket, didReceiveMessage: string)
        }
    }
    
    func websocketDidConnect(socket: JFRWebSocket!) {
        dispatchAsyncOnMainQueue() {
            self.handleWebSocketDidConnect(socket)
        }
    }
    
    func websocketDidDisconnect(socket: JFRWebSocket!, error: NSError!) {
        dispatchAsyncOnMainQueue() {
            self.handleWebSocket(socket, didDisconnectWithError: error)
        }
    }
    
    func websocketDidWriteError(socket: JFRWebSocket!, error: NSError!) {
        dispatchAsyncOnMainQueue() {
            self.websocketDidWriteError(socket, error: error)
        }
    }
    
    func handleWebSocket(webSocket: JFRWebSocket, didReceiveData data: NSData) {
        
    }
    
    func handleWebSocket(webSocket: JFRWebSocket, didReceiveMessage message: String) {
        // retreive data from string
        if let data = message.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
            // create Message representation from data
            if let message = JSON.JSONObjectFromData(data) as? Message {
                self.receiveMessage(message, webSocket: webSocket)
            }
        }
    }
    
    func handleWebSocketDidConnect(webSocket: JFRWebSocket) {
        
    }
    
    func handleWebSocket(webSocket: JFRWebSocket, didDisconnectWithError error: NSError?) {
        
    }
    
    func handleWebsocket(webSocket: JFRWebSocket, didWriteError error: NSError?) {
        
    }

}