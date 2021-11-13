//
//  RSDFormUIStepObject.swift
//  Research
//
//  Copyright © 2017-2021 Sage Bionetworks. All rights reserved.
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

extension CodingUserInfoKey {
    
    /// The key for the current step identifier to use when decoding a form step input field that should
    /// inherit the step identifier from the parent step.
    public static let stepIdentifier = CodingUserInfoKey(rawValue: "RSDFormUIStepObject.stepIdentifier")!
}

/// `RSDFormUIStepObject` is a concrete implementation of the `RSDFormUIStep` and
/// `RSDSurveyNavigationStep` protocols. It is a subclass of `RSDUIStepObject` and can be used to display
/// a navigable survey.
open class RSDFormUIStepObject : RSDUIStepObject, RSDFormUIStep, RSDSurveyNavigationStep, RSDCohortAssignmentStep {

    private enum CodingKeys: String, CodingKey, CaseIterable {
        case inputFields, identifier
    }

    /// The `inputFields` array is used to hold a logical subgrouping of input fields.
    open private(set) var inputFields: [RSDInputField]
    
    /// Default type is `.form`.
    open override class func defaultType() -> RSDStepType {
        return RSDStepType(rawValue: "form")
    }
    
    /// Initializer required for `copy(with:)` implementation.
    public required init(identifier: String, type: RSDStepType?) {
        self.inputFields = []
        super.init(identifier: identifier, type: type)
    }
    
    /// Override to set the properties of the subclass.
    override open func copyInto(_ copy: RSDUIStepObject) {
        super.copyInto(copy)
        guard let subclassCopy = copy as? RSDFormUIStepObject else {
            assertionFailure("Superclass implementation of the `copy(with:)` protocol should return an instance of this class.")
            return
        }
        subclassCopy.inputFields = self.inputFields
    }

    /// Default initializer.
    /// - parameters:
    ///     - identifier: A short string that uniquely identifies the step.
    ///     - inputFields: The input fields used to create this step.
    ///     - type: The type of the step. Default = `RSDStepType.form`
    public init(identifier: String, inputFields: [RSDInputField], type: RSDStepType? = nil) {
        self.inputFields = inputFields
        super.init(identifier: identifier, type: type)
    }
    
    /// Identifier to skip to if all input fields have nil answers.
    open var skipToIfNil: String? {
        guard let skipAction = self.action(for: .navigation(.skip), on: self) as? RSDNavigationUIAction
            else {
                return nil
        }
        return skipAction.skipToIdentifier
    }
    
    /// Identifier for the next step to navigate to based on the current task result.
    ///
    /// - note: The conditional rule is ignored by this implementation of the navigation rule. Instead,
    /// this will evaluate any survey rules and the direct navigation rule inherited from
    /// `RSDUIStepObject`.
    ///
    /// - parameters:
    ///     - result:           The current task result.
    ///     - conditionalRule:  The conditional rule associated with this task. (Ignored)
    ///     - isPeeking:        Is this navigation rule being called on a result for a step that is
    ///                         navigating forward or is it a step navigator that is peeking at the next
    ///                         step to set up UI display? If peeking at the next step then this
    ///                         parameter will be `true`.
    /// - returns: The identifier of the next step.
    open override func nextStepIdentifier(with result: RSDTaskResult?, isPeeking: Bool) -> String? {
        return self.evaluateSurveyRules(with: result, isPeeking: isPeeking) ??
            super.nextStepIdentifier(with: result, isPeeking: isPeeking)
    }
    
    /// Evaluate the task result and return the set of cohorts to add and remove. Default implementation
    /// calls
    /// `evaluateCohortsToApply(with:)`.
    ///
    /// - parameter result: The task result to evaluate.
    /// - returns: The cohorts to add/remove or `nil` if no rules apply.
    open func cohortsToApply(with result: RSDTaskResult) -> (add: Set<String>, remove: Set<String>)? {
        return self.evaluateCohortsToApply(with: result)
    }
    
    /// Initialize from a `Decoder`. This implementation will query the `RSDFactory` attached to the
    /// decoder for the appropriate implementation for each input field in the array.
    ///
    /// - example:
    ///
    ///     ```
    ///         // Example JSON dictionary that includes a date, integer, and multiple choice question
    ///         // defined in an array of dictionaries keyed to "inputFields".
    ///         let json = """
    ///             {
    ///             "identifier": "step3",
    ///             "type": "form",
    ///             "title": "Step 3",
    ///             "detail": "Some text.",
    ///             "inputFields": [
    ///                             {
    ///                             "identifier": "foo",
    ///                             "type": "date",
    ///                             "uiHint": "picker",
    ///                             "prompt": "Foo",
    ///                             "range" : { "minimumDate" : "2017-02-20",
    ///                                         "maximumDate" : "2017-03-20",
    ///                                         "codingFormat" : "yyyy-MM-dd" }
    ///                             },
    ///                             {
    ///                             "identifier": "bar",
    ///                             "type": "integer",
    ///                             "prompt": "Bar"
    ///                             },
    ///                             {
    ///                             "identifier": "goo",
    ///                             "type": "multipleChoice",
    ///                             "choices" : ["never", "sometimes", "often", "always"]
    ///                             }
    ///                            ]
    ///             }
    ///         """.data(using: .utf8)! // our data in native (JSON) format
    ///     ```
    ///
    /// - parameter decoder: The decoder to use to decode this instance.
    /// - throws: `DecodingError`
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Decode the input fields
        let factory = decoder.factory
        
        let previousIdentifier = decoder.codingInfo?.userInfo[.stepIdentifier]
        if let identifier = try container.decodeIfPresent(String.self, forKey: .identifier) {
            let codingInfo = decoder.codingInfo
            codingInfo?.userInfo[.stepIdentifier] = identifier
        }
        
        var decodedFields : [RSDInputField] = []
        if container.contains(.inputFields) {
            var nestedContainer = try container.nestedUnkeyedContainer(forKey: .inputFields)
            while !nestedContainer.isAtEnd {
                let nestedDecoder = try nestedContainer.superDecoder()
                if let field = try factory.decodeInputField(from: nestedDecoder) {
                    decodedFields.append(field)
                }
            }
        }
        else if let field = try factory.decodeInputField(from: decoder) {
            #if DEBUG
                let context = DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "The `inputFields` keyword is required and inline decoding of a single input field is no longer supported.")
                throw DecodingError.keyNotFound(CodingKeys.inputFields, context)
            #else
                decodedFields.append(field)
            #endif
        }
        self.inputFields = decodedFields
        
        decoder.codingInfo?.userInfo[.stepIdentifier] = previousIdentifier
        
        try super.init(from: decoder)
    }
    
    /// Instantiate a step result that is appropriate for this step. The default for this class is a
    /// `RSDCollectionResultObject`.
    /// - returns: A result for this step.
    open override func instantiateStepResult() -> ResultData {
        return RSDCollectionResultObject(identifier: self.identifier)
    }

    /// Validate the step to check for any configuration that should throw an error. This class will
    /// check that the input fields have unique identifiers and will call the `validate()` method on each
    /// input field.
    ///
    /// - throws: An error if validation fails.
    open override func validate() throws {
        try super.validate()
        
        // Check if the identifiers are unique
        let inputIds = inputFields.map({ $0.identifier })
        let uniqueIds = Set(inputIds)
        if inputIds.count != uniqueIds.count {
            throw RSDValidationError.notUniqueIdentifiers("Input field identifiers: \(inputIds.joined(separator: ","))")
        }
        
        // And validate the fields
        for inputField in inputFields {
            try inputField.validate()
        }
    }
    
    // MARK: Table source
    
    open override func instantiateDataSource(with parent: RSDPathComponent?, for supportedHints: Set<RSDFormUIHint>) -> RSDTableDataSource? {
        RSDFormStepDataSourceObject(step: self, parent: parent, supportedHints: supportedHints)
    }
}

extension RSDFactory {
    
    /// Decode the input field from this decoder. This method can be overridden to return `nil`
    /// if the input field should be skipped.
    ///
    /// - parameter decoder: The decoder to use to instantiate the object.
    /// - returns: The step (if any) created from this decoder.
    /// - throws: `DecodingError` if the object cannot be decoded.
    /// - seealso: `RSDFormUIStepObject`
    func decodeInputField(from decoder: Decoder) throws -> RSDInputField? {
        let dataType = try RSDInputFieldObject.dataType(from: decoder)
        let inputField = try decodeInputField(from: decoder, with: dataType)
        try inputField?.validate()
        return inputField
    }
    
    /// Decode the input field from this decoder. This method can be overridden to return `nil`
    /// if the input field should be skipped.
    ///
    /// - parameters:
    ///     - decoder: The decoder to use to instantiate the object.
    ///     - dataType: The type for this input field.
    /// - returns: The input field (if any) created from this decoder.
    /// - throws: `DecodingError` if the object cannot be decoded.
    func decodeInputField(from decoder:Decoder, with dataType: RSDFormDataType) throws -> RSDInputField? {
        switch dataType {
        case .collection(let collectionType, _):
            switch collectionType {
            case .multipleComponent:
                let codingPath = decoder.codingPath
                let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Input field .multipleComponent is not supported by this factory: \(self).")
                throw DecodingError.typeMismatch(RSDFormDataType.self, context)
                
            case .multipleChoice, .singleChoice:
                switch dataType.baseType {
                case .boolean:
                    return try RSDCodableChoiceInputFieldObject<Bool>(from: decoder)
                case .string:
                    return try RSDCodableChoiceInputFieldObject<String>(from: decoder)
                case .date:
                    return try RSDCodableChoiceInputFieldObject<Date>(from: decoder)
                case .decimal, .duration:
                    return try RSDCodableChoiceInputFieldObject<Double>(from: decoder)
                case .integer, .year:
                    return try RSDCodableChoiceInputFieldObject<Int>(from: decoder)
                default:
                    let codingPath = decoder.codingPath
                    let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Input field choices for a \(dataType.baseType) data type are not supported by this factory: \(self).")
                    throw DecodingError.typeMismatch(Codable.self, context)
                }
            }
            
        case .detail(_):
            let codingPath = decoder.codingPath
            let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Input field .detail data type is not supported by this factory: \(self).")
            throw DecodingError.typeMismatch(RSDFormDataType.self, context)
        
        default:
            return try RSDInputFieldObject(from: decoder)
        }
    }
    
}
