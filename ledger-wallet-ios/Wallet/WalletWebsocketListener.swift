//
//  WalletWebsocketListener.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 25/11/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

protocol WalletWebsocketListenerDelegate: class {
    
    func websocketListener(websocketListener: WalletWebsocketListener, didReceiveTransaction transaction: WalletRemoteTransaction)
    
}

final class WalletWebsocketListener {
    
    weak var delegate: WalletWebsocketListenerDelegate?
    private var websocket: WebSocket!
    private var listening = false
    
    func startListening() {
        guard !listening else { return }
        listening = true
        websocket = WebSocket(url: NSURL(string: "wss://socket.blockcypher.com/v1/btc/main")!)
        websocket.delegate = self
        websocket.connect()
    }
    
    func stopListening() {
        guard listening else { return }
        listening = false
        websocket.disconnect()
        websocket = nil
    }
    
    // MARK: Initialization
    
    deinit {
        stopListening()
    }

}

extension WalletWebsocketListener: WebSocketDelegate {
    
    func websocketDidConnect(socket: WebSocket) {
        socket.writeString("{\"id\": \"\(NSUUID().UUIDString)\", \"event\": \"unconfirmed-tx\"}")
    }
    
    func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        dispatchAfterOnMainQueue(3.0) { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.stopListening()
            strongSelf.startListening()
        }
    }
    
    func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        dispatchAsyncOnGlobalQueueWithPriority(DISPATCH_QUEUE_PRIORITY_DEFAULT) {
            guard let data = text.dataUsingEncoding(NSUTF8StringEncoding) else { return }
            guard let JSON = JSON.JSONObjectFromData(data) as? WalletRemoteTransaction else { return }
            dispatchAsyncOnMainQueue() { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.delegate?.websocketListener(strongSelf, didReceiveTransaction: JSON)
            }
        }
    }
    
    func websocketDidReceiveData(socket: WebSocket, data: NSData) {
        
    }
    
}