//
//  BridgeTestHarness.swift
//  
//
//  Created by Shannon Young on 11/11/21.
//

import Foundation
@testable import BridgeApp
@testable import BridgeSDK
import BridgeSDKSwizzle

public let defaultMockParticipant = SBBStudyParticipant(dictionaryRepresentation: [
    "firstName" : "Fürst",
    "phoneVerified" : NSNumber(value: true),
    "phone": [
        "number": "206-555-1234"
    ],
    "email": "fake.address@fake.domain.tld",
    ])!

open class BridgeTestHarness {
    public let resourceBundle: Bundle
    let participantManager: MockSBBParticipantManager
    
    public init(_ resourceBundle: Bundle, mockParticipant: SBBStudyParticipant = defaultMockParticipant) {
        self.resourceBundle = resourceBundle
        
        let objectManager = SBBObjectManager()

        // Swizzle the app config
        if let url = resourceBundle.url(forResource: "AppConfig", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let json = try? JSONSerialization.jsonObject(with: data, options: []),
           let obj = objectManager.object(fromBridgeJSON: json),
           let appConfig = obj as? SBBAppConfig {
            BridgeSDK.setTestAppConfig(appConfig)
        }
        
        // Setup mock participant
        self.participantManager = MockSBBParticipantManager(participant: mockParticipant)
        BridgeSDK.setTestParticipantManager(self.participantManager)
    }
    
    var isSetup = false
    
    public func setupBridgeIfNeeded(with factory: SBAFactory = .init()) {
        guard !isSetup else { return }
        isSetup = true
        
        // Setup Bridge Configuration
        SBABridgeConfiguration.shared.setupBridge(with: factory) {
        }
        
        participantManager.setupParticipant()
    }
}

