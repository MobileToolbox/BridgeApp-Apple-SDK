//
//  SBATrackedItemsLoggingStepObject.swift
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

/// `SBATrackedItemsLoggingStepObject` is a custom table step that can be used to log the same
/// information about a list of tracked items for each one.
open class SBATrackedItemsLoggingStepObject : SBATrackedSelectionStepObject {
    
    #if !os(watchOS)
    /// Implement the view controller vending in the model with compile flag. This is required so that
    /// subclasses can override this method to return a different implementation of the view controller.
    /// Note: The task delegate can also override this to return a different view controller.
    open func instantiateViewController(with parent: RSDPathComponent?) -> (UIViewController & RSDStepController)? {
        return SBATrackedLoggingStepViewController(step: self, parent: parent)
    }
    #endif
    
    /// Override to add the "submit" button for the action.
    override open func action(for actionType: RSDUIActionType, on step: RSDStep) -> RSDUIAction? {
        // If the dictionary includes an action then return that.
        if let action = self.actions?[actionType] { return action }
        // Only special-case for the goForward action.
        guard actionType == .navigation(.goForward) else { return nil }
        
        // If this is the goForward action then special-case to use the "Submit" button
        // if there isn't a button in the dictionary.
        let goForwardAction = RSDUIActionObject(buttonTitle: Localization.localizedString("BUTTON_SUBMIT"))
        var actions = self.actions ?? [:]
        actions[actionType] = goForwardAction
        self.actions = actions
        return goForwardAction
    }
    
    /// Override to return an instance of `SBATrackedLoggingDataSource`.
    override open func instantiateDataSource(with parent: RSDPathComponent?, for supportedHints: Set<RSDFormUIHint>) -> RSDTableDataSource? {
        return SBATrackedLoggingDataSource(step: self, parent: parent)
    }
    
    /// Override to return a collection result that is pre-populated with the a new set of logging objects.
    override open func instantiateStepResult() -> RSDResult {
        var collectionResult = SBATrackedLoggingCollectionResultObject(identifier: self.identifier)
        collectionResult.updateSelected(to: self.result?.selectedAnswers.map { $0.identifier }, with: self.items)
        return collectionResult
    }
}

extension RSDResultType {
    public static let loggingItem: RSDResultType = "loggingItem"
    public static let loggingCollection: RSDResultType = "loggingCollection"
    public static let symptom: RSDResultType = "symptom"
    public static let symptomCollection: RSDResultType = "symptomCollection"
    public static let trigger: RSDResultType = "trigger"
    public static let triggerCollection: RSDResultType = "triggerCollection"
}

/// `SBATrackedLoggingCollectionResultObject` is used include multiple logged items in a single logging result.
public struct SBATrackedLoggingCollectionResultObject : RSDCollectionResult, Codable, SBATrackedItemsCollectionResult, RSDNavigationResult {
    
    /// The identifier associated with the task, step, or asynchronous action.
    public let identifier: String
    
    /// A String that indicates the type of the result. This is used to decode the result using a `RSDFactory`.
    public var type: RSDResultType
    
    /// The start date timestamp for the result.
    public var startDate: Date = Date()
    
    /// The end date timestamp for the result.
    public var endDate: Date = Date()
    
    /// The list of logging results associated with this result.
    public var loggingItems: [SBATrackedLoggingResultObject]
    
    // The input results are the logging items.
    public var inputResults: [RSDResult] {
        get {
            return loggingItems
        }
        set {
            loggingItems = newValue.compactMap { $0 as? SBATrackedLoggingResultObject }
        }
    }
    
    /// The step identifier to skip to after this result.
    public var skipToIdentifier: String?
    
    /// Default initializer for this object.
    ///
    /// - parameters:
    ///     - identifier: The identifier string.
    public init(identifier: String) {
        self.identifier = identifier
        self.type = .loggingCollection
        self.loggingItems = []
    }
    
    private enum CodingKeys : String, CodingKey {
        case identifier, type, startDate, endDate, loggingItems = "items"
    }

    public func copy(with identifier: String) -> SBATrackedLoggingCollectionResultObject {
        var copy = SBATrackedLoggingCollectionResultObject(identifier: identifier)
        copy.startDate = self.startDate
        copy.endDate = self.endDate
        copy.type = self.type
        copy.loggingItems = self.loggingItems
        return copy
    }
    
    /// Returns the subset of selected answers that conform to the tracked item answer.
    public var selectedAnswers: [SBATrackedItemAnswer] {
        return self.loggingItems
    }
    
    /// Adds a `SBATrackedLoggingResultObject` for each identifier.
    public mutating func updateSelected(to selectedIdentifiers: [String]?, with items: [SBATrackedItem]) {
        let results = sort(selectedIdentifiers, with: items).map { (identifier) -> SBATrackedLoggingResultObject in
            if let result = self.loggingItems.first(where: { $0.identifier == identifier }) {
                return result
            }
            let item = items.first(where: { $0.identifier == identifier })
            return SBATrackedLoggingResultObject(identifier: identifier, text: item?.text, detail: item?.detail)
        }
        self.loggingItems = results
    }
    
    /// Update the details to the new value. This is only valid for a new value that is an `RSDResult`.
    public mutating func updateDetails(from result: RSDResult) {
        if let loggingResult = result as? SBATrackedLoggingResultObject {
            self.appendInputResults(with: loggingResult)
        }
        else if let collectionResult = result as? SBATrackedLoggingCollectionResultObject {
            self.loggingItems = collectionResult.loggingItems
        }
        else {
            assertionFailure("This is not a valid tracked item answer type. Cannot map to a result.")
        }
    }
    
    /// Build the client data for this result.
    public func dataScore() throws -> RSDJSONSerializable? {
        // Only include the client data for the logging result and not the selection result.
        guard identifier == RSDIdentifier.trackedItemsResult.stringValue
            else {
                return nil
        }
        return try self.rsd_jsonEncodedDictionary().jsonObject()
    }
    
    /// Update the selection from the client data.
    mutating public func updateSelected(from clientData: SBBJSONValue, with items: [SBATrackedItem]) throws {
        guard let dictionary = (clientData as? NSDictionary) ?? (clientData as? [NSDictionary])?.last
            else {
                assertionFailure("This is not a valid client data object.")
                return
        }
        let decoder = SBAFactory.shared.createJSONDecoder()
        let result = try decoder.decode(SBATrackedLoggingCollectionResultObject.self, from: dictionary)
        self.loggingItems = result.loggingItems.map {
            var loggedResult = $0
            loggedResult.loggedDate = nil
            loggedResult.inputResults = []
            return loggedResult
        }
    }
}

/// `SBATrackedLoggingResultObject` is used include multiple results associated with a tracked item.
public struct SBATrackedLoggingResultObject : RSDCollectionResult, Codable {

    private enum CodingKeys : String, CodingKey {
        case identifier, text, detail, loggedDate, itemIdentifier, timingIdentifier, timeZone
    }
    
    /// The identifier associated with the task, step, or asynchronous action.
    public let identifier: String
    
    /// The identifier that maps to the `SBATrackedItem`. 
    public var itemIdentifier: String?
    
    /// The timing identifier to map to a schedule.
    public var timingIdentifier: String?
    
    /// The title for the tracked item.
    public var text: String?
    
    /// A detail string for the tracked item.
    public var detail: String?
    
    /// The marker for when the tracked item was logged.
    public var loggedDate: Date?
    
    /// The time zone to use for the loggedDate.
    public let timeZone: TimeZone
    
    /// A String that indicates the type of the result. This is used to decode the result using a `RSDFactory`.
    public var type: RSDResultType = .loggingItem
    
    /// The start date timestamp for the result.
    public var startDate: Date = Date()
    
    /// The end date timestamp for the result.
    public var endDate: Date = Date()
    
    /// The list of input results associated with this step. These are generally assumed to be answers to
    /// field inputs, but they are not required to implement the `RSDAnswerResult` protocol.
    public var inputResults: [RSDResult]
    
    /// Default initializer for this object.
    ///
    /// - parameters:
    ///     - identifier: The identifier string.
    public init(identifier: String, text: String? = nil, detail: String? = nil) {
        self.identifier = identifier
        self.text = text
        self.detail = detail
        self.inputResults = []
        self.timeZone = TimeZone.current
    }
    
    /// Initialize from a `Decoder`. This decoding method will use the `RSDFactory` instance associated
    /// with the decoder to decode the `inputResults`.
    ///
    /// - parameter decoder: The decoder to use to decode this instance.
    /// - throws: `DecodingError`
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.identifier = try container.decode(String.self, forKey: .identifier)
        self.itemIdentifier = try container.decodeIfPresent(String.self, forKey: .itemIdentifier)
        self.timingIdentifier = try container.decodeIfPresent(String.self, forKey: .timingIdentifier)
        self.text = try container.decodeIfPresent(String.self, forKey: .text)
        self.detail = try container.decodeIfPresent(String.self, forKey: .detail)
        self.loggedDate = try container.decodeIfPresent(Date.self, forKey: .loggedDate)
        if let tzIdentifier = try container.decodeIfPresent(String.self, forKey: .timeZone) {
            self.timeZone = TimeZone(identifier: tzIdentifier) ?? TimeZone.current
        }
        else {
            self.timeZone = TimeZone.current
        }
        // TODO: syoung 05/30/2018 Decode the answers.
        self.inputResults = []
    }
    
    /// Encode the result to the given encoder.
    /// - parameter encoder: The encoder to use to encode this instance.
    /// - throws: `EncodingError`
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(identifier, forKey: .identifier)
        try container.encodeIfPresent(itemIdentifier, forKey: .itemIdentifier)
        try container.encodeIfPresent(timingIdentifier, forKey: .timingIdentifier)
        try container.encodeIfPresent(text, forKey: .text)
        try container.encodeIfPresent(detail, forKey: .detail)
        if let loggedDate = self.loggedDate {
            let formatter = encoder.factory.timestampFormatter
            formatter.timeZone = self.timeZone
            let loggingString = formatter.string(from: loggedDate)
            try container.encode(loggingString, forKey: .loggedDate)
            try container.encode(self.timeZone.identifier, forKey: .timeZone)
        }

        var anyContainer = encoder.container(keyedBy: AnyCodingKey.self)
        try inputResults.forEach { result in
            let key = AnyCodingKey(stringValue: result.identifier)!
            guard let answerResult = result as? RSDAnswerResult
                else {
                    var codingPath = encoder.codingPath
                    codingPath.append(key)
                    let context = EncodingError.Context(codingPath: codingPath, debugDescription: "Result does not conform to RSDAnswerResult protocol")
                    throw EncodingError.invalidValue(result, context)
            }
            guard let value = answerResult.value
                else {
                    return
            }
            let nestedEncoder = anyContainer.superEncoder(forKey: key)
            try answerResult.answerType.encode(value, to: nestedEncoder)
        }
    }
}

extension SBATrackedLoggingResultObject : SBATrackedItemAnswer {
    
    public var hasRequiredValues: Bool {
        if self.type == .symptom {
            // For a symptom result, need to have a severity.
            return (self.findAnswerResult(with: SBASymptomTableItem.ResultIdentifier.severity.stringValue)?.value != nil)
        }
        else {
            // otherwise, just marking the logged date is enough.
            return self.loggedDate != nil
        }
    }
    
    public var answerValue: Codable? {
        return self.identifier
    }
    
    public var isExclusive: Bool {
        return false
    }
    
    public var imageVendor: RSDImageVendor? {
        return nil
    }
    
    public func isEqualToResult(_ result: RSDResult?) -> Bool {
        return self.identifier == result?.identifier
    }
}
