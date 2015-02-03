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
    typealias MessageHandler = (Message) -> Void
    typealias CurriedMessageHandler = (BasePairingManager) -> (MessageHandler)
    
    enum MessageType: String {
        case Join = "join"
        case Identity = "identity"
        case Accept = "accept"
        case Repeat = "repeat"
        case Challenge = "challenge"
        case Pairing = "pairing"
        case Connect = "connect"
        case Disconnect = "disconnect"
    }
    private var messagesHandlers: [MessageType: CurriedMessageHandler] = [
        MessageType.Challenge: handleChallengeMessage,
        MessageType.Pairing: handlePairingMessage,
        MessageType.Disconnect: handleDisconnectMessage,
        MessageType.Connect: handleConnectMessage
    ]
    
    // MARK: Messages management
    
    func handleChallengeMessage(message: Message) {
        
    }
    
    func handlePairingMessage(message: Message) {
        
    }
    
    func handleDisconnectMessage(message: Message) {
        
    }
    
    func handleConnectMessage(message: Message) {
        
    }
    
}

extension BasePairingManager {
    
    // MARK: Messages management
    
    func receiveMessage(message: Message) {
        if let typeString = message["type"] as? String {
            if let messageType = MessageType(rawValue: typeString) {
                // lookup form message table
                if let handler = messagesHandlers[messageType] {
                    handler(self)(message)
                }
            }
        }
    }
    
    func sendMessage(message: Message, webSocket: JFRWebSocket) {
        if let JSONData = NSJSONSerialization.dataWithJSONObject(message, options: NSJSONWritingOptions.allZeros, error: nil) {
            webSocket.writeData(JSONData)
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

     // MARK: WebSocket delegate

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
        
    }
    
    func handleWebSocketDidConnect(webSocket: JFRWebSocket) {
        
    }
    
    func handleWebSocket(webSocket: JFRWebSocket, didDisconnectWithError error: NSError?) {
        
    }
    
    func handleWebsocket(webSocket: JFRWebSocket, didWriteError error: NSError?) {
        
    }

}