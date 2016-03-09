//
//  WalletTransactionsManager.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 25/11/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

final class WalletTransactionsManager: WalletTransactionsManagerType {
    
    let fetchRequestBuilder: WalletFetchRequestBuilder
    private var refreshing = false
    private var shouldUpdateStore = false
    private var pendingTasks: [WalletTaskType] = []
    
    var isRefreshing: Bool {
        var refreshing = false
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            refreshing = strongSelf.refreshing
        }
        workingQueue.waitUntilAllOperationsAreFinished()
        return refreshing
    }
    
    private let store: SQLiteStore
    private let storeProxy: WalletStoreProxy
    private let addressCache: WalletAddressCache
    private let layoutHolder: WalletLayoutHolder
    private let balanceUpdater: WalletBalanceUpdater
    private let transactionsConsumer: WalletTransactionsConsumer
    private let transactionsListener: WalletTransactionsListener
    private let transactionsStream: WalletTransactionsStream
    private let blocksStream: WalletBlocksStream
    private let unspentOutputsCollector: WalletUnspentOutputsCollector
    private let taskQueue: WalletTaskQueue
    private let logger = Logger.sharedInstance(name: "WalletTransactionsManager")
    private let delegateQueue = NSOperationQueue.mainQueue()
    private let workingQueue = NSOperationQueue(name: "WalletTransactionsManager", maxConcurrentOperationCount: 1)
    
    // MARK: Refresh management
    
    func refreshTransactions() {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            strongSelf.processStartRefreshingTransactions()
        }
    }
    
    private func processStartRefreshingTransactions() {
        guard !refreshing else { return }

        refreshing = true
        transactionsConsumer.startConsuming()
        ApplicationManager.sharedInstance.startNetworkActivity()
        notifyObservers(WalletTransactionsManagerDidStartRefreshingTransactionsNotification)
    }
    
    private func processDidStopRefreshingTransactions() {
        guard refreshing else { return }
        
        ApplicationManager.sharedInstance.stopNetworkActivity()
        enqueueUpdateStoreTasks()
        enqueueDidStopRefreshingTransactionsTask()
        enqueuePendingTasks()
    }
    
    // MARK: Extract data management
    
    func collectUnspentOutputs(accountIndex accountIndex: Int, amount: Int64, completionQueue: NSOperationQueue, completion: ([WalletUnspentTransactionOutput]?, WalletUnspentOutputsCollectorError?) -> Void) {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }

            let task = strongSelf.buildCollectUnspentOutputsTask(accountIndex: accountIndex, amount: amount, completionQueue: completionQueue, completion: completion)
            strongSelf.enqueueTaskAfterRefresh(task)
        }
    }
    
    func fetchCurrentAddress(accountIndex accountIndex: Int, external: Bool, completionQueue: NSOperationQueue, completion: (WalletAddress?) -> Void) {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            let task = strongSelf.buildFetchCurrentAddressTask(accountIndex: accountIndex, external: external, completionQueue: completionQueue, completion: completion)
            strongSelf.taskQueue.enqueueTask(task)
        }
    }
    
    func fetchExtendedPublicKey(accountIndex accountIndex: Int, completionQueue: NSOperationQueue, completion: (String?) -> Void) {
        workingQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            let task = strongSelf.buildFetchExtendedPublicKey(accountIndex: accountIndex, completionQueue: completionQueue, completion: completion)
            strongSelf.taskQueue.enqueueTask(task)
        }
    }
    
    // MARK: Initialization

    init?(identifier: String, servicesProvider: ServicesProviderType) {
        // log services provider and coin network
        logger.info("Using services provider \"\(servicesProvider.name)\" with coin network \"\(servicesProvider.coinNetwork.name)\"")

        // open store
        let storeURL = NSURL(fileURLWithPath: (ApplicationManager.sharedInstance.databasesDirectoryPath as NSString).stringByAppendingPathComponent(identifier + ".sqlite"))
        guard let store = WalletStoreManager.managedStoreAtURL(storeURL, identifier: identifier, coinNetwork: servicesProvider.coinNetwork) else {
            return nil
        }
        
        // create services
        self.store = store
        self.storeProxy = WalletStoreProxy(store: store)
        self.addressCache = WalletAddressCache(storeProxy: storeProxy)
        self.layoutHolder = WalletLayoutHolder(storeProxy: storeProxy)
        self.balanceUpdater = WalletBalanceUpdater(storeProxy: storeProxy)
        self.transactionsConsumer = WalletTransactionsConsumer(addressCache: addressCache, servicesProvider: servicesProvider, delegateQueue: workingQueue)
        self.transactionsListener = WalletTransactionsListener(servicesProvider: servicesProvider, delegateQueue: workingQueue)
        self.transactionsStream = WalletTransactionsStream(storeProxy: storeProxy, addressCache: addressCache, layoutHolder: layoutHolder, delegateQueue: workingQueue)
        self.blocksStream = WalletBlocksStream(storeProxy: storeProxy, delegateQueue: workingQueue)
        self.unspentOutputsCollector = WalletUnspentOutputsCollector(storeProxy: storeProxy)
        self.taskQueue = WalletTaskQueue(delegateQueue: workingQueue)
        self.fetchRequestBuilder = WalletFetchRequestBuilder(storeProxy: storeProxy, delegateQueue: delegateQueue)
        
        // plug delegates
        self.transactionsConsumer.delegate = self
        self.transactionsListener.delegate = self
        self.transactionsStream.delegate = self
        self.blocksStream.delegate = self
        self.taskQueue.delegate = self
        
        
        // start listening
        transactionsListener.startListening()
    }
    
    deinit {
        workingQueue.addOperationWithBlock() {
            if self.transactionsConsumer.isConsumimg {
                ApplicationManager.sharedInstance.stopNetworkActivity()
            }
            self.transactionsConsumer.stopConsuming()
            self.transactionsListener.stopListening()
            self.taskQueue.cancelAllTasks()
            self.store.close()
        }
        workingQueue.waitUntilAllOperationsAreFinished()
    }
    
}

// MARK: - Accounts management

private extension WalletTransactionsManager {
    
    private func registerAccount(account: WalletAccount) {
        // add account
        storeProxy.addAccount(account, completionQueue: workingQueue, completion: { _ in })
        
        // reload layout
        layoutHolder.reload()
        
        // cache 20 first internal + external addresses
        let internalPaths = (0..<WalletLayoutHolder.BIP44AddressesGap).map() { return WalletAddressPath(BIP32AccountIndex: account.index, chainIndex: 0, keyIndex: $0) }
        let externalPaths = (0..<WalletLayoutHolder.BIP44AddressesGap).map() { return WalletAddressPath(BIP32AccountIndex: account.index, chainIndex: 1, keyIndex: $0) }
        addressCache.fetchOrDeriveAddressesAtPaths(internalPaths + externalPaths, queue: workingQueue, completion: { _ in })
    }
    
    private func handleMissingAccountAtIndex(index: Int, continueBlock: (Bool) -> Void) {
        let request = WalletMissingAccountRequest(accountIndex: index) { [weak self] account in
            guard let strongSelf = self else { return }
            
            if let account = account {
                strongSelf.registerAccount(account)
                continueBlock(true)
                return
            }
            continueBlock(false)
        }
        let userInfo = [
            WalletTransactionsManagerMissingAccountRequestKey: request
        ]
        
        notifyObservers(WalletTransactionsManagerDidMissAccountNotification, userInfo: userInfo)
//                let accounts = [
//                    WalletAccount(index: 0, extendedPublicKey: "xpub67tVq9TLPPoaJgTkpz64N6YtB9pCorrwkLjqNgrnxWgGSVBkg2F7WhhRz5eBy7tEb2ZST4RUsC4iuMNGnWbQG69gPrTKmSKZMT3Xo7p9H4n", name: nil),
//                    WalletAccount(index: 1, extendedPublicKey: "xpub6D4waFVPfPCpUjYZexFNXjxusXSa5WrRj2iU8v5U6x2EvVuHaSKuo1zQEJA6Lt9dRcjgM1CSQmyq3tmSj5jCSup6WC24vRrHrBUyZkv5Jem", name: nil),
//                    WalletAccount(index: 2, extendedPublicKey: "xpub6D4waFVPfPCpX183njE1zjMayNCAnMHV4D989WsFd8ENDwfcdogPfRXSaA4opz3qoLoyCZCHZy9F7GQQnBxF4nNmZfXKKiokb2ABY8Bi8Jz", name: nil),
//                    WalletAccount(index: 3, extendedPublicKey: "xpub6D4waFVPfPCpZtpCLcfWBKLy2BqmWxDGuYVn4DmHyDSeVUDzjD5AsHy98SDmyXoiKmLWpsdfZszbcveZzFaEY6NhZSqw476xXu8LYBosvbG", name: nil),
//                ]
//        let accounts = [
//            WalletAccount(index: 0, extendedPublicKey: "xpub6Cec5KTvWeSNEw9bHe5v5sFPRwpM1x86Scuu7FuBpsQrhBg5GjhhBePAxpUQxmX8RNdAW2rfxZPQrrE5JAUqaa7MRfnXGKjQJB2awZ7Qgxy", name: nil),
//            WalletAccount(index: 1, extendedPublicKey: "xpub6Cec5KTvWeSNG1BsXpNab628WvCGZEECqiHPY7JcBWSQgKfQN5wK4hUr3e9PM464Q7u9owCNHKTRGNGMxYdfPgUFZ3hR3ko2ap7xqxHmCxk", name: nil),
//            WalletAccount(index: 2, extendedPublicKey: "xpub6Cec5KTvWeSNJtrFK6PqoCoP369xG8HYEDswqmTsQq63frkqF6dqYV56qRjJ7VQn1TEaejBPowG9vMGxVhsfRinhTgH5fTcAvMedABC8w6P", name: nil),
//            WalletAccount(index: 3, extendedPublicKey: "xpub6Cec5KTvWeSNLwb2fMVRYVJn4w49WebLyg7cJM2QsbQotPggFX49H8jKvieYCMHaGCsKrW9VVknSt7KRxRuacasuGyJm74hZ4JeNRdsRB6Y", name: nil),
//            WalletAccount(index: 4, extendedPublicKey: "xpub6Cec5KTvWeSNQLuVYmj4JZkX8q3VpSoQRd4BRkcPmhQvDaFi3yPobQXW795SLwN9zHXv9vYJyt4FrkWRBuJZMrg81qx7BDxNffPtJmFg2mb", name: nil)
//        ]
//                let accounts = [
//                    WalletAccount(index: 0, extendedPublicKey: "xpub6C47CZq7qLLXHgpoSdpBfjvxBz4YcnY4qXcgbbeeZGiSdyUDugFN3XMLavrUmdedGgaQaQRgVau69dUtoLQvgE1kSXHKWAQfiZHU7hGR2TX", name: nil)
//                ]
    }
    
}

// MARK: - Tasks management

extension WalletTransactionsManager {
    
    private func enqueueTaskAfterRefresh(task: WalletTaskType) {
        guard !refreshing else {
            pendingTasks.append(task)
            return
        }
        
        taskQueue.enqueueTask(task)
    }
    
    private func enqueuePendingTasks() {
        taskQueue.enqueueTasks(pendingTasks)
        pendingTasks.removeAll()
    }
    
    private func enqueueUpdateBalancesTask() {
        let task = WalletBlockTask(source: nil) { [weak self] taskCompletion in
            guard let strongSelf = self else { return }

            strongSelf.workingQueue.addOperationWithBlock() { [weak self] in
                guard let strongSelf = self else { return }

                strongSelf.balanceUpdater.updateAccountBalances(completionQueue: strongSelf.workingQueue) { _ in taskCompletion() }
            }
        }
        taskQueue.enqueueTask(task)
    }
    
    private func enqueueStoreTransactionTasks(transactions: [WalletTransactionContainer], source: WalletTaskSource) {
        let tasks: [WalletTaskType] = transactions.map({ transaction in
            return WalletBlockTask(source: source) { [weak self] taskCompletion in
                guard let strongSelf = self else { return }
            
                strongSelf.workingQueue.addOperationWithBlock() { [weak self] in
                    guard let strongSelf = self else { return }
                    
                    strongSelf.transactionsStream.processTransaction(transaction, completionQueue: strongSelf.workingQueue, completion: taskCompletion)
                }
            }
        })
        taskQueue.enqueueTasks(tasks)
    }
    
    private func enqueueStoreBlockTasks(blocks: [WalletBlockContainer], source: WalletTaskSource) {
        let tasks: [WalletTaskType] = blocks.map({ block in
            return WalletBlockTask(source: source) { [weak self] taskCompletion in
                guard let strongSelf = self else { return }
                
                strongSelf.workingQueue.addOperationWithBlock() { [weak self] in
                    guard let strongSelf = self else { return }

                    strongSelf.blocksStream.processBlock(block, completionQueue: strongSelf.workingQueue, completion: taskCompletion)
                }
            }
        })
        taskQueue.enqueueTasks(tasks)
    }
    
    private func enqueueNotifyObserversTask(notification: String, userInfo: [String: AnyObject]? = nil) {
        let task = WalletBlockTask(source: nil) { [weak self] taskCompletion in
            guard let strongSelf = self else { return }
            
            strongSelf.workingQueue.addOperationWithBlock() { [weak self] in
                guard let strongSelf = self else { return }
                
                strongSelf.notifyObservers(notification, userInfo: userInfo)
            }
            taskCompletion()
        }
        taskQueue.enqueueTask(task)
    }
    
    private func enqueueDidStopRefreshingTransactionsTask() {
        let task = WalletBlockTask(source: nil) { [weak self] taskCompletion in
            guard let strongSelf = self else { return }
            
            strongSelf.workingQueue.addOperationWithBlock() { [weak self] in
                guard let strongSelf = self else { return }
                
                strongSelf.refreshing = false
                strongSelf.notifyObservers(WalletTransactionsManagerDidStopRefreshingTransactionsNotification)
                taskCompletion()
            }
        }
        taskQueue.enqueueTask(task)
    }
    
    private func enqueueUpdateStoreTasks() {
        enqueueUpdateBalancesTask()
        enqueueNotifyObserversTask(WalletTransactionsManagerDidUpdateOperationsNotification)
        enqueueNotifyObserversTask(WalletTransactionsManagerDidUpdateAccountsNotification)
    }
    
    private func buildCollectUnspentOutputsTask(accountIndex accountIndex: Int, amount: Int64, completionQueue: NSOperationQueue, completion: ([WalletUnspentTransactionOutput]?, WalletUnspentOutputsCollectorError?) -> Void) -> WalletTaskType {
        let task = WalletBlockTask(source: nil) { [weak self] taskCompletion in
            guard let strongSelf = self else { return }
            
            strongSelf.workingQueue.addOperationWithBlock() { [weak self] in
                guard let strongSelf = self else { return }
                
                strongSelf.unspentOutputsCollector.collectUnspentOutputs(accountIndex: accountIndex, amount: amount, completionQueue: strongSelf.workingQueue) { outputs, error in
                    completionQueue.addOperationWithBlock() { completion(outputs, error) }
                    taskCompletion()
                }
            }
        }
        return task
    }
    
    private func buildFetchCurrentAddressTask(accountIndex accountIndex: Int, external: Bool, completionQueue: NSOperationQueue, completion: (WalletAddress?) -> Void) -> WalletTaskType {
        let task = WalletBlockTask(source: nil) { [weak self] taskCompletion in
            guard let strongSelf = self else { return }

            strongSelf.workingQueue.addOperationWithBlock() {
                guard let strongSelf = self else { return }
                
                strongSelf.storeProxy.fetchCurrentAddressForAccountAtIndex(accountIndex, external: external, completionQueue: strongSelf.workingQueue) { address in
                    completionQueue.addOperationWithBlock() { completion(address) }
                    taskCompletion()
                }
            }
        }
        return task
    }
    
    private func buildFetchExtendedPublicKey(accountIndex accountIndex: Int, completionQueue: NSOperationQueue, completion: (String?) -> Void) -> WalletTaskType {
        let task = WalletBlockTask(source: nil) { [weak self] taskCompletion in
            guard let strongSelf = self else { return }
            
            strongSelf.workingQueue.addOperationWithBlock() {
                guard let strongSelf = self else { return }
                
                strongSelf.storeProxy.fetchExtendedPublicKeyForAccountAtIndex(accountIndex, completionQueue: strongSelf.workingQueue) { extendedPublicKey in
                    completionQueue.addOperationWithBlock() { completion(extendedPublicKey) }
                    taskCompletion()
                }
            }
        }
        return task
    }
    
}

// MARK: - Notifications management

extension WalletTransactionsManager {
    
    private func notifyObservers(notification: String, userInfo: [String: AnyObject]? = nil) {
        delegateQueue.addOperationWithBlock() { [weak self] in
            guard let strongSelf = self else { return }
            
            strongSelf.logger.info("Notifying \(notification)")
            NSNotificationCenter.defaultCenter().postNotificationName(notification, object: strongSelf, userInfo: userInfo)
        }
    }
    
}

// MARK: - WalletTaskQueueDelegate

extension WalletTransactionsManager: WalletTaskQueueDelegate {
    
    func taskQueueDidStartDequeingTasks(taskQueue: WalletTaskQueue) {
        
    }
    
    func taskQueueDidStopDequeingTasks(taskQueue: WalletTaskQueue) {
        
    }
    
    func taskQueue(taskQueue: WalletTaskQueue, willProcessTask task: WalletTaskType) {
        guard let source = task.source where !refreshing && source == .TransactionsListener else { return }
        
        shouldUpdateStore = false
    }
    
    func taskQueue(taskQueue: WalletTaskQueue, didProcessTask task: WalletTaskType) {
        guard let source = task.source where !refreshing && source == .TransactionsListener else { return }
        
        if shouldUpdateStore {
            enqueueUpdateStoreTasks()
            shouldUpdateStore = false
        }
    }
    
}

// MARK: - WalletTransactionsConsumerDelegate

extension WalletTransactionsManager: WalletTransactionsConsumerDelegate {
    
    func transactionsConsumer(transactionsConsumer: WalletTransactionsConsumer, didMissAccountAtIndex index: Int, continueBlock: (Bool) -> Void) {
        handleMissingAccountAtIndex(index, continueBlock: continueBlock)
    }
    
    func transactionsConsumerDidStart(transactionsConsumer: WalletTransactionsConsumer) {
        
    }
    
    func transactionsConsumer(transactionsConsumer: WalletTransactionsConsumer, didStopWithError error: WalletTransactionsConsumerError?) {
        processDidStopRefreshingTransactions()
    }
    
    func transactionsConsumer(transactionsConsumer: WalletTransactionsConsumer, didDiscoverTransactions transactions: [WalletTransactionContainer]) {
        enqueueStoreTransactionTasks(transactions, source: .TransactionsConsumer)
    }
    
}

// MARK: - WalletTransactionsListenerDelegate

extension WalletTransactionsManager: WalletTransactionsListenerDelegate {
    
    func transactionsListenerDidStart(transactionsListener: WalletTransactionsListener) {
   
    }
    
    func transactionsListenerDidStop(transactionsListener: WalletTransactionsListener) {

    }
    
    func transactionsListener(transactionsListener: WalletTransactionsListener, didReceiveTransaction transaction: WalletTransactionContainer) {
        enqueueStoreTransactionTasks([transaction], source: .TransactionsListener)
    }
    
    func transactionsListener(transactionsListener: WalletTransactionsListener, didReceiveBlock block: WalletBlockContainer) {
        enqueueStoreBlockTasks([block], source: .TransactionsListener)
    }
    
}

// MARK: - WalletTransactionsStreamDelegate

extension WalletTransactionsManager: WalletTransactionsStreamDelegate {
    
    func transactionsStream(transactionsStream: WalletTransactionsStream, didMissAccountAtIndex index: Int, continueBlock: (Bool) -> Void) {
        handleMissingAccountAtIndex(index, continueBlock: continueBlock)
    }
    
    func transactionsStreamDidUpdateTransactions(transactionsStream: WalletTransactionsStream) {
        shouldUpdateStore = true
    }
    
    func transactionsStreamDidUpdateAccountLayouts(transactionsStream: WalletTransactionsStream) {
        shouldUpdateStore = true
    }
    
    func transactionsStreamDidUpdateOperations(transactionsStream: WalletTransactionsStream) {
        shouldUpdateStore = true
    }
    
    func transactionsStreamDidUpdateDoubleSpendConflicts(transactionsStream: WalletTransactionsStream) {
        shouldUpdateStore = true
    }
    
}

// MARK: - WalletBlocksStreamDelegate

extension WalletTransactionsManager: WalletBlocksStreamDelegate {
    
    func blocksStreamDidUpdateTransactions(blocksStream: WalletBlocksStream) {
        shouldUpdateStore = true
    }
    
}
