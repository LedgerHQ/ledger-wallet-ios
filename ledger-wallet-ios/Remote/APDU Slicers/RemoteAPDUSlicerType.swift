//
//  RemoteAPDUSlicerType.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 04/02/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

protocol RemoteAPDUSlicerType {
    
    var transportType: RemoteTransportType { get }
    
    func sliceFromData(data: NSData) -> RemoteAPDUSlice?
    func sliceAPDU(APDU: RemoteAPDU, maxBytesLength: Int) -> [RemoteAPDUSlice]
    func joinSlices(slices: [RemoteAPDUSlice]) -> RemoteAPDU?
    
}