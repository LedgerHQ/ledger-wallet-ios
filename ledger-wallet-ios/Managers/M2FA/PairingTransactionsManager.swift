//
//  IncomingTransactionsManager.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 02/02/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

protocol PairingTransactionsManagerDelegate: class {
    
    func pairingTransactionsManager(pairingTransactionsManager: PairingTransactionsManager, didReceiveNewTransactionInfo transactionInfo: PairingTransactionInfo)
    func pairingTransactionsManager(pairingTransactionsManager: PairingTransactionsManager, dongleDidCancelCurrentTransactionInfo transactionInfo: PairingTransactionInfo)
    
}

final class PairingTransactionsManager: BaseM2FAManager {
    
    weak var delegate: PairingTransactionsManagerDelegate? = nil
    private var webSocketsPairingKeychainItems: [WebSocket: PairingKeychainItem] = [:]
    private lazy var cryptor = PairingTransactionsCryptor()
    private var confirmingTransaction: Bool { return currentTransactionInfo != nil && currentTransactionWebSocket != nil && currentTransactionPairingKeychainItem != nil }
    private var currentTransactionInfo: PairingTransactionInfo? = nil
    private var currentTransactionWebSocket: WebSocket? = nil
    private var currentTransactionPairingKeychainItem: PairingKeychainItem? = nil
    
    // MARK: - Initialization
    
    deinit {
        stopListening()
    }
    
}

extension PairingTransactionsManager {
    
    // MARK: - Transactions management
    
    func tryListening() -> Bool {
        // create all webSockets
        initilizeWebSockets()
        logger.info("Listening \(webSocketsPairingKeychainItems.count) websockets")
        return webSocketsPairingKeychainItems.count > 0
    }
    
    func stopListening() {
        // destroy all webSockets
        logger.info("Stop listening all websockets")
        destroyWebSockets()
        destroyCurrentTransactionWebSocket()
    }
    
    func restartListening() {
        stopListening()
        tryListening()
    }
    
    func confirmTransaction(transactionInfo: PairingTransactionInfo) {
        handleTransaction(transactionInfo, confirm: true)
    }
    
    func rejectTransaction(transactionInfo: PairingTransactionInfo) {
        handleTransaction(transactionInfo, confirm: false)
    }
    
    private func handleTransaction(transactionInfo: PairingTransactionInfo, confirm: Bool) {
        guard confirmingTransaction && currentTransactionInfo != nil && transactionInfo == currentTransactionInfo! else {
            return
        }
        
        logger.info("\(confirm ? "Confirming" : "Rejecting") transaction \(transactionInfo)")
        
        // send response
        var data:[String: AnyObject] = ["is_accepted": confirm]
        if confirm {
            data["pin"] = currentTransactionInfo!.pinCode
        }
        sendMessage(messageWithType(MessageType.Response, data: data), webSocket: currentTransactionWebSocket!)
        
        // start listening
        logger.info("Listening all other websockets")
        initilizeWebSockets(excepted: [currentTransactionPairingKeychainItem!])
        
        // merge current transaction webSocket in newly listening webSockets
        webSocketsPairingKeychainItems[currentTransactionWebSocket!] = currentTransactionPairingKeychainItem
        
        // forget current transaction info
        currentTransactionInfo = nil
        currentTransactionWebSocket = nil
        currentTransactionPairingKeychainItem = nil
    }
    
    private func initilizeWebSockets(excepted exceptions: [PairingKeychainItem]? = nil) {
        // rebuild websockets
        let exemptedPairingItem = exceptions ?? []
        let pairingItems = PairingKeychainItem.fetchAll() as! [PairingKeychainItem]
        for pairingItem in pairingItems where !exemptedPairingItem.contains(pairingItem) {
            let webSocket = WebSocket(url: NSURL(string: LedgerWebSocketBaseURL)!.URLByAppendingPathComponent("/2fa/channels"))
            webSocket.delegate = self
            webSocket.connect()
            webSocketsPairingKeychainItems[webSocket] = pairingItem
        }
    }
    
    private func destroyWebSockets(excepted exceptions: [WebSocket]? = nil) {
        // destroy webSockets
        let exemptedWebSockets = exceptions ?? []
        for (webSocket, _) in webSocketsPairingKeychainItems where !exemptedWebSockets.contains(webSocket) {
            webSocket.delegate = nil
            if webSocket.isConnected {
                webSocket.disconnect()
            }
        }
        webSocketsPairingKeychainItems.removeAll()
    }
    
    private func destroyCurrentTransactionWebSocket() {
        currentTransactionWebSocket?.delegate = nil
        if currentTransactionWebSocket?.isConnected == true {
            currentTransactionWebSocket?.disconnect()
        }
        currentTransactionWebSocket = nil
        currentTransactionPairingKeychainItem = nil
        currentTransactionInfo = nil
    }
    
    private func acceptTransactionInfo(transactionInfo: PairingTransactionInfo, fromWebSocket webSocket: WebSocket) {
        // retain transaction info
        currentTransactionInfo = transactionInfo
        currentTransactionWebSocket = webSocket
        currentTransactionPairingKeychainItem = webSocketsPairingKeychainItems[webSocket]!
        
        // assign name to transaction info
        currentTransactionInfo?.dongleName = currentTransactionPairingKeychainItem?.dongleName ?? ""
        
        // destroy all webSockets excepted this one
        logger.info("Destroying all other websockets")
        destroyWebSockets(excepted: [webSocket])
        
        // send accept
        sendMessage(messageWithType(MessageType.Accept, data: nil), webSocket: webSocket)
        
        // notify delegate
        self.delegate?.pairingTransactionsManager(self, didReceiveNewTransactionInfo: currentTransactionInfo!)
    }
    
}

extension PairingTransactionsManager {
    
    // MARK: Messages management
    
    override func handleRequestMessage(message: Message, webSocket: WebSocket) {
        // make sure we're not already confirming a transaction
        guard !confirmingTransaction else {
            return
        }
        
        // get pairing key from websocket
        guard let pairingKey = webSocketsPairingKeychainItems[webSocket]?.pairingKey else {
            return
        }
        
        // get transaction info from data
        if let transactionInfo = cryptor.transactionInfoFromRequestMessage(message, pairingKey: pairingKey) {
            // accept transaction info
            logger.info("Accepting transaction \(transactionInfo)")
            acceptTransactionInfo(transactionInfo, fromWebSocket: webSocket)
        }
        else {
            logger.warn("Rejecting transaction")
        }
    }
    
    override func handleDisconnectMessage(message: Message, webSocket: WebSocket) {
        if confirmingTransaction {
            // notify delegate
            self.delegate?.pairingTransactionsManager(self, dongleDidCancelCurrentTransactionInfo: currentTransactionInfo!)
            
            // stop/start listening again
            logger.info("Received disconnect message, inside transaction, aborting")
            restartListening()
        }
        else {
            logger.info("Received disconnect message, outside transaction, ignoring")
        }
    }
    
}

extension PairingTransactionsManager {
    
    // MARK: - WebSocket events management
    
    override func handleWebSocketDidConnect(webSocket: WebSocket) {
        guard !confirmingTransaction else {
            return
        }
        
        // get pairing item
        if let pairingKeychainItem = webSocketsPairingKeychainItems[webSocket] {
            // join room
            logger.info("Websocket connected, joining room \(pairingKeychainItem.pairingId!)")
            sendMessage(messageWithType(MessageType.Join, data: ["room": pairingKeychainItem.pairingId!]), webSocket: webSocket)
            
            // send repeat message
            sendMessage(messageWithType(MessageType.Repeat, data: nil), webSocket: webSocket)
        }
    }

    override func handleWebSocket(webSocket: WebSocket, didDisconnectWithError error: NSError?) {
        if confirmingTransaction {
            // notify delegate
            self.delegate?.pairingTransactionsManager(self, dongleDidCancelCurrentTransactionInfo: currentTransactionInfo!)
            
            // stop/start listening again
            logger.warn("Websocket disconnected, inside transaction, aborting")
            restartListening()
        }
        else {
            // perform reconnect
            logger.warn("Websocket disconnected, outside transaction, reconnecting")
            dispatchOnMainQueueAfter(3.0) {
                webSocket.connect()
            }
        }
    }
    
}