//
//  WalletLayoutAddressRequest.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 04/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

enum WalletLayoutAddressRequestError: ErrorType {

    case NoDelegateOrDataSource
    case MissingAddresses
    case MissingExtendedPublicKey(accountIndex: Int)
    case Internal
    
}

protocol WalletLayoutAddressRequestDelegate: class {

    func layoutAddressRequest(layoutAddressRequest: WalletLayoutAddressRequest, didFailWithError error: WalletLayoutAddressRequestError)
    func layoutAddressRequest(layoutAddressRequest: WalletLayoutAddressRequest, didSucceedWithAddresses addresses: [WalletAddressModel])
    func layoutAddressRequest(layoutAddressRequest: WalletLayoutAddressRequest, didGenerateAddresses addresses: [WalletAddressModel])
    
}

protocol WalletLayoutAddressRequestDataSource: class {
    
    func layoutAddressRequest(layoutAddressRequest: WalletLayoutAddressRequest, accountAtIndex index: Int, providerBlock: (WalletAccountModel?) -> Void)
    func layoutAddressRequest(layoutAddressRequest: WalletLayoutAddressRequest, addressesForPaths paths: [WalletAddressPath], providerBlock: ([WalletAddressModel]?) -> Void)
    
}

final class WalletLayoutAddressRequest {
    
    let fromPath: WalletAddressPath
    let toKeyIndex: Int
    weak var delegate: WalletLayoutAddressRequestDelegate?
    weak var dataSource: WalletLayoutAddressRequestDataSource?
    private let logger = Logger.sharedInstance(name: "WalletLayoutAddressRequest")
    
    // MARK: Discovery
    
    func resume() {
        guard delegate != nil && dataSource != nil else {
            delegate?.layoutAddressRequest(self, didFailWithError: .NoDelegateOrDataSource)
            return
        }
        fetchRequiredAddresses()
    }
    
    private func fetchRequiredAddresses() {
        // generate all paths
        var pathsToFetch: [WalletAddressPath] = []
        for i in fromPath.keyIndex...toKeyIndex {
            pathsToFetch.append(WalletAddressPath(accountIndex: fromPath.accountIndex, chainIndex: fromPath.chainIndex, keyIndex: i))
        }
        
        // get or create addresses from data source
        let currentPaths = fromPath.rangeStringToKeyIndex(toKeyIndex)
        dataSource?.layoutAddressRequest(self, addressesForPaths: pathsToFetch) { [weak self] addresses in
            guard let strongSelf = self else { return }
            
            guard let addresses = addresses else {
                strongSelf.logger.error("Data source failed to provide addresses in range \(currentPaths), aborting")
                strongSelf.delegate?.layoutAddressRequest(strongSelf, didFailWithError: .MissingAddresses)
                return
            }
            
            // if some addresses are unknown
            guard addresses.count == pathsToFetch.count else {
                strongSelf.logger.warn("Some addresses in range \(currentPaths) are unknown, generating missing ones")

                // cache for missing paths
                let fetchedPaths = addresses.map({ $0.addressPath })
                let missingPaths: [WalletAddressPath] = pathsToFetch.filter({ !fetchedPaths.contains($0) })
                
                // check that we computed missing paths
                guard missingPaths.count + addresses.count == pathsToFetch.count else {
                    strongSelf.logger.error("Unable to determine missing paths, aborting")
                    strongSelf.delegate?.layoutAddressRequest(strongSelf, didFailWithError: .Internal)
                    return
                }
                
                strongSelf.fetchExtendedPublicKeyForMissingPaths(missingPaths, existingAddresses: addresses)
                return
            }
            
            // all addresses are known
            strongSelf.logger.info("Addresses in range \(currentPaths) are known")
            strongSelf.delegate?.layoutAddressRequest(strongSelf, didSucceedWithAddresses: addresses)
        }
    }
    
    private func fetchExtendedPublicKeyForMissingPaths(paths: [WalletAddressPath], existingAddresses: [WalletAddressModel]) {
        // try to get extended public key
        dataSource?.layoutAddressRequest(self, accountAtIndex: fromPath.accountIndex) { [weak self] account in
            guard let strongSelf = self else { return }
            
            guard let account = account else {
                strongSelf.logger.warn("Data source failed to provide account at index \(strongSelf.fromPath.accountIndex), aborting")
                strongSelf.delegate?.layoutAddressRequest(strongSelf, didFailWithError: .MissingExtendedPublicKey(accountIndex: strongSelf.fromPath.accountIndex))
                return
            }
            
            // generate addresses
            strongSelf.cacheAddressesForMissingPaths(paths, extendedPublicKey: account.extendedPublicKey, existingAddresses: existingAddresses)
        }
    }
    
    private func cacheAddressesForMissingPaths(paths: [WalletAddressPath], extendedPublicKey: String, existingAddresses: [WalletAddressModel]) {
        // store missing paths
        let currentPaths = fromPath.rangeStringToKeyIndex(toKeyIndex)
        guard let generatedAddresses = generateAddressesAtPaths(paths, extendedPublicKey: extendedPublicKey) else {
            logger.error("Unable to derive missing addresses in range \(currentPaths), aborting")
            delegate?.layoutAddressRequest(self, didFailWithError: .Internal)
            return
        }
        
        // store generated addresses
        delegate?.layoutAddressRequest(self, didGenerateAddresses: generatedAddresses)
        
        // we now have all addresses known
        delegate?.layoutAddressRequest(self, didSucceedWithAddresses: existingAddresses + generatedAddresses)
    }
    
    private func generateAddressesAtPaths(paths: [WalletAddressPath], extendedPublicKey: String) -> [WalletAddressModel]? {
        guard paths.count > 0 else {
            return []
        }
        
        // create addresses from xpub
        guard let keychain = BTCKeychain(extendedKey: extendedPublicKey) else {
            return nil
        }
        
        var cacheAddresses: [WalletAddressModel] = []
        for path in paths {
            let address = keychain.keyWithPath(path.chainPath).address.string
            cacheAddresses.append(WalletAddressModel(addressPath: path, address: address))
        }
        return cacheAddresses
    }

    // MARK: Initialization

    init?(fromPath: WalletAddressPath, toKeyIndex: Int) {
        self.fromPath = fromPath
        self.toKeyIndex = toKeyIndex
        
        guard toKeyIndex > fromPath.keyIndex else {
            logger.error("Unable to fetch addresses to a key index \(toKeyIndex) lower that starting key \(fromPath.relativePath), aborting")
            return nil
        }
    }
    
}