//
//  SBADataTrackingFactory.swift
//  DataTracking (iOS)
//
//  Copyright © 2018-2019 Sage Bionetworks. All rights reserved.
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
import Research
import JsonModel
import BridgeApp

extension RSDTaskType {
    
    /// Defaults to creating a `SBAMedicationTrackingStepNavigator`.
    public static let medicationTracking: RSDTaskType = "medicationTracking"
    
    /// Defaults to creating a `SBATrackedItemsStepNavigator`.
    public static let tracking: RSDTaskType = "tracking"
}

extension RSDStepType {
    
    /// Defaults to creating a `SBATrackedItemsLoggingStepObject`.
    public static let logging: RSDStepType = "logging"
    
    /// Defaults to creating a `SBATrackedItemsReviewStepObject`.
    public static let review: RSDStepType = "review"
    
    /// Defaults to creating a `SBATrackedSelectionStepObject`.
    public static let selection: RSDStepType = "selection"
    
    /// Defaults to creating a `SBASymptomLoggingStepObject`.
    public static let symptomLogging: RSDStepType = "symptomLogging"
    
    /// Defaults to creating a `SBAMedicationRemindersStepObject`.
    public static let medicationReminders: RSDStepType = "medicationReminders"
    
    /// Defaults to creating a 'SBATrackedMedicationDetailStepObject'
    public static let medicationDetails: RSDStepType = "medicationDetails"
    
    /// Defaults to creating a 'SBAMedicationTrackingStep'
    public static let medicationTracking: RSDStepType = "medicationTracking"
}

extension SerializableResultType {
    
    public static let medication: SerializableResultType = "medication"
    
    public static let medicationDetails: SerializableResultType = "medicationDetails"
}

open class SBADataTrackingFactory : SBAFactory {
    
    public required init() {
        super.init()
        
        // Add steps to factory serializer
        self.stepSerializer.add(SBATrackedSelectionStepObject(identifier: "example", type: nil))
        self.stepSerializer.add(SBATrackedItemsLoggingStepObject(identifier: "example", type: nil))
        self.stepSerializer.add(SBASymptomLoggingStepObject(identifier: "example", type: nil))
        self.stepSerializer.add(SBATrackedItemRemindersStepObject(identifier: "example", type: nil))
        
        // Add tasks to serializer
        self.taskSerializer.add(SBAMedicationTrackingStepNavigator())
        self.taskSerializer.add(SBATrackedItemsStepNavigator())
    }
}
