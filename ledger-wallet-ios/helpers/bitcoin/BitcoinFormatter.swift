//
//  BitcoinFormatter.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 11/02/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

extension Bitcoin {
    
    class Formatter {
        
        enum SymbolStyle {
            case None
            case Symbol
            case Unit
            case LowercaseUnit
        }
        
        enum Unit {
            case Bitcoin
            case MilliBitcoin
            case Bit
            case Satoshi
        }
    
        class func stringFromAmount(amount: Bitcoin.Amount, unit: Unit = .Bitcoin, symbolStyle: SymbolStyle = .Unit) -> String {
            let formatter = BTCNumberFormatter(bitcoinUnit: BTCNumberFormatterUnitFromUnit(unit), symbolStyle: BTCNumberFormatterSymbolStyleFromSymbolStyle(symbolStyle))
            formatter.minimumFractionDigits = 3
            formatter.decimalSeparator = "."
            return formatter.stringFromAmount(amount)
        }
        
        private class func BTCNumberFormatterUnitFromUnit(unit: Unit) -> BTCNumberFormatterUnit {
            if (unit == .Bitcoin) {
                return BTCNumberFormatterUnit.BTC
            }
            else if (unit == .MilliBitcoin) {
                return BTCNumberFormatterUnit.MilliBTC
            }
            else if (unit == .Bit) {
                return BTCNumberFormatterUnit.Bit
            }
            else {
                return BTCNumberFormatterUnit.Satoshi
            }
        }
        
        private class func BTCNumberFormatterSymbolStyleFromSymbolStyle(symbolStyle: SymbolStyle) -> BTCNumberFormatterSymbolStyle {
            if (symbolStyle == .None) {
                return BTCNumberFormatterSymbolStyle.None
            }
            else if (symbolStyle == .Symbol) {
                return BTCNumberFormatterSymbolStyle.Symbol
            }
            else if (symbolStyle == .Unit) {
                return BTCNumberFormatterSymbolStyle.Code
            }
            else {
                return BTCNumberFormatterSymbolStyle.Lowercase
            }
        }
        
    }

}