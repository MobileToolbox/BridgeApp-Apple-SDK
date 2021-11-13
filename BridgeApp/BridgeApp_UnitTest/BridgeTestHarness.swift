//
//  BridgeTestHarness.swift
//  
//
//  Copyright © 2021 Sage Bionetworks. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// 1.  Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// 2.  Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation and/or
// other materials provided with the distribution.
//
// 3.  Neither the name of the copyright holder(s) nor the names of any contributors
// may be used to endorse or promote products derived from this software without
// specific prior written permission. No license is granted to the trademarks of
// the copyright holders even if such marks are included in this software.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
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

