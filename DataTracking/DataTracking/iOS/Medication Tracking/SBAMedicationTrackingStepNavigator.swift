//
//  SBAMedicationTrackingStepNavigator.swift
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
import JsonModel
import Research
import BridgeApp
import BridgeSDK

open class SBAMedicationTrackingStepNavigator : SBATrackedItemsStepNavigator {
    
    open override class func defaultType() -> RSDTaskType {
        .medicationTracking
    }
    
    var medicationResult: SBAMedicationTrackingResult? {
        return self._inMemoryResult as? SBAMedicationTrackingResult
    }

    override open class func decodeItems(from decoder: Decoder) throws -> (items: [SBATrackedItem], sections: [SBATrackedSection]?) {
        let container = try decoder.container(keyedBy: ItemsCodingKeys.self)
        let items = try container.decode([SBAMedicationItem].self, forKey: .items)
        let sections = try container.decodeIfPresent([SBATrackedSectionObject].self, forKey: .sections)
        return (items, sections)
    }
    
    override open class func buildSelectionStep(items: [SBATrackedItem], sections: [SBATrackedSection]?) -> SBATrackedItemsStep {
        let stepId = StepIdentifiers.selection.stringValue
        let step = SBATrackedSelectionStepObject(identifier: stepId, items: items, sections: sections)
        step.title = Localization.localizedString("MEDICATION_SELECTION_TITLE")
        step.detail = Localization.localizedString("MEDICATION_SELECTION_DETAIL")
        step.includePreviouslySelected = false
        return step
    }
    
    override open class func buildReviewStep(items: [SBATrackedItem], sections: [SBATrackedSection]?) -> SBATrackedItemsStep? {
        return SBATrackedMedicationReviewStepObject(identifier: StepIdentifiers.review.stringValue, items: items, sections: sections)
    }
    
    override open class func buildLoggingStep(items: [SBATrackedItem], sections: [SBATrackedSection]?) -> SBATrackedItemsStep {
        return SBAMedicationLoggingStepObject(identifier: StepIdentifiers.logging.stringValue, items: items, sections: sections)
    }
    
    override open func instantiateLoggingResult() -> SBATrackedItemsCollectionResult {
        return SBAMedicationTrackingResult(identifier: self.reviewStep!.identifier)
    }
    
    /// Override to check that at least one item has been filled in.
    override open func doesRequireReview() -> Bool {
        return medicationResult?.medications.first(where: { $0.hasRequiredValues }) == nil
    }
    
    /// Override to set reminder if the current reminders are nil.
    override open func doesRequireSetReminder() -> Bool {
        return medicationResult?.reminders == nil
    }
}

extension RSDIdentifier {
    
    public static let medicationReminders: RSDIdentifier = "medicationReminders"
    
    public static let logging: RSDIdentifier = "logging"
}

/// A medication item includes details for displaying a given medication.
public protocol SBAMedication : SBATrackedItem {
    
    /// Is the medication delivered via continuous injection? If this is the case, then questions about
    /// schedule timing and dosage should be skipped. Assumed `false` if `nil`.
    var isContinuousInjection: Bool? { get }
}

/// A medication item includes details for displaying a given medication.
///
/// - example:
/// ```
///    let json = """
///            {
///                "identifier": "advil",
///                "sectionIdentifier": "pain",
///                "title": "Advil",
///                "shortText": "Ibu",
///                "detail": "(Ibuprofen)",
///                "isExclusive": true,
///                "icon": "pill",
///                "injection": true
///            }
///            """.data(using: .utf8)! // our data in native (JSON) format
/// ```
public struct SBAMedicationItem : Codable, SBAMedication, RSDEmbeddedIconData {
    
    private enum CodingKeys : String, CodingKey {
        case identifier
        case sectionIdentifier
        case title
        case shortText
        case detail
        case _isExclusive = "isExclusive"
        case icon
        case isContinuousInjection = "injection"
    }
    
    /// A unique identifier that can be used to track the item.
    public let identifier: String
    
    /// An optional identifier that can be used to group the medication into a section.
    public let sectionIdentifier: String?

    /// Localized text to display as the full descriptor for the medication.
    public let title: String?
    
    /// Localized shortened text to display when used in a sentence.
    public let shortText: String?
    
    /// Detail text to display with additional information about the medication.
    public let detail: String?
    
    /// Whether or not the medication is set up so that *only* this can be selected
    /// for a given section.
    public var isExclusive: Bool {
        return _isExclusive ?? false
    }
    private let _isExclusive: Bool?
    
    /// An optional icon to display for the medication.
    public let icon: RSDResourceImageDataObject?
    
    /// Is the medication delivered via continuous injection? If this is the case, then questions about
    /// schedule timing and dosage should be skipped.
    public let isContinuousInjection: Bool?
    
    public init(identifier: String, sectionIdentifier: String?, title: String? = nil, shortText: String? = nil, detail: String? = nil, icon: RSDResourceImageDataObject? = nil, isExclusive: Bool = false, isContinuousInjection: Bool? = nil) {
        self.identifier = identifier
        self.sectionIdentifier = sectionIdentifier
        self.title = title
        self.shortText = shortText
        self.detail = detail
        self.icon = icon
        self._isExclusive = isExclusive
        self.isContinuousInjection = isContinuousInjection
    }
}

/// A medication answer for a given participant.
public struct SBAMedicationAnswer : Codable, SBATrackedItemAnswer {
    private enum CodingKeys : String, CodingKey {
        case identifier, dosageItems, isContinuousInjection = "injection"
    }
    
    /// An identifier that maps to the associated `RSDMedicationItem`.
    public let identifier: String
    
    /// The scheduled items associated with this medication result.
    public var dosageItems: [SBADosage]?
    
    /// Is the medication delivered via continuous injection? If this is the case, then questions about
    /// schedule timing and dosage should be skipped.
    public var isContinuousInjection: Bool?
    
    /// Required items for a medication are dosage and schedule unless this is a continuous injection.
    public var hasRequiredValues: Bool {
        // exit early if this is a continuous injection
        if (isContinuousInjection ?? false) { return true }
        guard let items = self.dosageItems, items.count > 0 else { return false }
        return items.reduce(true, { $0 && $1.hasRequiredValues })
    }
        
    /// Default initializer.
    /// - parameter identifier:
    public init(identifier: String) {
        self.identifier = identifier
    }
    
    /// When the participant taps the "save" button, finalize editing of this dosage by stripping out the
    /// information that should not be stored.
    mutating public func finalizeEditing() {
        guard let dosageItems = self.dosageItems else { return }
        var items = [String : SBADosage]()
        dosageItems.forEach {
            guard let dosage = $0.dosage, !dosage.isEmpty else { return }
            var newItem = $0
            if newItem.isAnytime == nil {
                // If the `isAnytime` property is not set, then figure out what it should be.
                let hasTimeOfDay = (newItem.timestamps?.first(where: { $0.timeOfDay != nil }) != nil)
                newItem.isAnytime = !hasTimeOfDay
            }
            if newItem.isAnytime! {
                // If this is an `isAnytime` dosage, then nil out the days of the week and time of day.
                newItem.daysOfWeek = nil
                newItem.timestamps = newItem.timestamps?.compactMap {
                    var timestamp = $0
                    guard timestamp.loggedDate != nil else { return nil }
                    timestamp.timeOfDay = nil
                    return timestamp
                }
            }
            if let existingItem = items[dosage], existingItem.daysOfWeek == $0.daysOfWeek, let existingTimestamps = existingItem.timestamps {
                // If there is already an existing item, add this one to that one.
                var timestamps = newItem.timestamps ?? []
                timestamps.append(contentsOf: existingTimestamps)
                newItem.timestamps = timestamps
            }
            // Filter and sort the timestamps.
            newItem.timestamps = newItem.timestamps?
                .filter { $0.timeOfDay != nil || $0.loggedDate != nil }
                .sorted(by: { (lhs, rhs) -> Bool in
                    if let lhsTime = lhs.timeOfDay, let rhsTime = rhs.timeOfDay {
                        return lhsTime < rhsTime
                    }
                    else if let lhsTime = lhs.loggedDate, let rhsTime = rhs.loggedDate {
                        return lhsTime < rhsTime
                    }
                    else {
                        return false
                    }
                })
            items[dosage] = newItem
        }
        self.dosageItems = items.map { $0.value }
    }
}

/// A dosage includes the dosage label and timestamps/timeOfDay for a given medication.
public struct SBADosage : Codable {    
    private enum CodingKeys : String, CodingKey {
        case dosage, daysOfWeek, timestamps
    }
    
    /// A string answer value for the dosage.
    public var dosage: String?
    
    /// The days of the week to include in the schedule. By default, this will be set to daily.
    public var daysOfWeek: Set<RSDWeekday>?
    
    /// Logged date and time of day mapping (if any).
    public var timestamps: [SBATimestamp]?
    
    /// Is this an "anytime" dosage?
    public var isAnytime: Bool?
    
    public init(dosage: String? = nil, daysOfWeek: Set<RSDWeekday>? = nil, timestamps: [SBATimestamp]? = nil, isAnytime: Bool? = nil) {
        self.dosage = dosage
        self.daysOfWeek = daysOfWeek
        self.timestamps = timestamps
        self.isAnytime = isAnytime
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.dosage = try container.decode(String.self, forKey: .dosage)
        let daysOfWeek = try container.decodeIfPresent(Set<RSDWeekday>.self, forKey: .daysOfWeek)
        let timestamps = try container.decodeIfPresent([SBATimestamp].self, forKey: .timestamps)
        let hasTimeOfDay = (daysOfWeek != nil) && (timestamps?.first(where: { $0.timeOfDay != nil }) != nil)
        self.daysOfWeek = hasTimeOfDay ? daysOfWeek : nil
        self.timestamps = timestamps
        self.isAnytime = !hasTimeOfDay
    }
    
    /// Required items for a medication are dosage and schedule unless this is a continuous injection.
    public var hasRequiredValues: Bool {
        guard let dosage = self.dosage, !dosage.isEmpty,
            let isAnytime = self.isAnytime
            else {
                return false
        }
        return isAnytime ? true : ((daysOfWeek?.count ?? 0) > 0 && self.selectedTimes.count > 0)
    }
    
    /// Map each dosage to a set of schedule items.
    public var scheduleItems: Set<RSDWeeklyScheduleObject>? {
        guard let timestamps = self.timestamps,
            let daysOfWeek = self.daysOfWeek
            else {
                return nil
        }
        return Set(timestamps.compactMap {
            guard let timeOfDay = $0.timeOfDay else { return nil }
            return RSDWeeklyScheduleObject(timeOfDayString: timeOfDay, daysOfWeek: daysOfWeek)
        })
    }
    
    /// Mapping of the selected times associated with this dosage. The `String` should be the timeOfDay
    /// string in the format used to track time of day.
    public var selectedTimes: Set<String> {
        return Set(self.timestamps?.compactMap { $0.timeOfDay } ?? [])
    }
    
    /// Localize and join the time of day strings.
    public func timesText() -> String? {
        guard let timestamps = self.timestamps?.filter({ $0.timeOfDay != nil }), timestamps.count > 0 else {
            return nil
        }
        let times = timestamps.sorted(by: { $0.timeOfDay! < $1.timeOfDay! }).compactMap { $0.localizedTime() }
        let delimiter = Localization.localizedString("LIST_FORMAT_DELIMITER")
        return times.joined(separator: delimiter)
    }
    
    /// Localize and join the days of the week string.
    public func daysText() -> String? {
        guard let days = self.daysOfWeek, days.count > 0 else { return nil }
        if days == RSDWeekday.all {
            return Localization.localizedString("SCHEDULE_EVERY_DAY")
        }
        else if days.count == 1, let text = days.first!.text {
            return text
        }
        else {
            let delimiter = Localization.localizedString("LIST_FORMAT_DELIMITER")
            return days.sorted().compactMap({ $0.shortText }).joined(separator: delimiter)
        }
    }
    
    /// When the participant taps the "save" button, finalize editing of this dosage by stripping
    /// out the information that should not be stored. This will also set the value of `isAnytime`
    /// to `true` upon the assumption that the participant forgot to select a timing.
    mutating public func finalizeEditing() {
        if self.isAnytime ?? true {
            self.isAnytime = true
            self.daysOfWeek = nil
            let timestamps = self.timestamps?.compactMap {
                $0.loggedDate != nil ? SBATimestamp(timeOfDay: nil, loggedDate: $0.loggedDate) : nil
            }
            self.timestamps = (timestamps?.count ?? 0 > 0) ? timestamps : nil
        }
        else {
            self.daysOfWeek = self.daysOfWeek ?? RSDWeekday.all
            self.timestamps = self.timestamps?.filter { $0.timeOfDay != nil }
        }
    }
}


/// V1 coding for a Medication Answer.
public struct SBAMedicationAnswerV1 : Codable {
    private enum CodingKeys : String, CodingKey {
        case identifier, dosage, scheduleItems, isContinuousInjection = "injection", timestamps
    }
    public let identifier: String
    public let dosage: String?
    public let scheduleItems: Set<RSDWeeklyScheduleObject>?
    public let isContinuousInjection: Bool?
    public let timestamps: [SBATimestamp]?
    
    func convert() -> SBAMedicationAnswer {
        var dosageItems = [SBADosage]()
        scheduleItems?.forEach { (schedule) in
            let timeOfDay = schedule.timeOfDayString
            let isAnytime = (self.dosage == nil) ? nil : (timeOfDay == nil)
            let timestamps: [SBATimestamp]? = {
                guard let anytime = isAnytime else { return nil }
                if anytime {
                    return self.timestamps?.filter { $0.timeOfDay == nil }
                }
                else if let timestamp = self.timestamps?.first(where: { $0.timeOfDay == timeOfDay }) {
                    return [timestamp]
                }
                else {
                    return nil
                }
            }()
            let daysOfWeek = (timeOfDay != nil) ? schedule.daysOfWeek : nil
            dosageItems.append(SBADosage(dosage: self.dosage, daysOfWeek: daysOfWeek, timestamps: timestamps, isAnytime: isAnytime))
        }
        var med = SBAMedicationAnswer(identifier: self.identifier)
        med.dosageItems = dosageItems
        med.finalizeEditing()
        return med
    }
}

/// Extend the medication answer to allow for adding medication using an "Other" style field during
/// selection. All values defined in this section are `nil` or `false`.
extension SBAMedicationAnswer : SBAMedication {
    
    public var sectionIdentifier: String? {
        return nil
    }
    
    public var title: String? {
        return self.identifier
    }
    
    public var detail: String? {
        return nil
    }
    
    public var shortText: String? {
        return nil
    }
    
    public var isExclusive: Bool {
        return false
    }
    
    public var imageData: RSDImageData? {
        return nil
    }
}

/// A medication tracking result which can be used to track the selected medications and details for each
/// medication.
public struct SBAMedicationTrackingResult : Codable, SBATrackedItemsCollectionResult, RSDNavigationResult, SerializableResultData {

    private enum CodingKeys : String, CodingKey {
        case identifier, serializableType = "type", startDate, endDate, medications = "items", reminders, revision, timeZone
    }
    
    /// The identifier associated with the task, step, or asynchronous action.
    public let identifier: String
    
    /// The revision number is used to set the coding to V1 medication answers or V2 medication answers.
    public private(set) var revision: Int?
    
    /// A String that indicates the type of the result. This is used to decode the result using a `RSDFactory`.
    public private(set) var serializableType: SerializableResultType = .medication
    
    /// The start date timestamp for the result.
    public var startDate: Date = Date()
    
    /// The end date timestamp for the result.
    public var endDate: Date = Date()
    
    /// The list of medications that are currently selected.
    public var medications: [SBAMedicationAnswer] = []
    
    /// A list of the selected answer items.
    public var selectedAnswers: [SBATrackedItemAnswer] {
        return medications
    }
    
    /// A list of minutes before the medication scheduled times that a user should be reminded about each medication
    public var reminders: [Int]?
    
    /// The step identifier of the next step to skip to after this one.
    public var skipToIdentifier: String? = nil
    
    /// The current timezone of the start date, used to determine "day" constraints.
    private var timeZone: TimeZone
    
    public init(identifier: String) {
        self.identifier = identifier
        self.revision = SBAMedicationTrackingResult.kCurrentEncodingRevision
        self.timeZone = TimeZone.current
    }
    
    internal init(identifier: String, timeZone: TimeZone) {
        self.identifier = identifier
        self.revision = SBAMedicationTrackingResult.kCurrentEncodingRevision
        self.timeZone = timeZone
    }
    
    private static let kCurrentEncodingRevision = 2
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.serializableType = .medication
        
        // For medications, the encoded results do not include these values by default
        // because they are ignored in favor of the timestamps.
        let identifier = try container.decodeIfPresent(String.self, forKey: .identifier)
        self.identifier = identifier ?? RSDIdentifier.logging.stringValue
        let startDate = try container.decodeIfPresent(Date.self, forKey: .startDate)
        let date = startDate ?? Date()
        self.startDate = date
        let endDate = try container.decodeIfPresent(Date.self, forKey: .endDate)
        self.endDate = endDate ?? date
        
        if let timeZoneDate = try container.decodeIfPresent(String.self, forKey: .startDate),
            let timeZone = TimeZone(iso8601: timeZoneDate) {
            self.timeZone = timeZone
        }
        else {
            self.timeZone = TimeZone.current
        }
        
        let medicationData = try MedicationData(from: decoder)
        self.reminders = medicationData.reminders
        self.medications = medicationData.medications
        
        // If re-encoded, should encode with the current revision
        self.revision = SBAMedicationTrackingResult.kCurrentEncodingRevision
    }
    
    public func copy(with identifier: String) -> SBAMedicationTrackingResult {
        var copy = SBAMedicationTrackingResult(identifier: identifier)
        copy.startDate = self.startDate
        copy.endDate = self.endDate
        copy.serializableType = self.serializableType
        copy.medications = self.medications
        copy.reminders = self.reminders
        copy.revision = self.revision
        copy.timeZone = self.timeZone
        return copy
    }
    
    public func deepCopy() -> SBAMedicationTrackingResult {
        self.copy(with: self.identifier)
    }
    
    mutating public func updateSelected(to selectedIdentifiers: [String]?, with items: [SBATrackedItem]) {
        guard let newIdentifiers = selectedIdentifiers, newIdentifiers.count > 0 else {
            self.medications = []
            return
        }
        
        func getMedication(with identifier: String) -> SBAMedicationAnswer {
            return medications.first(where: { $0.identifier == identifier }) ?? SBAMedicationAnswer(identifier: identifier)
        }

        // Filter and replace the meds.
        var allIdentifiers = newIdentifiers
        var meds = items.compactMap { (item) -> SBAMedicationAnswer? in
            guard allIdentifiers.contains(item.identifier) else { return nil }
            allIdentifiers.remove(where: { $0 == item.identifier })
            var medication = getMedication(with: item.identifier)
            medication.isContinuousInjection = (item as? SBAMedication)?.isContinuousInjection
            return medication
        }
        
        // For the medications that weren't in the items set, then just add using the identifier.
        meds.append(contentsOf: allIdentifiers.map { getMedication(with: $0) })
        
        // Set the new array
        self.medications = meds
    }
    
    mutating public func updateDetails(from result: ResultData) {
        if let medsResult = result as? SBAMedicationTrackingResult {
            self.medications = medsResult.medications
        }
        else if let loggingResult = result as? SBATrackedLoggingResultObject {
            updateLogging(from: loggingResult)
        }
        else if result.identifier == RSDIdentifier.medicationReminders.stringValue {
            updateReminders(from: result)
        }
    }
    
    mutating func updateLogging(from loggingResult: SBATrackedLoggingResultObject) {
        guard let itemIdentifier = loggingResult.itemIdentifier,
            let timingIdentifier = loggingResult.timingIdentifier
                else {
                    return
            }
        self.updateLogging(itemIdentifier: itemIdentifier, timingIdentifier: timingIdentifier, loggedDate: loggingResult.loggedDate)
    }
    
    mutating func updateLogging(itemIdentifier: String, timingIdentifier: String, loggedDate: Date?) {
        guard let idx = medications.firstIndex(where: { $0.identifier == itemIdentifier })
            else {
                return
        }
        var medication = self.medications[idx]
        
        var timestampIndex: Int!
        guard let doseIndex = medication.dosageItems?.firstIndex(where: { (dose) -> Bool in
            guard let tIndex = dose.timestamps?.firstIndex(where: { $0.uuid == timingIdentifier })
                else {
                    return false
            }
            timestampIndex = tIndex
            return true
        }) ?? medication.dosageItems?.firstIndex(where: { $0.isAnytime ?? false })
            else {
                assertionFailure("Couldn't find a dose to attach the logged date to.")
                return
        }
        
        var dosageItems = medication.dosageItems!
        var dose = dosageItems[doseIndex]
        var timestamps = dose.timestamps ?? []
        if loggedDate == nil && (dose.isAnytime ?? false) {
            if let removeIdx = timestampIndex {
                timestamps.remove(at: removeIdx)
            }
        }
        else {
            var timestamp = (timestampIndex == nil) ? SBATimestamp() : timestamps[timestampIndex]
            timestamp.loggedDate = loggedDate
            timestamp.uuid = timingIdentifier
            if (timestampIndex == nil) {
                timestamps.append(timestamp)
            }
            else {
                timestamps.remove(at: timestampIndex)
                timestamps.insert(timestamp, at: timestampIndex)
            }
        }
        dose.timestamps = timestamps
        
        dosageItems.remove(at: doseIndex)
        dosageItems.insert(dose, at: doseIndex)
        medication.dosageItems = dosageItems
        
        self.medications.remove(at: idx)
        self.medications.insert(medication, at: idx)
    }
    
    mutating func updateReminders(from result: ResultData) {
        let aResult = ((result as? RSDCollectionResult)?.children.first ?? result) as? RSDAnswerResult
        if let array = aResult?.value as? [Int] {
            self.reminders = array
        }
        else if let value = aResult?.value as? Int {
            self.reminders = [value]
        }
        else {
            self.reminders = []
        }
    }
    
    public func dataScore() throws -> JsonSerializable? {
        let dictionary = try self.rsd_jsonEncodedDictionary()
        return
            [CodingKeys.startDate.stringValue : SBAFactory.shared.encodeString(from: self.startDate, codingPath: []),
             CodingKeys.revision.stringValue : dictionary[CodingKeys.revision.stringValue],
             CodingKeys.medications.stringValue : dictionary[CodingKeys.medications.stringValue],
             CodingKeys.reminders.stringValue : dictionary[CodingKeys.reminders.stringValue]].jsonObject()
    }
    
    mutating public func updateSelected(from clientData: SBBJSONValue, with items: [SBATrackedItem]) throws {
        let decoder = RSDFactory.shared.createJSONDecoder()
        let medsTracking = try decoder.decode(MedicationData.self, from: clientData)
        self.reminders = medsTracking.reminders
        var calendar = Calendar.iso8601
        calendar.timeZone = self.timeZone
        let today = calendar.dateComponents([.year, .month, .day], from: self.startDate)
        self.medications = medsTracking.medications.map { (med) -> SBAMedicationAnswer in
            var medication = med
            medication.dosageItems = med.dosageItems?.map { (dosage) -> SBADosage in
                var dosage = dosage
                let timestamps = dosage.timestamps?.compactMap { (timestamp) -> SBATimestamp? in
                    guard let loggingDate = timestamp.loggedDate else { return timestamp }
                    calendar.timeZone = timestamp.timeZone
                    let log = calendar.dateComponents([.year, .month, .day], from: loggingDate)
                    if log.year == today.year, log.month == today.month, log.day == today.day {
                        return timestamp
                    }
                    else if let timeOfDay = timestamp.timeOfDay {
                        return SBATimestamp(timeOfDay: timeOfDay, loggedDate: nil)
                    }
                    else {
                        return nil
                    }
                }
                dosage.timestamps = (timestamps?.count ?? 0 > 0) ? timestamps : nil
                return dosage
            }
            return medication
        }
    }
    
    private struct MedicationData : Decodable {
        let reminders: [Int]?
        let medications: [SBAMedicationAnswer]
        
        private enum CodingKeys : String, CodingKey {
            case medications = "items", reminders, revision
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.reminders = try container.decodeIfPresent([Int].self, forKey: .reminders)
            
            // Decode to V1 if missing revision or revision == 1
            if let revision = try container.decodeIfPresent(Int.self, forKey: .revision), revision > 1 {
                self.medications = try container.decode([SBAMedicationAnswer].self, forKey: .medications)
            }
            else {
                let meds = try container.decode([SBAMedicationAnswerV1].self, forKey: .medications)
                self.medications = meds.map { $0.convert() }
            }
        }
    }
}

/// A timestamp object is a light-weight Codable that can be used to record the timestamp for a logging event.
/// This object includes a `timingIdentifier` that maps to either an `SBATimeRange` or an
/// `RSDSchedule.timeOfDayString`.
public struct SBATimestamp : Codable, RSDScheduleTime {
    internal fileprivate(set) var uuid = UUID().uuidString
    
    private enum CodingKeys : String, CodingKey {
        case timeOfDay, loggedDate, quantity, timeZone
    }
    
    public init(timeOfDay: String? = nil, loggedDate: Date? = nil) {
        self.timeOfDay = timeOfDay
        self.loggedDate = loggedDate
        self.quantity = 1
        self.timeZone = TimeZone.current
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let timeOfDay = try container.decodeIfPresent(String.self, forKey: .timeOfDay)
        var validTimeOfDay = false
        if timeOfDay != nil {
            let regEx = try! NSRegularExpression(pattern: "(?:[01]\\d|2[0123]):(?:[012345]\\d)")
            let matches = regEx.numberOfMatches(in: timeOfDay!, options: [], range: NSRange(timeOfDay!.startIndex..., in: timeOfDay!))
            validTimeOfDay = (matches == 1)
        }
        let loggedDate = try container.decodeIfPresent(Date.self, forKey: .loggedDate)
        if loggedDate == nil && !validTimeOfDay {
            let context = DecodingError.Context(codingPath: container.codingPath, debugDescription: "loggedDate and timeOfDay cannot both be nil")
            throw DecodingError.keyNotFound(CodingKeys.loggedDate, context)
        }
        self.quantity = try container.decodeIfPresent(Int.self, forKey: .quantity) ?? 1
        self.loggedDate = loggedDate
        self.timeOfDay = validTimeOfDay ? timeOfDay : nil
        
        if let timeZoneIdentifier = try container.decodeIfPresent(String.self, forKey: .timeZone),
            let timeZone = TimeZone(identifier: timeZoneIdentifier) {
            self.timeZone = timeZone
        }
        else if let dateString = try container.decodeIfPresent(String.self, forKey: .loggedDate),
            let timeZone = TimeZone(iso8601: dateString) {
            self.timeZone = timeZone
        }
        else {
            self.timeZone = TimeZone.current
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(self.timeOfDay, forKey: .timeOfDay)
        try container.encode(self.quantity, forKey: .quantity)
        if let loggedDate = self.loggedDate {
            let formatter = encoder.factory.timestampFormatter.copy() as! DateFormatter
            formatter.timeZone = self.timeZone
            let loggingString = formatter.string(from: loggedDate)
            try container.encode(loggingString, forKey: .loggedDate)
            try container.encode(self.timeZone.identifier, forKey: .timeZone)
        }
    }
    
    /// When the logged event is scheduled to occur.
    public var timeOfDay: String?
    
    /// The time/date for when the event was logged as *actually* occuring.
    public var loggedDate: Date?
    
    /// The number of times the event was logged at a given time.
    public var quantity: Int
    
    /// The time zone when the event was logged.
    public let timeZone: TimeZone
    
    /// The time of day from the `RSDSchedule` that can be used to identify this schedule.
    public var timeOfDayString : String? {
        return timeOfDay
    }
    
    /// The time range for this timestamp.
    public func timeRange(on date: Date) -> SBATimeRange {
        return self.timeOfDay(on: date)?.timeRange() ?? loggedDate?.timeRange() ?? date.timeRange()
    }
}

