//
//  EndianConvertible.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 11/02/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

protocol EndianConvertible: IntegerType {
    
    var bigEndian: Self { get }
    var littleEndian: Self { get }
    var byteSwapped: Self { get }
    
}

extension Int16: EndianConvertible {}
extension UInt16: EndianConvertible {}
extension Int32: EndianConvertible {}
extension UInt32: EndianConvertible {}
extension Int64: EndianConvertible {}
extension UInt64: EndianConvertible {}