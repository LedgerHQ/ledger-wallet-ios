//
//  RemoteDeviceType.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 22/01/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

protocol RemoteDeviceType {

    var name: String? { get }
    var transportType: RemoteTransportType { get }

}