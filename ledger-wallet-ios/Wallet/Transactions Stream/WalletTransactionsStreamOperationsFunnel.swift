//
//  WalletTransactionsStreamOperationsFunnel.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 17/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

final class WalletTransactionsStreamOperationsFunnel: WalletTransactionsStreamFunnelType {
    
    func process(context: WalletTransactionsStreamContext, workingQueue: NSOperationQueue, completion: (Bool) -> Void) {
        // flatten inputs and outputs into operations
        var sendOperations = flattenInputs(context)
        var receiveInternalOperations = flattenOutputs(context, external: false)
        var receiveExternalOperations = flattenOutputs(context, external: true)
        
        // normalize operations
        decreaseSendOperationAmounts(&sendOperations, internalOperations: receiveInternalOperations)
        checkForExternalSendToInternalAddresses(sendOperations, internalOperations: &receiveInternalOperations, externalOperations: &receiveExternalOperations)
        checkForInternalSendToInternalAddresses(context, sendOperations: sendOperations, internalOperations: &receiveInternalOperations, externalOperations: &receiveExternalOperations)
        
        // update context
        context.sendOperations.appendContentsOf(sendOperations.values)
        context.receiveOperations.appendContentsOf(receiveExternalOperations.values)
        completion(true)
    }
    
    // MARK: Inputs/ouputs management
    
    private func flattenInputs(context: WalletTransactionsStreamContext) -> [Int: WalletOperation] {
        var operations: [Int: WalletOperation] = [:]
        
        for (input, address) in context.mappedInputs {
            let operation = operations[address.path.accountIndex] ??
                WalletOperation(accountIndex: address.path.accountIndex, transactionHash: context.remoteTransaction.transaction.hash, kind: .Send, amount: 0)
            operations[address.path.accountIndex] = operation.increaseAmount(input.value)
        }
        return operations
    }
    
    private func flattenOutputs(context: WalletTransactionsStreamContext, external: Bool) -> [Int: WalletOperation] {
        var operations: [Int: WalletOperation] = [:]
        
        for (output, address) in context.mappedOutputs where address.path.isInternal == !external {
            let operation = operations[address.path.accountIndex] ??
                WalletOperation(accountIndex: address.path.accountIndex, transactionHash: context.remoteTransaction.transaction.hash, kind: .Receive, amount: 0)
            operations[address.path.accountIndex] = operation.increaseAmount(output.value)
        }
        return operations
    }
    
    private func decreaseSendOperationAmounts(inout sendOperations: [Int: WalletOperation], internalOperations: [Int: WalletOperation]) {
        for (accountIndex, operation) in sendOperations {
            if let internalOperation = internalOperations[accountIndex] {
                sendOperations[accountIndex] = operation.decreaseAmount(internalOperation.amount)
            }
        }
    }
    
    private func checkForExternalSendToInternalAddresses(sendOperations: [Int: WalletOperation],
        inout internalOperations: [Int: WalletOperation], inout externalOperations: [Int: WalletOperation]) {
        guard sendOperations.count == 0 && internalOperations.count > 0 && externalOperations.count == 0 else {
            return
        }
        
        externalOperations = internalOperations
        internalOperations.removeAll()
    }
    
    private func checkForInternalSendToInternalAddresses(context: WalletTransactionsStreamContext, sendOperations: [Int: WalletOperation],
        inout internalOperations: [Int: WalletOperation], inout externalOperations: [Int: WalletOperation]) {
        guard sendOperations.count > 0 && internalOperations.count == context.remoteTransaction.outputs.count && externalOperations.count == 0 else {
            return
        }

        guard let firstInputAccountIndex = sendOperations.first?.0 else {
            return
        }
        internalOperations.removeValueForKey(firstInputAccountIndex)
        externalOperations = internalOperations
        internalOperations.removeAll()
    }
    
}