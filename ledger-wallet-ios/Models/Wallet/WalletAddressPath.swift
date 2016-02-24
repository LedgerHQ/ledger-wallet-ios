//
//  WalletAddressPathe.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 16/02/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

struct WalletAddressPath {
    
    private(set) var indexes: [WalletAddressPathIndex]
    
    // MARK: Utils
    
    var derivationIndexes: [UInt32] {
        return indexes.map { $0.derivationIndex }
    }
    
    var depth: Int {
        return indexes.count
    }
    
    func indexAtDepth(depth: Int) -> WalletAddressPathIndex? {
        guard depth <= indexes.count - 1 else { return nil }
        
        return indexes[depth]
    }
    
    var parentPath: WalletAddressPath? {
        guard indexes.count > 0 else { return nil }
        
        return WalletAddressPath(indexes: Array(indexes.dropLast()))
    }
    
    func pathPrefixedWithPath(path: WalletAddressPath) -> WalletAddressPath {
        return WalletAddressPath(indexes: path.indexes + indexes)
    }
    
    func pathSuffixedWithPath(path: WalletAddressPath) -> WalletAddressPath {
        return WalletAddressPath(indexes: indexes + path.indexes)
    }
    
    func pathDroppingFirst(n: Int) -> WalletAddressPath? {
        guard indexes.count >= depth else { return nil }
        
        return WalletAddressPath(indexes: Array(indexes.dropFirst(n)))
    }
    
    func pathDroppingLast(n: Int) -> WalletAddressPath? {
        guard indexes.count >= depth else { return nil }

        return WalletAddressPath(indexes: Array(indexes.dropLast(n)))
    }
    
    func representativeString(includeMasterLevel includeMasterLevel: Bool = false) -> String {
        return indexes.reduce(includeMasterLevel ? "m" : "", combine: { return "\($0)/\($1.index)\($1.isHardened ? "'" : "")" })
    }
    
    func rangeStringToIndex(index: Int, includeMasterLevel: Bool = false) -> String {
        return representativeString(includeMasterLevel: includeMasterLevel) + "-\(index)"
    }
    
    // MARK: Initialization
    
    init() {
        self.init(indexes: [])
    }
    
    init(path: String) {
        var path = path.stringByTrimmingCharactersInSet(characterSet)
        let characterSet = NSCharacterSet.whitespaceAndNewlineCharacterSet()
        let levels = path.componentsSeparatedByString("/").map({ $0.stringByTrimmingCharactersInSet(characterSet) }).filter({ $0.characters.count > 0 && $0 != "m" })
        var foundIndexes: [WalletAddressPathIndex] = []
        
        levels.forEach { level in
            var level = level
            let hardened: Bool
            
            if level.characters.last == "'" {
                level = level.stringByReplacingOccurrencesOfString("'", withString: "")
                hardened = true
            }
            else {
                hardened = false
            }
            
            guard let index = Int(level) else { return }
            guard let newIndex = WalletAddressPathIndex(index: index, isHardened: hardened) else { return }
            foundIndexes.append(newIndex)
        }
        self.init(indexes: foundIndexes)
    }
    
    init(indexes: [WalletAddressPathIndex]) {
        self.indexes = indexes
    }
    
}

// MARK: - Equatable

extension WalletAddressPath: Equatable { }

func ==(lhs: WalletAddressPath, rhs: WalletAddressPath) -> Bool {
    return lhs.indexes == rhs.indexes
}

// MARK: - BIP32

extension WalletAddressPath {
    
    var conformsToBIP32: Bool {
        return indexes.count == 3 && indexes[0].isHardened &&
            !indexes[1].isHardened && !indexes[2].isHardened
    }
    
    var BIP32AccountIndex: Int? {
        return BIP32IndexAtDepth(0)
    }
    
    var BIP32ChainIndex: Int? {
        return BIP32IndexAtDepth(1)
    }
    
    var BIP32KeyIndex: Int? {
        return BIP32IndexAtDepth(2)
    }
    
    var isBIP32External: Bool {
        return BIP32ChainIndex == 0
    }
    
    var isBIP32Internal: Bool {
        return BIP32ChainIndex == 1
    }
    
    func pathWithBIP32AccountIndex(accountIndex: Int) -> WalletAddressPath? {
        guard let chainIndex = BIP32ChainIndex, keyIndex = BIP32KeyIndex else { return nil }
        
        return WalletAddressPath(BIP32AccountIndex: accountIndex, chainIndex: chainIndex, keyIndex: keyIndex)
    }
    
    func pathWithBIP32ChainIndex(chainIndex: Int) -> WalletAddressPath? {
        guard let accountIndex = BIP32AccountIndex, keyIndex = BIP32KeyIndex else { return nil }
        
        return WalletAddressPath(BIP32AccountIndex: accountIndex, chainIndex: chainIndex, keyIndex: keyIndex)
    }
    
    func pathWithBIP32KeyIndex(keyIndex: Int) -> WalletAddressPath? {
        guard let accountIndex = BIP32AccountIndex, chainIndex = BIP32ChainIndex else { return nil }
        
        return WalletAddressPath(BIP32AccountIndex: accountIndex, chainIndex: chainIndex, keyIndex: keyIndex)
    }
    
    func pathWithNewBIP32AccountIndex(accountIndex: Int) -> WalletAddressPath {
        return WalletAddressPath(BIP32AccountIndex: accountIndex, chainIndex: 0, keyIndex: 0)
    }
    
    func pathWithNewBIP32ChainIndex(chainIndex: Int) -> WalletAddressPath? {
        guard let accountIndex = BIP32AccountIndex else { return nil }

        return WalletAddressPath(BIP32AccountIndex: accountIndex, chainIndex: chainIndex, keyIndex: 0)
    }

    private func BIP32IndexAtDepth(depth: Int) -> Int? {
        guard conformsToBIP32 else { return nil }
        
        return indexes[depth].index
    }
    
    init(BIP32AccountIndex accountIndex: Int, chainIndex: Int, keyIndex: Int) {
        self.init(path: "/\(accountIndex)'/\(chainIndex)/\(keyIndex)")
    }
    
}

// MARK: - BIP44

extension WalletAddressPath {
    
    var conformsToBIP44: Bool {
        return indexes.count == 5 && indexes[0].index == 44 && indexes[0].isHardened &&
            indexes[1].isHardened && indexes[2].isHardened &&
            !indexes[3].isHardened && !indexes[4].isHardened
    }
    
    func BIP44PathWithCoinNetwork(coinNetwork: CoinNetworkType) -> WalletAddressPath? {
        if conformsToBIP44 {
            return self
        }
        else if conformsToBIP32 {
            return self.pathPrefixedWithPath(WalletAddressPath(path: "/44'/\(coinNetwork.BIP44Index)'"))
        }
        return nil
    }

    init(BIP44AccountIndex accountIndex: Int, chainIndex: Int, keyIndex: Int, coinNetwork: CoinNetworkType) {
        self.init(path: "/44'/\(coinNetwork.BIP44Index)'/\(accountIndex)'/\(chainIndex)/\(keyIndex)")
    }
    
    init(BIP44AccountIndex accountIndex: Int, coinNetwork: CoinNetworkType) {
        self.init(path: "/44'/\(coinNetwork.BIP44Index)'/\(accountIndex)'")
    }
    
}