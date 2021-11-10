//
//  SBAActivityReference.swift
//  BridgeApp
//
//  Copyright © 2018 Sage Bionetworks. All rights reserved.
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
import BridgeSDK
import Research
import JsonModel
import MobilePassiveData


/// `SBAActivityReference` is used to cast all the activity reference types to a
/// common interface. This includes both compound tasks with different schema tables
/// for each task and single tasks with a single schema table.
public protocol SBAActivityReference : AnyObject, RSDTaskInfo {
    
    /// The detailed description of the activity. This maps to the `detail` property of
    /// the `RSDTaskInfo` protocol.
    var activityDescription: String? { get }
}

/// `SBASingleActivityReference` refers to tasks that point at a single instance of
/// the schema reference.
public protocol SBASingleActivityReference : SBAActivityReference, RSDTaskInfoStep {
    
    /// Optional number for the estimated minutes.
    var minuteDuration: NSNumber? { get }
    
    /// Optional schema info for this activity reference.
    var schemaInfo: RSDSchemaInfo? { get }
}

extension SBAActivityReference {
    
    /// Return the activity info from the configuration map.
    public var activityInfo : SBAActivityInfo? {
        return SBABridgeConfiguration.shared.activityInfo(for: self.identifier)
    }
    
    /// Return the activity info title.
    public var title: String? {
        return self.activityInfo?.title
    }
    
    /// Return the activity info subtitle.
    public var subtitle: String? {
        return self.activityInfo?.subtitle
    }
    
    /// Return `activityDescription` or if `nil`, the activity info detail.
    public var detail: String? {
        return self.activityDescription ?? self.activityInfo?.detail
    }
    
    /// Return the activity info imageData.
    public var imageData: RSDImageData? {
        return self.activityInfo?.imageData
    }
    
    /// The resource transformer on `RSDTaskInfo` is used in cases where the transformer is
    /// loaded from a resource by the task info (when decoded). In the case of Bridge objects,
    /// this does not apply. Instead, the bridge objects defer to the app configuation singletons.
    /// - returns: `nil`
    public var resourceTransformer: RSDTaskTransformer? {
        return nil
    }
}

extension SBASingleActivityReference {
    
    /// For single activity references, the reference is both the task info and the step.
    public var taskInfo: RSDTaskInfo {
        return self
    }
    
    /// Return the `minuteDuration` if not nil, otherwise return the activity info estimated minutes.
    public var estimatedMinutes : Int {
        return minuteDuration?.intValue ?? self.activityInfo?.estimatedMinutes ?? 0
    }
    
    /// Returns `.taskInfo`.
    public var stepType: RSDStepType {
        return .taskInfo
    }
    
    /// Instantiates a `RSDTaskResultObject`.
    public func instantiateStepResult() -> ResultData {
        return RSDTaskResultObject(identifier: self.identifier,
                                   versionString: self.schemaInfo?.versionString,
                                   assessmentIdentifier: self.identifier,
                                   schemaIdentifier: self.schemaInfo?.schemaIdentifier)
    }
}

extension SBBSchemaReference : SBASingleActivityReference, RSDSchemaInfo {
    
    public var schemaInfo: RSDSchemaInfo? {
        return self
    }
    
    public var schemaIdentifier: String? {
        return self.identifier
    }
    
    public var schemaVersion: Int {
        return self.revision?.intValue ?? 1
    }
}

extension SBBTaskReference : SBASingleActivityReference {
    
    public var schemaInfo: RSDSchemaInfo? {
        return SBABridgeConfiguration.shared.schemaInfo(for: self.identifier)
    }
}

extension SBBSurveyReference : SBASingleActivityReference {
    
    public var schemaInfo: RSDSchemaInfo? {
        return nil
    }
}

/// `SBBCompoundActivity` is the task info step, transformer, task, and step navigator
/// where each step is a `SBASingleActivityReference`.
extension SBBCompoundActivity {
    
    /// Total number of subtasks.
    var count : Int {
        return (schemaList?.count ?? 0) + (surveyList?.count ?? 0)
    }
    
    fileprivate var _surveyList : [SBBSurveyReference] {
        return self.surveyList as? [SBBSurveyReference] ?? []
    }
    
    fileprivate var _schemaList : [SBBSchemaReference] {
        return self.schemaList as? [SBBSchemaReference] ?? []
    }
    
    fileprivate func _index(of step: RSDStep) -> Int? {
        if let ref = step as? SBBSurveyReference {
            return _surveyList.firstIndex(of: ref)
        } else if let ref = step as? SBBSchemaReference, let idx = _schemaList.firstIndex(of: ref) {
            return idx + _surveyList.count
        } else {
            return nil
        }
    }
}

extension SBBCompoundActivity : SBAActivityReference {
    
    public var estimatedMinutes: Int {
        return _surveyList.reduce(0, { $0 + $1.estimatedMinutes }) +
            _schemaList.reduce(0, { $0 + $1.estimatedMinutes })
    }
    
    /// Return nil. Does not apply to a combo task.
    public var schemaInfo: RSDSchemaInfo? {
        return nil
    }
    
    public var stepType: RSDStepType {
        return .taskInfo
    }
    
    public func instantiateStepResult() -> ResultData {
        return RSDTaskResultObject(identifier: identifier)
    }
}

extension SBBCompoundActivity : RSDStepNavigator {

    public func step(with identifier: String) -> RSDStep? {
        return _surveyList.first(where: { $0.identifier == identifier }) ??
            _schemaList.first(where: { $0.identifier == identifier })
    }
    
    public func shouldExit(after step: RSDStep?, with result: RSDTaskResult) -> Bool {
        return false
    }
    
    public func hasStep(after step: RSDStep?, with result: RSDTaskResult) -> Bool {
        guard let ref = step else { return count > 0 }
        guard let idx = _index(of: ref) else { return false }
        return idx + 1 < count
    }
    
    public func hasStep(before step: RSDStep, with result: RSDTaskResult) -> Bool {
        guard let idx = _index(of: step) else { return false }
        return idx > 0
    }
    
    public func step(after step: RSDStep?, with result: inout RSDTaskResult) -> (step: RSDStep?, direction: RSDStepDirection) {
        return (_step(after: step), .forward)
    }
    
    private func _step(after step: RSDStep?) -> RSDStep? {
        if step == nil {
            return _surveyList.first ?? _schemaList.first
        } else if let ref = step as? SBBSurveyReference {
            if let next = _surveyList.rsd_next(after: { $0.identifier == ref.identifier }) {
                return next
            } else {
                return _schemaList.first
            }
        } else if let ref = step as? SBBSchemaReference {
            return _schemaList.rsd_next(after: { $0.identifier == ref.identifier })
        } else {
            return nil
        }
    }
    
    public func step(before step: RSDStep, with result: inout RSDTaskResult) -> RSDStep? {
        if let ref = step as? SBBSurveyReference {
            return _surveyList.rsd_previous(before: { $0.identifier == ref.identifier })
        } else if let ref = step as? SBBSchemaReference {
            if let previous = _schemaList.rsd_previous(before: { $0.identifier == ref.identifier }) {
                return previous
            } else {
                return _surveyList.last
            }
        } else {
            return nil
        }
    }
    
    public func progress(for step: RSDStep, with result: RSDTaskResult?) -> (current: Int, total: Int, isEstimated: Bool)? {
        guard let idx = _index(of: step) else { return nil }
        return (idx + 1, count, false)
    }
}

extension SBBCompoundActivity : RSDTask {

    public var stepNavigator: RSDStepNavigator {
        return self
    }
    
    public var copyright: String? {
        return nil
    }
    
    public var asyncActions: [AsyncActionConfiguration]? {
        return nil
    }
    
    public func instantiateTaskResult() -> RSDTaskResult {
        return RSDTaskResultObject(identifier: identifier)
    }
}

