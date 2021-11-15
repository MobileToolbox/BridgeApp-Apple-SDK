//
//  BridgeSDK+UnitTest.m
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

#import <BridgeSDK/BridgeSDK.h>
#import "include/BridgeSDK+UnitTest.h"
#import <objc/runtime.h>

static SBBAppConfig * _currentTestAppConfig;
static BOOL _hasBeenSwizzled_AppConfig = false;

static id<SBBParticipantManagerProtocol> _currentTestParticipantManager;
static BOOL _hasBeenSwizzled_ParticipantManager = false;

static id<SBBActivityManagerProtocol> _currentTestActivityManager;
static BOOL _hasBeenSwizzled_ActivityManager = false;

@implementation BridgeSDK (UnitTest)

+ (void)swizzleAppConfig {
    if (!_hasBeenSwizzled_AppConfig) {
        _hasBeenSwizzled_AppConfig = true;
        
        // Swizzle the appConfig
        Method origMethod = class_getClassMethod(self, @selector(appConfig));
        Method newMethod = class_getClassMethod(self, @selector(sba_testAppConfig));
        method_exchangeImplementations(origMethod, newMethod);
    }
}

+ (SBBAppConfig *)sba_testAppConfig {
    return [BridgeSDKTest testAppConfig];
}

+ (void)swizzleParticipantManager {
    if (!_hasBeenSwizzled_ParticipantManager) {
        _hasBeenSwizzled_ParticipantManager = true;
        
        // Swizzle the appConfig
        Method origMethod = class_getClassMethod([BridgeSDK class], @selector(participantManager));
        Method newMethod = class_getClassMethod(self, @selector(sba_testParticipantManager));
        method_exchangeImplementations(origMethod, newMethod);
    }
}

+ (id<SBBParticipantManagerProtocol> _Nonnull)sba_testParticipantManager {
    return [BridgeSDKTest testParticipantManager];
}

+ (void)swizzleActivityManager {
    if (!_hasBeenSwizzled_ActivityManager) {
        _hasBeenSwizzled_ActivityManager = true;
        
        // Swizzle the appConfig
        Method origMethod = class_getClassMethod([BridgeSDK class], @selector(activityManager));
        Method newMethod = class_getClassMethod(self, @selector(sba_testActivityManager));
        method_exchangeImplementations(origMethod, newMethod);
    }
}

+ (id<SBBActivityManagerProtocol> _Nonnull)sba_testActivityManager {
    return [BridgeSDKTest testActivityManager];
}

@end

@implementation BridgeSDKTest

+ (SBBAppConfig *)testAppConfig {
    return _currentTestAppConfig;
}

+ (void)setTestAppConfig: (SBBAppConfig *)appConfig {
    _currentTestAppConfig = appConfig;
    [BridgeSDK swizzleAppConfig];
}

+ (id<SBBParticipantManagerProtocol> _Nullable)testParticipantManager {
    return _currentTestParticipantManager;
}

+ (void)setTestParticipantManager: (id<SBBParticipantManagerProtocol> _Nonnull) manager {
    _currentTestParticipantManager = manager;
    [BridgeSDK swizzleParticipantManager];
}

+ (id<SBBActivityManagerProtocol> _Nullable)testActivityManager {
    return _currentTestActivityManager;
}

+ (void)setTestActivityManager: (id<SBBActivityManagerProtocol> _Nonnull) manager {
    _currentTestActivityManager = manager;
    [BridgeSDK swizzleActivityManager];
}

@end

