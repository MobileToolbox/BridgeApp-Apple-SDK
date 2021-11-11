//
//  BridgeSDK+UnitTest.h
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

@import BridgeSDK;

/**
 Registering mocks using `SBBComponentManager` only appears to work if you are running unit tests
 with an app set up as the test harness. When setting up unit tests without this, the shared singletons
 do not get set up correctly. Since there is a bunch of unit tests that are assuming that those singletons
 are set up, I found that the quickest path to not crashing w/o using BridgeSDK.SBBBridgeTestHarness
 was to swizzle the getters. (syoung 11/11/2021)
 */

@interface BridgeSDK (UnitTest)

+ (SBBAppConfig * _Nullable)testAppConfig;
+ (void)setTestAppConfig: (SBBAppConfig * _Nonnull)appConfig;

+ (id<SBBParticipantManagerProtocol> _Nullable)testParticipantManager;
+ (void)setTestParticipantManager: (id<SBBParticipantManagerProtocol> _Nonnull) manager;

+ (id<SBBActivityManagerProtocol> _Nullable)testActivityManager;
+ (void)setTestActivityManager: (id<SBBActivityManagerProtocol> _Nonnull) manager;

@end
