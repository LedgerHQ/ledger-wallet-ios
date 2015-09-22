//
//  BasePairingManager.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 02/02/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

class BasePairingManager: NSObject {
    
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
    
    var ignoresTimeout = true
    var ignoresWebSocketDelegate = false
    private var messagesHandlers: [MessageType: MessageHandler] = [:]
    private(set) var lastSentMessage: Message? = nil
    private var timeoutTimer: NSTimer? = nil
    
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
    
    override init() {
        super.init()
        
        unowned let me = self
        messagesHandlers.updateValue({ message, webSocket in me.handleChallengeMessage(message, webSocket: webSocket) }, forKey: MessageType.Challenge)
        messagesHandlers.updateValue({ message, webSocket in me.handleConnectMessage(message, webSocket: webSocket) }, forKey: MessageType.Connect)
        messagesHandlers.updateValue({ message, webSocket in me.handleDisconnectMessage(message, webSocket: webSocket) }, forKey: MessageType.Disconnect)
        messagesHandlers.updateValue({ message, webSocket in me.handlePairingMessage(message, webSocket: webSocket) }, forKey: MessageType.Pairing)
        messagesHandlers.updateValue({ message, webSocket in me.handleRepeatMessage(message, webSocket: webSocket) }, forKey: MessageType.Repeat)
        messagesHandlers.updateValue({ message, webSocket in me.handleRequestMessage(message, webSocket: webSocket) }, forKey: MessageType.Request)
    }
    
}

extension BasePairingManager {
    
    // MARK: - Timeout management
    
    func handleWebsocketTimeout() {
        
    }
    
    private dynamic func notifyTimeout() {
        handleWebsocketTimeout()
        stopTimeoutTimer()
    }
    
    private func startTimeoutTimer() {
        if ignoresTimeout || timeoutTimer != nil && timeoutTimer!.valid {
            return
        }
        timeoutTimer = NSTimer.scheduledTimerWithTimeInterval(30, target: self, selector: "notifyTimeout", userInfo: nil, repeats: false)
    }
    
    private func stopTimeoutTimer() {
        timeoutTimer?.invalidate()
        timeoutTimer = nil
    }
}

extension BasePairingManager {
    
    // MARK: - Messages management
    
    func sendMessage(message: Message, webSocket: WebSocket) {
        if let JSONData = JSON.dataFromJSONObject(message) {
            if let messageString = Crypto.Data.stringFromData(JSONData) {
                startTimeoutTimer()
                webSocket.writeString(messageString)
                lastSentMessage = message
            }
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
    
    private func receiveMessage(message: Message, webSocket: WebSocket) {
        if let typeString = message["type"] as? String {
            if let messageType = MessageType(rawValue: typeString) {
                // lookup form message table
                if let handler = messagesHandlers[messageType] {
                    stopTimeoutTimer()
                    handler(message, webSocket)
                }
            }
        }
    }
    
}

extension BasePairingManager {
    
    // MARK: - Websocket events management
    
    func handleWebSocket(webSocket: WebSocket, didReceiveMessage message: String) {
        if (ignoresWebSocketDelegate) {
            return
        }
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

extension BasePairingManager: WebSocketDelegate {

     // MARK: - WebSocket delegate

    func websocketDidConnect(socket: WebSocket) {
        if (ignoresWebSocketDelegate) {
            return
        }
        dispatchAsyncOnMainQueue() {
            self.handleWebSocketDidConnect(socket)
        }
    }
    
    func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        if (ignoresWebSocketDelegate) {
            return
        }
        dispatchAsyncOnMainQueue() {
            self.handleWebSocket(socket, didDisconnectWithError: error)
        }
    }
    
    func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        if (ignoresWebSocketDelegate) {
            return
        }
        dispatchAsyncOnMainQueue() {
            self.handleWebSocket(socket, didReceiveMessage: text)
        }
    }
    
    func websocketDidReceiveData(socket: WebSocket, data: NSData) {
        if (ignoresWebSocketDelegate) {
            return
        }
    }

}