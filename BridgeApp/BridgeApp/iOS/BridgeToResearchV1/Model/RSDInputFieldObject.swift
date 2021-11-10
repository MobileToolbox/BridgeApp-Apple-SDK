//
//  RSDInputFieldObject.swift
//  Research
//
//  Copyright © 2017-2018 Sage Bionetworks. All rights reserved.
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

extension Date {
    func yearComponent() -> Int {
        Calendar.iso8601.component(.year, from: self)
    }
}

/// `RSDInputFieldObject` is a `Decodable` implementation of the `RSDSurveyInputField` protocol. This is implemented as
/// an open class so that the decoding strategy can be used to support subclasses.
///
open class RSDInputFieldObject : RSDInputField, RSDSurveyInputField, RSDMutableInputField, RSDCopyInputField, Codable {
    
    private enum CodingKeys : String, CodingKey, CaseIterable {
        case identifier
        case inputPrompt = "prompt"
        case inputPromptDetail = "promptDetail"
        case placeholder
        case dataType = "type"
        case inputUIHint = "uiHint"
        case isOptional = "optional"
        case textFieldOptions
        case range
        case surveyRules
    }

    /// A short string that uniquely identifies the input field within the step. The identifier is reproduced in the
    /// results of a step result in the step history of a task result.
    public let identifier: String
    
    /// The data type for this input field. The data type can have an associated ui hint.
    open private(set) var dataType: RSDFormDataType
    
    /// A UI hint for how the study would prefer that the input field is displayed to the user.
    open private(set) var inputUIHint: RSDFormUIHint?
    
    /// A localized string that displays a short text offering a hint to the user of the data to be entered for
    /// this field. This is only applicable for certain types of UI hints and data types.
    open var inputPrompt: String?
    
    /// Additional detail about this input field.
    open var inputPromptDetail: String?
    
    /// A localized string that displays placeholder information for the input field.
    ///
    /// You can display placeholder text in a text field or text area to help users understand how to answer
    /// the item's question.
    open var placeholder: String?
    
    /// Options for displaying a text field. This is only applicable for certain types of UI hints and data types.
    open var textFieldOptions: RSDTextFieldOptions?
    
    /// A range used by dates and numbers for setting up a picker wheel, slider, or providing text field
    /// input validation. This is only applicable for certain types of UI hints and data types.
    open var range: RSDRange?
    
    /// A Boolean value indicating whether the user can skip the input field without providing an answer.
    open var isOptional: Bool = true
    
    /// A list of survey rules associated with this input field.
    open var surveyRules: [RSDSurveyRule]?
    
    /// A formatter that is appropriate to the data type. If `nil`, the format will be determined by the UI.
    /// This is the formatter used to display a previously entered answer to the user or to convert an answer
    /// entered in a text field into the appropriate value type.
    ///
    /// - seealso: `RSDAnswerResultType.BaseType` and `RSDFormStepDataSource`
    open var formatter: Formatter? {
        get {
            return _formatter ?? (self.range as? RSDRangeWithFormatter)?.formatter
        }
        set {
            _formatter = newValue
        }
    }
    private var _formatter: Formatter?
    
    /// Default for the picker source is to optionally cast self.
    open var pickerSource: RSDPickerDataSource? {
        return self as? RSDPickerDataSource
    }
    
    /// Default intializer.
    ///
    /// - parameters:
    ///     - identifier: A short string that uniquely identifies the input field within the step.
    ///     - dataType: The data type for this input field.
    ///     - uiHint: A UI hint for how the study would prefer that the input field is displayed to the user.
    ///     - prompt: A localized string that displays a short text offering a hint to the user of the data to be entered for
    ///               this field.
    public init(identifier: String, dataType: RSDFormDataType, uiHint: RSDFormUIHint? = nil, prompt: String? = nil) {
        self.identifier = identifier
        self.dataType = dataType
        self.inputUIHint = uiHint
        self.inputPrompt = prompt
    }
    
    public required init(identifier: String, dataType: RSDFormDataType) {
        self.identifier = identifier
        self.dataType = dataType
    }
    
    public func copy(with identifier: String) -> Self {
        let copy = type(of: self).init(identifier: identifier, dataType: dataType)
        copyInto(copy as RSDInputFieldObject)
        return copy
    }
    
    /// Swift subclass override for copying properties from the instantiated class of the `copy(with:)`
    /// method. Swift does not nicely handle casting from `Self` to a class instance for non-final classes.
    /// This is a work around.
    open func copyInto(_ copy: RSDInputFieldObject) {
        copy.inputUIHint = self.inputUIHint
        copy.inputPrompt = self.inputPrompt
        copy.inputPromptDetail = self.inputPromptDetail
        copy.placeholder = self.placeholder
        copy.textFieldOptions = self.textFieldOptions
        copy.range = self.range
        copy.isOptional = self.isOptional
        copy.surveyRules = self.surveyRules
        copy._formatter = self._formatter
    }
    
    public func copyInto(_ copy: AbstractInputItemObject) {
        copy.fieldLabel = self.inputPrompt
        copy.placeholder = self.placeholder
        if let uiHint = self.inputUIHint {
            copy.inputUIHint = uiHint
        }
        if copy.isOptional != self.isOptional {
            copy.isOptional = self.isOptional
        }
    }
    
    /// Validate the input field to check for any configuration that should throw an error.
    open func validate() throws {
    }
    
    /// Class function for decoding the data type from the decoder. The default implementation will key to
    /// `CodingKeys.dataType`.
    ///
    /// - parameter decoder: The decoder used to decode this object.
    /// - returns: The decoded `RSDFormDataType` data type.
    /// - throws: `DecodingError` if the data type field is missing or is not a `String`.
    public final class func dataType(from decoder: Decoder) throws -> RSDFormDataType {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        return try container.decode(RSDFormDataType.self, forKey: .dataType)
    }
    
    /// Overridable class function for decoding the `RSDTextFieldOptions` from the decoder. The default implementation
    /// will key to `CodingKeys.textFieldOptions`. If no text field options are defined in the decoder, then for certain
    /// data types, the default keyboard type is instantiated.
    ///
    /// If the data type has a `BaseType` of an `integer`, an instance of `RSDTextFieldOptionsObject` will be created with
    /// a `numberPad` keyboard type.
    ///
    /// If the data type has a `BaseType` of a `decimal`, an instance of `RSDTextFieldOptionsObject` will be created with
    /// a `decimalPad` keyboard type.
    ///
    /// - parameters:
    ///     - decoder: The decoder used to decode this object.
    ///     - dataType: The data type associated with this instance.
    /// - returns: An appropriate instance of `RSDTextFieldOptions` or `nil` if none is present.
    /// - throws: `DecodingError`
    open class func textFieldOptions(from decoder: Decoder, dataType: RSDFormDataType) throws -> RSDTextFieldOptions? {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let textFieldOptions = try container.decodeIfPresent(RSDTextFieldOptionsObject.self, forKey: .textFieldOptions) {
            return textFieldOptions
        }
        // If there isn't a text field returned, then set the default for certain types
        switch dataType.baseType {
        case .integer:
            return RSDTextFieldOptionsObject(keyboardType: .numberPad)
        case .decimal:
            return RSDTextFieldOptionsObject(keyboardType: .decimalPad)
        default:
            return nil
        }
    }
    
    /// Initialize from a `Decoder`. This decoding method will decode all the properties for this
    /// input field.
    ///
    /// - parameter decoder: The decoder to use to decode this instance.
    /// - throws: `DecodingError`
    public required init(from decoder: Decoder) throws {
        
        let dataType = try type(of: self).dataType(from: decoder)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let factory = decoder.factory
        
        // Look to the form step for an identifier.
        if !container.contains(.identifier),
            let identifier = decoder.codingInfo?.userInfo[.stepIdentifier] as? String {
            self.identifier = identifier
        }
        else {
            self.identifier = try container.decode(String.self, forKey: .identifier)
        }
        
        // Decode the survey rules from the factory.
        if container.contains(.surveyRules) {
            let nestedContainer = try container.nestedUnkeyedContainer(forKey: .surveyRules)
            self.surveyRules = try factory.decodeSurveyRules(from: nestedContainer, for: dataType)
        }
        else {
             self.surveyRules = nil
        }
        
        // Decode the range from the factory.
        if container.contains(.range) {
            let nestedDecoder = try container.superDecoder(forKey: .range)
            self.range = try factory.decodeRange(from: nestedDecoder, for: dataType)
        }
        else {
            self.range = nil
        }
        
        self.dataType = dataType
        self.inputUIHint = try container.decodeIfPresent(RSDFormUIHint.self, forKey: .inputUIHint)
        self.textFieldOptions = try type(of: self).textFieldOptions(from: decoder, dataType: dataType)
        self.inputPrompt = try container.decodeIfPresent(String.self, forKey: .inputPrompt)
        self.inputPromptDetail = try container.decodeIfPresent(String.self, forKey: .inputPromptDetail)
        self.placeholder = try container.decodeIfPresent(String.self, forKey: .placeholder)
        self.isOptional = try container.decodeIfPresent(Bool.self, forKey: .isOptional) ?? false
    }
    
    /// Encode the object to the given encoder.
    /// - parameter encoder: The encoder to use to encode this instance.
    /// - throws: `EncodingError`
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.identifier, forKey: .identifier)
        try container.encode(self.dataType, forKey: .dataType)
        try container.encodeIfPresent(inputPrompt, forKey: .inputPrompt)
        try container.encodeIfPresent(inputPromptDetail, forKey: .inputPromptDetail)
        try container.encodeIfPresent(placeholder, forKey: .placeholder)
        try container.encodeIfPresent(inputUIHint, forKey: .inputUIHint)
        if let obj = self.range {
            let nestedEncoder = container.superEncoder(forKey: .range)
            guard let encodable = obj as? Encodable else {
                throw EncodingError.invalidValue(obj, EncodingError.Context(codingPath: nestedEncoder.codingPath, debugDescription: "The range does not conform to the Encodable protocol"))
            }
            try encodable.encode(to: nestedEncoder)
        }
        if let obj = self.textFieldOptions {
            let nestedEncoder = container.superEncoder(forKey: .textFieldOptions)
            guard let encodable = obj as? Encodable else {
                throw EncodingError.invalidValue(obj, EncodingError.Context(codingPath: nestedEncoder.codingPath, debugDescription: "The textFieldOptions does not conform to the Encodable protocol"))
            }
            try encodable.encode(to: nestedEncoder)
        }
        try container.encode(isOptional, forKey: .isOptional)
        if let obj = self.surveyRules {
            var nestedContainer = container.nestedUnkeyedContainer(forKey: .surveyRules)
            guard let encodables = obj as? [Encodable] else {
                throw EncodingError.invalidValue(obj, EncodingError.Context(codingPath: nestedContainer.codingPath, debugDescription: "The surveyRules do not conform to the Encodable protocol"))
            }
            
            for encodable in encodables {
                let nestedEncoder = nestedContainer.superEncoder()
                try encodable.encode(to: nestedEncoder)
            }
        }
    }
}

extension RSDFactory {

    /// Overridable  function for decoding the range from the decoder. The default implementation will
    /// decode a range object appropriate to the data type.
    ///
    /// | RSDFormDataType.BaseType      | Type of range to decode                                    |
    /// |-------------------------------|:----------------------------------------------------------:|
    /// | .integer, .decimal, .fraction | `RSDNumberRangeObject`                                     |
    /// | .date                         | `RSDDateRangeObject`                                       |
    /// | .year                         | `RSDDateRangeObject` or `RSDNumberRangeObject`             |
    /// | .duration                     | `RSDDurationRangeObject`                                   |
    ///
    /// - parameters:
    ///     - decoder: The decoder used to decode this object.
    ///     - dataType: The data type associated with this instance.
    /// - returns: An appropriate instance of `RSDRange`.
    /// - throws: `DecodingError`
    /// - seealso: `RSDInputFieldObject`
    func decodeRange(from decoder: Decoder, for dataType: RSDFormDataType) throws -> RSDRange? {
        switch dataType.baseType {
        case .integer, .decimal, .fraction:
            return try RSDNumberRangeObject(from: decoder)
        case .duration:
            return try RSDDurationRangeObject(from: decoder)
        case .date:
            return try RSDDateRangeObject(from: decoder)
        case .year:
            // For a year data type, we first need to check if there is a min/max range set using the date
            // and if so, return that. The decoder could fail to find any property keys and not fail to
            // decode because everything in the range is optional.
            if let dateRange = try? RSDDateRangeObject(from: decoder),
                (dateRange.minimumDate != nil || dateRange.maximumDate != nil) {
                return dateRange
            } else {
                return try RSDNumberRangeObject(from: decoder)
            }
        case .string, .boolean, .codable:
            let codingPath = decoder.codingPath
            let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Ranges for a \(dataType.baseType) data type are not supported.")
            throw DecodingError.typeMismatch(Codable.self, context)
        }
    }
        
    /// Overridable function for decoding a list of survey rules from an unkeyed container for a given data
    /// type. The default implementation will instantiate a list of `RSDComparableSurveyRuleObject` instances
    /// appropriate to the `BaseType` of the given data type.
    ///
    /// - example:
    ///
    /// The following will decode the "surveyRules" key as an array of `[RSDComparableSurveyRuleObject<Int>]`.
    ///
    ///     ````
    ///        {
    ///            "identifier": "foo",
    ///            "type": "integer",
    ///            "surveyRules" : [
    ///                            {
    ///                            "skipToIdentifier": "lessThan",
    ///                            "ruleOperator": "lt",
    ///                            "matchingAnswer": 0
    ///                            },
    ///                            {
    ///                            "skipToIdentifier": "greaterThan",
    ///                            "ruleOperator": "gt",
    ///                            "matchingAnswer": 1
    ///                            }
    ///                            ]
    ///        }
    ///     ````
    ///
    /// - parameters:
    ///     - rulesContainer: The unkeyed container for the survey rules.
    ///     - dataType: The data type associated with this instance.
    /// - returns: An array of survey rules.
    /// - throws: `DecodingError`
    /// - seealso: `RSDInputFieldObject`
    func decodeSurveyRules(from rulesContainer: UnkeyedDecodingContainer, for dataType: RSDFormDataType) throws -> [RSDSurveyRule] {
        var container = rulesContainer
        var surveyRules = [RSDSurveyRule]()
        while !container.isAtEnd {
            let nestedDecoder = try container.superDecoder()
            let surveyRule = try self.decodeSurveyRule(from: nestedDecoder, for: dataType)
            surveyRules.append(surveyRule)
        }
        return surveyRules
    }
    
    /// Overridable factory method for returning a survey rule. By default, this will return a
    /// `RSDComparableSurveyRuleObject` appropriate to the base type of the data type.
    func decodeSurveyRule(from decoder: Decoder, for dataType: RSDFormDataType) throws -> RSDSurveyRule {
        switch dataType.baseType {
        case .boolean:
            return try RSDComparableSurveyRuleObject<Bool>(from: decoder)
        case .string:
            return try RSDComparableSurveyRuleObject<String>(from: decoder)
        case .date:
            return try RSDComparableSurveyRuleObject<Date>(from: decoder)
        case .decimal, .duration:
            return try RSDComparableSurveyRuleObject<Double>(from: decoder)
        case .integer, .year:
            return try RSDComparableSurveyRuleObject<Int>(from: decoder)
        default:
            let codingPath = decoder.codingPath
            let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Survey rules for a .codable data type are not supported.")
            throw DecodingError.typeMismatch(Codable.self, context)
        }
    }
}
