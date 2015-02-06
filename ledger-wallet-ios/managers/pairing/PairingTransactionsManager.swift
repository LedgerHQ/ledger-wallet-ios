//
//  IncomingTransactionsManager.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 02/02/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

protocol PairingTransactionsManagerDelegate: class {
    
    
    
}

class PairingTransactionsManager: BasePairingManager {
    
    private(set) var listening: Bool = false
    weak var delegate: PairingTransactionsManagerDelegate? = nil
    private var webSockets: [JFRWebSocket: PairingKeychainItem] = [:]
    
    // MARK: -  Transactions management
    
    func startListening() {
        if (listening) {
            return
        }
        
        initilizeWebSockets()
        listening = true
    }
    
    func stopListening() {
        if (!listening) {
            return
        }
        
        destroyWebSockets()
        listening = false
    }

    private func initilizeWebSockets() {
        // rebuild websockets
        let pairingItems = PairingKeychainItem.fetchAll() as [PairingKeychainItem]
        for pairingItem in pairingItems {
            let websocket = JFRWebSocket(URL: NSURL(string: "ws://localhost:8080")!, protocols: nil)
            websocket.delegate = self
            websocket.connect()
            webSockets[websocket] = pairingItem
        }
    }
    
    private func destroyWebSockets() {
        for (websocket, pairingItem) in webSockets {
            websocket.delegate = nil
            websocket.disconnect()
        }
        webSockets.removeAll()
    }
    
    // MARK: -  Initialization
    
    deinit {
        destroyWebSockets()
    }
    
}

extension PairingTransactionsManager {
    
    // MARK: -  WebSocket delegate
    
    override func handleWebSocketDidConnect(webSocket: JFRWebSocket) {
        
    }
    
    override func handleWebSocket(webSocket: JFRWebSocket, didReceiveMessage message: String) {
        
    }
    
    override func handleWebSocket(webSocket: JFRWebSocket, didDisconnectWithError error: NSError?) {
        delayOnMainQueue(5.0) {
            println("CONNECt")
            webSocket.connect()
        }
    }
    
    override func handleWebsocket(webSocket: JFRWebSocket, didWriteError error: NSError?) {
        
    }
    
}