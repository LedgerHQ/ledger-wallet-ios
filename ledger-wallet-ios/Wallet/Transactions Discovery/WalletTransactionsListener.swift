//
//  WalletTransactionsListener.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 25/11/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

protocol WalletTransactionsListenerDelegate: class {
    
    func transactionsListenerDidStart(transactionsListener: WalletTransactionsListener)
    func transactionsListenerDidStop(transactionsListener: WalletTransactionsListener)
    func transactionsListener(transactionsListener: WalletTransactionsListener, didReceiveTransaction transaction: WalletTransactionContainer)
    func transactionsListener(transactionsListener: WalletTransactionsListener, didReceiveBlock block: WalletBlockContainer)
    
}

final class WalletTransactionsListener {
    
    weak var delegate: WalletTransactionsListenerDelegate?
    private var websocket: WebSocket!
    private let servicesProvider: ServicesProviderType
    private var listening = false
    private let delegateQueue: NSOperationQueue
    private let workingQueue = dispatchSerialQueueWithName(dispatchQueueNameForIdentifier("WalletTransactionsListener"))
    private let logger = Logger.sharedInstance(name: "WalletTransactionsListener")
    
    var isListening: Bool {
        var value = false
        dispatchSyncOnQueue(workingQueue) { [weak self] in
            guard let strongSelf = self else { return }
            value = strongSelf.listening
        }
        return value
    }
    
    func startListening() {
        dispatchAsyncOnQueue(workingQueue) { [weak self] in
            guard let strongSelf = self where !strongSelf.listening else { return }
            
            strongSelf.logger.info("Start listening transactions")
            strongSelf.listening = true
            strongSelf.websocket = WebSocket(url: strongSelf.servicesProvider.walletEventsWebsocketURL)
            strongSelf.websocket.delegate = self
            strongSelf.websocket.queue = strongSelf.workingQueue
            strongSelf.websocket.connect()
            
            // notify delegate
            strongSelf.delegateQueue.addOperationWithBlock() { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.delegate?.transactionsListenerDidStart(strongSelf)
            }
        }
    }
    
    func stopListening() {
        dispatchAsyncOnQueue(workingQueue) { [weak self] in
            guard let strongSelf = self where strongSelf.listening else { return }

            strongSelf.logger.info("Stop listening transactions")
            strongSelf.listening = false
            strongSelf.websocket.disconnect()
            strongSelf.websocket = nil
            
            // notify delegate
            strongSelf.delegateQueue.addOperationWithBlock() { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.delegate?.transactionsListenerDidStop(strongSelf)
            }
        }
        dispatchSyncOnQueue(workingQueue, block: {})
    }
    
    // MARK: Initialization
    
    init(servicesProvider: ServicesProviderType, delegateQueue: NSOperationQueue) {
        self.delegateQueue = delegateQueue
        self.servicesProvider = servicesProvider
    }
    
    deinit {
        stopListening()
    }

}

// MARK: - WebSocketDelegate

extension WalletTransactionsListener: WebSocketDelegate {
    
    func websocketDidConnect(socket: WebSocket) {
        guard listening else { return }
    }
    
    func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        guard listening else { return }

        dispatchAfter(3, queue: workingQueue) { [weak self] in
            guard let strongSelf = self where strongSelf.listening else { return }

            strongSelf.logger.info("Lost connection, retrying in 3 seconds")
            strongSelf.stopListening()
            strongSelf.startListening()
        }
    }
    
    func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        guard listening else { return }

        guard let data = text.dataUsingEncoding(NSUTF8StringEncoding), JSON = JSON.JSONObjectFromData(data) as? [String: AnyObject] else {
            logger.error("Unable to get or parse JSON message from data")
            return
        }
        guard let payload = JSON["payload"] as? [String: AnyObject], type = payload["type"] as? String else {
            logger.error("Unable to get or parse message type from JSON")
            return
        }
        
        switch type {
        case "new-transaction": handleNewTransactionMessage(payload)
        case "new-block": handleNewBlockMessage(payload)
        default: return
        }
    }
    
    func websocketDidReceiveData(socket: WebSocket, data: NSData) {
        guard listening else { return }
    }
    
}

// MARK: - Messages management

private extension WalletTransactionsListener {
    
    private func handleNewTransactionMessage(payloadJSON: [String: AnyObject]) {
        guard let transactionJSON = payloadJSON["transaction"] as? [String: AnyObject] else {
            logger.error("Unable to get new transaction from payload")
            return
        }
        
        guard let transaction = WalletTransactionContainer(JSONObject: transactionJSON, parentObject: nil) else {
            logger.error("Unable to create transaction object from JSON")
            return
        }
        
        delegateQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.transactionsListener(strongSelf, didReceiveTransaction: transaction)
        }
    }
    
    private func handleNewBlockMessage(payloadJSON: [String: AnyObject]) {
        guard let blockJSON = payloadJSON["block"] as? [String: AnyObject] else {
            logger.error("Unable to get new block from payload")
            return
        }
        
        guard let block = WalletBlockContainer(JSONObject: blockJSON, parentObject: nil) else {
            logger.error("Unable to create block object from JSON")
            return
        }
        
        delegateQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.transactionsListener(strongSelf, didReceiveBlock: block)
        }

    }
    
}