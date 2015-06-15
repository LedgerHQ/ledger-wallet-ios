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

class PairingTransactionsManager: BasePairingManager {
    
    weak var delegate: PairingTransactionsManagerDelegate? = nil
    private var webSockets: [WebSocket: PairingKeychainItem] = [:]
    private var webSocketsBaseURL: String! = nil
    private var cryptor: PairingTransactionsCryptor! = nil
    private var isConfirmingTransaction: Bool { return currentTransactionInfo != nil && currentTransactionWebSocket != nil && currentTransactionPairingKeychainItem != nil }
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
    
    func startListening() -> Bool {
        // create all webSockets
        initilizeWebSockets()
        return webSockets.count > 0
    }
    
    func stopListening() {
        // destroy all webSockets
        destroyWebSockets()
        destroyCurrentTransactionWebSocket()
    }
    
    func restartListening() {
        stopListening()
        startListening()
    }
    
    func confirmTransaction(transactionInfo: PairingTransactionInfo) {
        handleTransaction(transactionInfo, confirm: true)
    }
    
    func rejectTransaction(transactionInfo: PairingTransactionInfo) {
        handleTransaction(transactionInfo, confirm: false)
    }
    
    private func handleTransaction(transactionInfo: PairingTransactionInfo, confirm: Bool) {
        if (!isConfirmingTransaction || transactionInfo !== currentTransactionInfo) {
            return
        }
        
        // send response
        var data:[String: AnyObject] = ["is_accepted": confirm]
        if confirm {
            data["pin"] = currentTransactionInfo!.pinCode
        }
        sendMessage(messageWithType(MessageType.Response, data: data), webSocket: currentTransactionWebSocket!)
        
        // start listening
        initilizeWebSockets(excepted: [currentTransactionPairingKeychainItem!])
        
        // merge current transaction webSocket in newly listening webSockets
        webSockets[currentTransactionWebSocket!] = currentTransactionPairingKeychainItem
        
        // forget current transaction info
        currentTransactionInfo = nil
        currentTransactionWebSocket = nil
        currentTransactionPairingKeychainItem = nil
    }
    
    private func initilizeWebSockets(excepted exceptions: [PairingKeychainItem]? = nil) {
        // initialize websocket URL
        if (webSocketsBaseURL == nil) { webSocketsBaseURL = LedgerWebSocketBaseURL }
        
        // create cryptor
        if (cryptor == nil) { cryptor = PairingTransactionsCryptor() }
        
        // rebuild websockets
        let exemptedPairingItem = exceptions ?? []
        let pairingItems = PairingKeychainItem.fetchAll() as! [PairingKeychainItem]
        for pairingItem in pairingItems {
            if (contains(exemptedPairingItem, pairingItem)) {
                continue
            }
            let webSocket = WebSocket(url: NSURL(string: webSocketsBaseURL)!.URLByAppendingPathComponent("/2fa/channels"))
            webSocket.delegate = self
            webSocket.connect()
            webSockets[webSocket] = pairingItem
        }
    }
    
    private func destroyWebSockets(excepted exceptions: [WebSocket]? = nil) {
        // destroy webSockets
        let exemptedWebSockets = exceptions ?? []
        for (webSocket, pairingItem) in webSockets {
            if (contains(exemptedWebSockets, webSocket)) {
                continue
            }
            webSocket.delegate = nil
            if webSocket.isConnected {
                webSocket.disconnect()
            }
        }
        webSockets.removeAll()
    }
    
    private func destroyCurrentTransactionWebSocket() {
        currentTransactionWebSocket?.delegate = nil
        if let isConnected = currentTransactionWebSocket?.isConnected {
            if isConnected == true {
                currentTransactionWebSocket?.disconnect()
            }
        }
        currentTransactionWebSocket = nil
        currentTransactionPairingKeychainItem = nil
        currentTransactionInfo = nil
    }
    
    private func acceptTransactionInfo(transactionInfo: PairingTransactionInfo, fromWebSocket webSocket: WebSocket) {
        // retain transaction info
        currentTransactionInfo = transactionInfo
        currentTransactionWebSocket = webSocket
        currentTransactionPairingKeychainItem = webSockets[webSocket]!
        
        // assign transaction info
        transactionInfo.dongleName = currentTransactionPairingKeychainItem!.dongleName!
        
        // destroy all webSockets excepted this one
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
        if (isConfirmingTransaction) {
            return
        }
        
        // get base 16 string
        if let dataString = message["second_factor_data"] as? String {
            // get encrypted blob
            if let blob = Crypto.Encode.dataFromBase16String(dataString) {
                // get pairing item
                if let pairingKeychainItem = webSockets[webSocket] {
                    // get transaction info from blob
                    if let transactionInfo = cryptor.transactionInfoFromEncryptedBlob(blob, pairingKey: pairingKeychainItem.pairingKey!) {
                        // accept transaction info
                        acceptTransactionInfo(transactionInfo, fromWebSocket: webSocket)
                    }
                }
            }
        }
    }
    
    override func handleDisconnectMessage(message: Message, webSocket: WebSocket) {
        if (isConfirmingTransaction) {
            // notify delegate
            self.delegate?.pairingTransactionsManager(self, dongleDidCancelCurrentTransactionInfo: currentTransactionInfo!)
            
            // stop/start listening again
            restartListening()
        }
    }
    
}

extension PairingTransactionsManager {
    
    // MARK: - WebSocket delegate
    
    override func handleWebSocketDidConnect(webSocket: WebSocket) {
        if (!isConfirmingTransaction) {
            // get pairing item
            if let pairingKeychainItem = webSockets[webSocket] {
                // join room
                sendMessage(messageWithType(MessageType.Join, data: ["room": pairingKeychainItem.pairingId!]), webSocket: webSocket)
                
                // send repeat message
                sendMessage(messageWithType(MessageType.Repeat, data: nil), webSocket: webSocket)
            }
        }
    }
    
    override func handleWebSocket(webSocket: WebSocket, didDisconnectWithError error: NSError?) {
        if (isConfirmingTransaction) {
            // notify delegate
            self.delegate?.pairingTransactionsManager(self, dongleDidCancelCurrentTransactionInfo: currentTransactionInfo!)
            
            // stop/start listening again
            restartListening()
        }
        else {
            // perform reconnect
            delayOnMainQueue(3.0) {
                webSocket.connect()
            }
        }
    }
    
}