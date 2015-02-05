//
//  PairingProtocolManagerTests.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 04/02/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation
import XCTest

class PairingProtocolManagerTests: XCTestCase, PairingProtocolManagerDelegate {
    
    let publicKey = Crypto.Encode.dataFromBase16String("04ae218d8080c7b9cd141b06f6b9f63ef3adf7aecdf49bb3916ac7f5d887fc4027bea6fd187b9fa810b6d251e1430f6555edd2d5b19828d51908917c03e3f7c436")
    let privateKey = Crypto.Encode.dataFromBase16String("b208b83b23edfff327bb6e0098eeaa0a5c87a599d5d8b24ff2734d2aac8bbdde")
    let webSocketURL = "ws://192.168.2.107:8080"
    let roomName = "holymacaroni"
    let challengeResponse = "abcd"
    let dongleName = "My new Pairing"
    
    var pairingProtocolManager: PairingProtocolManager! = nil
    var waitChallengeExpectation: XCTestExpectation? = nil
    var waitPairingExpectation: XCTestExpectation? = nil
    var stop = false
    
    override func setUp() {
        super.setUp()
        
        pairingProtocolManager = PairingProtocolManager()
        pairingProtocolManager.delegate = self
        pairingProtocolManager.setTestKey(Crypto.Key(privateKey: privateKey))
        pairingProtocolManager.setTestWebSocketURL(webSocketURL)
        pairingProtocolManager.setEnvironementIsTest(true)
    }
    
    func testPairingFlow() {
        // join
        pairingProtocolManager.joinRoom(roomName)
        pairingProtocolManager.sendPublicKey()
        
        // wait challenge
        waitChallengeExpectation = expectationWithDescription("wait challenge")
        waitForExpectationsWithTimeout(30) { error in
            if (error != nil) { self.stop = true }
        }
        
        if (stop == true) { return }
        
        // send challenge response
        pairingProtocolManager.sendChallengeResponse(challengeResponse)
        
        // wait pairing
        waitPairingExpectation = expectationWithDescription("wait pairing")
        waitForExpectationsWithTimeout(30) { error in
            if (error != nil) { self.stop = true }
        }
        
        if (stop == true) { return }

        // create pairing keychain item
        if (pairingProtocolManager.canCreatePairingItemNamed(dongleName) == false) {
            XCTFail("already existing pairing keychain item named \(dongleName)")
            return
        }
        if (pairingProtocolManager.createNewPairingItemNamed(dongleName) == false) {
            XCTFail("unable to create pairing keychain item named \(dongleName)")
            return
        }
    }

    override func tearDown() {
        super.tearDown()
        
        pairingProtocolManager.delegate = nil
        pairingProtocolManager.terminate()
        pairingProtocolManager = nil
    }
    
}

extension PairingProtocolManagerTests: PairingProtocolManagerDelegate {
    
    // PairingProtocolManager delegate

    func pairingProtocolManager(pairingProtocolManager: PairingProtocolManager, didReceiveChallenge challenge: String) {
        waitChallengeExpectation?.fulfill(); waitChallengeExpectation = nil
    }
    
    func pairingProtocolManager(pairingProtocolManager: PairingProtocolManager, didTerminateWithOutcome outcome: PairingProtocolManager.PairingOutcome) {
        if (outcome != PairingProtocolManager.PairingOutcome.DongleSucceeded) {
            XCTFail("outcome is not .DongleSucceeded, got \(outcome)")
            stop = true
        }
        waitChallengeExpectation?.fulfill(); waitChallengeExpectation = nil
        waitPairingExpectation?.fulfill(); waitPairingExpectation = nil
    }
    
}