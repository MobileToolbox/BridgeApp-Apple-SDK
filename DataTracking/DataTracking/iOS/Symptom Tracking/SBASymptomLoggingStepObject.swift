//
//  SBASymptomLoggingStepObject.swift
//  BridgeApp
//
//  Copyright © 2018-2021 Sage Bionetworks. All rights reserved.
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
import UIKit
import JsonModel
import Research
import ResearchUI
import BridgeApp

/// A step used for logging symptoms.
open class SBASymptomLoggingStepObject : SBATrackedItemsLoggingStepObject {
    
    open override class func defaultType() -> RSDStepType {
        .symptomLogging
    }
    
    #if !os(watchOS)
    /// Override to return a symptom logging step view controller.
    open override func instantiateViewController(with parent: RSDPathComponent?) -> (UIViewController & RSDStepController)? {
        return SBASymptomLoggingStepViewController(step: self, parent: parent)
    }
    #endif
    
    /// Override to return a `SBASymptomLoggingDataSource`.
    open override func instantiateDataSource(with parent: RSDPathComponent?, for supportedHints: Set<RSDFormUIHint>) -> RSDTableDataSource? {
        return SBASymptomLoggingDataSource(step: self, parent: parent)
    }
}

/// A data source used to handle symptom logging.
open class SBASymptomLoggingDataSource : SBATrackedLoggingDataSource {
    
    /// Override the instantiation of the table item to return a symptom table item.
    override open class func instantiateTableItem(at rowIndex: Int, inputField: RSDInputField, itemAnswer: SBATrackedItemAnswer, choice: RSDChoice) -> RSDTableItem {
        
        let loggedResult: SBATrackedLoggingResultObject = {
            if let result = itemAnswer as? SBATrackedLoggingResultObject {
                return result
            }
            else {
                var result = SBATrackedLoggingResultObject(identifier: itemAnswer.identifier, text: choice.text, detail: choice.detail)
                result.serializableType = .symptom
                result.loggedDate = Date()
                return result
            }
        }()
        
        return SBASymptomTableItem(loggedResult: loggedResult, rowIndex: rowIndex)
    }
    
    override open func step(for tableItem: RSDModalStepTableItem) -> RSDStep? {
        guard let symptomItem = tableItem as? SBASymptomTableItem else {
            return super.step(for: tableItem)
        }
        
        let formStep = SBASymptomDurationLevel.formStep(at: symptomItem.time)
        return formStep
    }
    
    override open func previousResult(for tableItem: RSDModalStepTableItem, with step: RSDStep) -> ResultData? {
        guard let symptomItem = tableItem as? SBASymptomTableItem else {
            return super.previousResult(for: tableItem, with: step)
        }
        return symptomItem.loggedResult.findResult(with: step.identifier)
    }
    
    override open func saveAnswer(for tableItem: RSDModalStepTableItem, from taskViewModel: RSDTaskViewModel) {
        guard let symptomItem = tableItem as? SBASymptomTableItem,
            let result = taskViewModel.taskResult.findAnswerResult(with: SBASymptomTableItem.ResultIdentifier.duration.stringValue)
            else {
                super.saveAnswer(for: tableItem, from: taskViewModel)
                return
        }
            
        // Let the delegate know that things are changing.
        self.delegate?.tableDataSourceWillBeginUpdate(self)
        
        // Update the result set for this source.
        symptomItem.duration = SBASymptomDurationLevel(result: result)
        updateResults(with: symptomItem)
        self.delegate?.tableDataSource(self, didRemoveRows: [symptomItem.indexPath], with: .none)
        self.delegate?.tableDataSource(self, didAddRows: [symptomItem.indexPath], with: .none)
            
        // reload the table delegate.
        self.delegate?.tableDataSourceDidEndUpdate(self)
    }
    
    /// Update the logged result with the new input result.
    func updateResults(with tableItem: SBASymptomTableItem) {
        
        var stepResult = self.trackingResult()
        stepResult.updateDetails(from: tableItem.loggedResult)
        self.taskResult.appendStepHistory(with: stepResult)
        
        // inform delegate that answers have changed
        delegate?.tableDataSource(self, didChangeAnswersIn: tableItem.indexPath.section)
    }
}

/// The severity level of the symptom being logged.
public enum SBASymptomSeverityLevel : Int, Codable {
    case none = 0, mild, moderate, severe
}

/// The medication timing for the symptom being logged.
public enum SBASymptomMedicationTiming : String, Codable {
    case preMedication = "pre-medication"
    case postMedication = "post-medication"

    public var intValue: Int {
        return SBASymptomMedicationTiming.sortOrder.firstIndex(of: self)!
    }
    
    public init?(intValue: Int) {
        guard intValue < SBASymptomMedicationTiming.sortOrder.count, intValue >= 0 else { return nil }
        self = SBASymptomMedicationTiming.sortOrder[intValue]
    }
    
    private static let sortOrder: [SBASymptomMedicationTiming] = [.preMedication, .postMedication]
}

/// The symptom duration as a "level" of duration length.
public enum SBASymptomDurationLevel : Int, Codable {
    
    case now, shortPeriod, littleWhile, morning, afternoon, evening, halfDay, halfNight, allDay, allNight
    
    private static let choiceKeys = [
        "DURATION_CHOICE_NOW",
        "DURATION_CHOICE_SHORT_PERIOD",
        "DURATION_CHOICE_A_WHILE",
        "DURATION_CHOICE_MORNING",
        "DURATION_CHOICE_AFTERNOON",
        "DURATION_CHOICE_EVENING",
        "DURATION_CHOICE_HALF_DAY",
        "DURATION_CHOICE_HALF_NIGHT",
        "DURATION_CHOICE_ALL_DAY",
        "DURATION_CHOICE_ALL_NIGHT"
    ]
    
    public init?(result: ResultData) {
        guard let answerResult = result as? RSDAnswerResult else { return nil }
        if let value = answerResult.value as? SBASymptomDurationLevel {
            self = value
        }
        else if let number = answerResult.value as? NSNumber {
            self.init(rawValue: number.intValue)
        }
        else if let rawValue = answerResult.value as? Int {
            self.init(rawValue: rawValue)
        }
        else if let stringValue = answerResult.value as? String {
            self.init(stringValue: stringValue)
        }
        else {
            return nil
        }
    }
    
    public init?(stringValue: String) {
        guard let rawValue = SBASymptomDurationLevel.choiceKeys.firstIndex(of: stringValue) else { return nil }
        self.init(rawValue: rawValue)
    }
    
    public var stringValue : String {
        return SBASymptomDurationLevel.choiceKeys[self.rawValue]
    }
    
    public var level : Int {
        switch self {
        case .now, .shortPeriod, .littleWhile:
            return rawValue
        case .morning, .afternoon, .evening:
            return SBASymptomDurationLevel.morning.rawValue
        case .halfDay, .halfNight:
            return SBASymptomDurationLevel.morning.level + 1
        case .allDay, .allNight:
            return SBASymptomDurationLevel.halfDay.level + 1
        }
    }
    
    public static func durationChoices(at time: Date) -> [SBASymptomDurationLevel] {
        switch time.timeRange() {
        case .morning:
            return [.now, .shortPeriod, .littleWhile, .morning, .halfDay, .allDay]
        case .afternoon:
            return [.now, .shortPeriod, .littleWhile, .afternoon, .halfDay, .allDay]
        case .evening:
            return [.now, .shortPeriod, .littleWhile, .evening, .halfDay, .allDay]
        case .night:
            return [.now, .shortPeriod, .littleWhile, .halfNight, .allNight]
        }
    }
    
    public static func formStep(at time: Date) ->  RSDFormUIStep {
        let identifier = SBASymptomTableItem.ResultIdentifier.duration.stringValue
        let choices = durationChoices(at: time)
        let inputField = RSDChoiceInputFieldObject(identifier: identifier, choices: choices, dataType: dataType)
        let formStep = RSDFormUIStepObject(identifier: identifier, inputFields: [inputField])
        formStep.title = Localization.localizedString("DURATION_SELECTION_TITLE")
        formStep.detail = Localization.localizedString("DURATION_SELECTION_DETAIL")
        formStep.actions = [.navigation(.goForward) : RSDUIActionObject(buttonTitle: Localization.localizedString("BUTTON_SAVE"))]
        return formStep
    }
    
    public static var dataType : RSDFormDataType {
        return .collection(.singleChoice, .string)
    }
    
    public static var answerType : RSDAnswerResultType {
        return .string
    }
    
    public init(from decoder: Decoder) throws {
        let singleContainer = try decoder.singleValueContainer()
        if let stringValue = try? singleContainer.decode(String.self) {
            self.init(stringValue: stringValue)!
        }
        else {
            let rawValue = try singleContainer.decode(Int.self)
            self.init(rawValue: rawValue)!
        }
    }
}

extension SBASymptomDurationLevel : RSDChoice {
    
    public var answerValue: Codable? {
        return self.stringValue
    }
    
    public var text: String? {
        let key = SBASymptomDurationLevel.choiceKeys[self.rawValue]
        return Localization.localizedString(key)
    }
    
    public var detail: String? {
        return nil
    }
    
    public var isExclusive: Bool {
        return true
    }
    
    public var imageData: RSDImageData? {
        return nil
    }
    
    public func isEqualToResult(_ result: ResultData?) -> Bool {
        guard let aResult = result, let level = SBASymptomDurationLevel(result: aResult) else { return false }
        return level == self
    }
}

/// The symptom table item is tracked using the result object.
open class SBASymptomTableItem : RSDModalStepTableItem {
    
    public enum ResultIdentifier : String, CodingKey, Codable {
        case severity, duration, medicationTiming, notes
    }
    
    /// The result object associated with this table item.
    public var loggedResult: SBATrackedLoggingResultObject
    
    /// The severity level of the symptom.
    public var severity : SBASymptomSeverityLevel? {
        get {
            guard let rawValue = loggedResult.findAnswerResult(with: ResultIdentifier.severity.rawValue)?.value as? Int
                else {
                    return nil
            }
            return SBASymptomSeverityLevel(rawValue: rawValue)
        }
        set {
            let answerResult = RSDAnswerResultObject(identifier: ResultIdentifier.severity.rawValue, answerType: .integer)
            answerResult.value = newValue?.rawValue
            loggedResult.appendInputResults(with: answerResult)
            if newValue != nil, loggedResult.loggedDate == nil {
                loggedResult.loggedDate = Date()
            }
        }
    }
    
    /// The time when the symptom started occuring.
    public var time: Date {
        get {
            return loggedResult.loggedDate ?? Date()
        }
        set {
            loggedResult.loggedDate = newValue
            if severity == nil {
                self.severity = .moderate
            }
        }
    }
    
    /// The duration window describing how long the symptoms occurred.
    public var duration: SBASymptomDurationLevel? {
        get {
            guard let result = loggedResult.findAnswerResult(with: ResultIdentifier.duration.rawValue) else { return nil }
            return SBASymptomDurationLevel(result: result)
        }
        set {
            let answerResult = RSDAnswerResultObject(identifier: ResultIdentifier.duration.rawValue, answerType: SBASymptomDurationLevel.answerType)
            answerResult.value = newValue?.answerValue
            loggedResult.appendInputResults(with: answerResult)
        }
    }
    
    /// The medication timing for when the symptom occurred.
    public var medicationTiming: SBASymptomMedicationTiming? {
        get {
            guard let rawValue = loggedResult.findAnswerResult(with: ResultIdentifier.medicationTiming.rawValue)?.value as? String
                else {
                    return nil
            }
            return SBASymptomMedicationTiming(rawValue: rawValue)        }
        set {
            let answerResult = RSDAnswerResultObject(identifier: ResultIdentifier.medicationTiming.rawValue, answerType: .string)
            answerResult.value = newValue?.rawValue
            loggedResult.appendInputResults(with: answerResult)
        }
    }
    
    /// Notes added by the participant.
    public var notes: String? {
        get {
            return loggedResult.findAnswerResult(with: ResultIdentifier.notes.rawValue)?.value as? String
        }
        set {
            let answerResult = RSDAnswerResultObject(identifier: ResultIdentifier.notes.rawValue, answerType: .string)
            answerResult.value = newValue
            loggedResult.appendInputResults(with: answerResult)
        }
    }
    
    /// Initialize a new RSDTableItem.
    /// - parameters:
    ///     - identifier: The cell identifier.
    ///     - rowIndex: The index of this item relative to all rows in the section in which this item resides.
    ///     - reuseIdentifier: The string to use as the reuse identifier.
    public init(loggedResult: SBATrackedLoggingResultObject, rowIndex: Int, reuseIdentifier: String = RSDFormUIHint.logging.rawValue) {
        self.loggedResult = loggedResult
        super.init(identifier: loggedResult.identifier, rowIndex: rowIndex, reuseIdentifier: reuseIdentifier)
    }
}

/// The symptom table item is tracked using the result object.
public struct SBASymptomResult : Codable, RSDScoringResult, SerializableResultData {
    private enum CodingKeys : String, CodingKey {
        case identifier, text, loggedDate, timeZone, severity, duration, medicationTiming, notes, serializableType = "type"
    }
    
    public let serializableType: SerializableResultType = .symptom
    
    public let identifier: String
    
    /// The start date timestamp for the result.
    public var startDate: Date = Date()
    
    /// The end date timestamp for the result.
    public var endDate: Date = Date()
    
    /// The text shown to the user as the title.
    public let text: String
    
    /// The date timestamp for when the item was logged.
    public var loggedDate: Date?
    
    /// The time zone in effect when the item was logged.
    public var timeZone: TimeZone = TimeZone.current
    
    /// The severity level of the symptom.
    public var severity : SBASymptomSeverityLevel?
    
    /// The time when the symptom started occuring.
    public var time: Date {
        get {
            return loggedDate ?? Date()
        }
        set {
            loggedDate = newValue
        }
    }
    
    /// The duration window describing how long the symptoms occurred.
    public var duration: SBASymptomDurationLevel?
    
    /// The medication timing for when the symptom occurred.
    public var medicationTiming: SBASymptomMedicationTiming?
    
    /// Notes added by the participant.
    public var notes: String?
    
    public func dataScore() throws -> JsonSerializable? {
        return try self.rsd_jsonEncodedDictionary().jsonObject()
    }
    
    public func buildArchiveData(at stepPath: String?) throws -> (manifest: RSDFileManifest, data: Data)? {
        // create the manifest and encode the result.
        let manifest = RSDFileManifest(filename: self.identifier, timestamp: self.startDate, contentType: "application/json", identifier: self.identifier, stepPath: stepPath)
        let data = try self.rsd_jsonEncodedData()
        return (manifest, data)
    }
    
    public init(identifier: String, text: String? = nil) {
        self.identifier = identifier
        self.text = text ?? identifier
    }
    
    public init(from decoder: Decoder) throws {
        //identifier, loggedDate, timeZone, severity, duration, medicationTiming, notes
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let identifier = try container.decode(String.self, forKey: .identifier)
        self.identifier = identifier
        let text = try container.decodeIfPresent(String.self, forKey: .text)
        self.text = text ?? identifier
        self.loggedDate = try container.decodeIfPresent(Date.self, forKey: .loggedDate)
        if let tzIdentifier = try container.decodeIfPresent(String.self, forKey: .timeZone),
            let timeZone = TimeZone(identifier: tzIdentifier) {
            self.timeZone = timeZone
        }
        if let iso8601 = try container.decodeIfPresent(String.self, forKey: .loggedDate),
            let timeZone = TimeZone(iso8601: iso8601) {
            self.timeZone = timeZone
        }
        else {
            self.timeZone = TimeZone.current
        }
        // syoung 07/29/2019 Because of a bug in the encoding, need to catch and nil out encoding
        // errors where the container has a type mismatch.
        do {
            self.severity = try container.decodeIfPresent(SBASymptomSeverityLevel.self, forKey: .severity)
        } catch DecodingError.typeMismatch(_, _) {
            self.severity = nil
        }
        do {
            self.duration = try container.decodeIfPresent(SBASymptomDurationLevel.self, forKey: .duration)
        } catch DecodingError.typeMismatch(_, _) {
            self.duration = nil
        }
        do {
            self.medicationTiming = try container.decodeIfPresent(SBASymptomMedicationTiming.self, forKey: .medicationTiming)
        } catch DecodingError.typeMismatch(_, _) {
            self.medicationTiming = nil
        }
        self.notes = try container.decodeIfPresent(String.self, forKey: .notes)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.identifier, forKey: .identifier)
        try container.encode(self.serializableType, forKey: .serializableType)
        try container.encode(self.text, forKey: .text)
        if let loggedDate = self.loggedDate {
            let formatter = encoder.factory.timestampFormatter.copy() as! DateFormatter
            formatter.timeZone = self.timeZone
            let loggingString = formatter.string(from: loggedDate)
            try container.encode(loggingString, forKey: .loggedDate)
            try container.encode(self.timeZone.identifier, forKey: .timeZone)
        }
        try container.encodeIfPresent(self.severity, forKey: .severity)
        if let durationString = self.duration?.stringValue {
            try container.encodeIfPresent(durationString, forKey: .duration)
        }
        try container.encodeIfPresent(self.medicationTiming, forKey: .medicationTiming)
        try container.encodeIfPresent(self.notes, forKey: .notes)
    }
    
    public func deepCopy() -> SBASymptomResult {
        self
    }
}

/// Wrapper for the clientData from a report.
public struct SBASymptomReportData : Codable {
    public let trackedItems : SBASymptomCollectionResult
}

/// Wrapper for a collection of symptoms as a result.
public struct SBASymptomCollectionResult : Codable, RSDCollectionResult, SerializableResultData {
    public let serializableType: SerializableResultType = .symptomCollection
    
    private enum CodingKeys : String, CodingKey {
        case identifier, serializableType = "type", startDate, endDate, symptomResults = "items"
    }
    
    public let identifier: String
    
    /// The start date timestamp for the result.
    public var startDate: Date = Date()
    
    /// The end date timestamp for the result.
    public var endDate: Date = Date()
    
    /// List of the symptom results.
    public var symptomResults: [SBASymptomResult] = []
    
    /// A wrapper for the input results.
    public var children: [ResultData] {
        get {
            return symptomResults
        }
        set {
            symptomResults = newValue.compactMap { $0 as? SBASymptomResult }
        }
    }
    
    public init(identifier: String) {
        self.identifier = identifier
    }
    
    public func deepCopy() -> SBASymptomCollectionResult {
        self
    }
}

