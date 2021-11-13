//
//  CodableTrackedDataTests.swift
//  BridgeAppTests
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

import XCTest
@testable import BridgeApp
@testable import DataTracking
import Research
import JsonModel
import BridgeSDK

let testFactory: RSDFactory = {
    RSDFactory.shared = SBADataTrackingFactory()
    return RSDFactory.shared
}()

var decoder: JSONDecoder {
    return testFactory.createJSONDecoder()
}

var encoder: JSONEncoder {
    return testFactory.createJSONEncoder()
}

class CodableTrackedDataTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    
    func testTrackedSectionObject_Codable() {
        let json = """
        {
            "identifier": "foo",
            "text": "Text",
            "detail" : "Detail"
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        do {
            let object = try decoder.decode(SBATrackedSectionObject.self, from: json)
            
            XCTAssertEqual(object.identifier, "foo")
            XCTAssertEqual(object.text, "Text")
            XCTAssertEqual(object.detail, "Detail")
            
            let jsonData = try encoder.encode(object)
            guard let dictionary = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String : Any]
                else {
                    XCTFail("Encoded object is not a dictionary")
                    return
            }
            
            XCTAssertEqual(dictionary["identifier"] as? String, "foo")
            XCTAssertEqual(dictionary["text"] as? String, "Text")
            XCTAssertEqual(dictionary["detail"] as? String, "Detail")
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testTrackedItem_Codable() {
        let json = """
        {
            "identifier": "advil-ibuprofen",
            "sectionIdentifier": "pain",
            "title": "Advil",
            "shortText": "Adv",
            "detail": "(Ibuprofen)",
            "isExclusive": true,
            "icon": "pill",
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        do {
            let object = try decoder.decode(SBATrackedItemObject.self, from: json)
            
            XCTAssertEqual(object.identifier, "advil-ibuprofen")
            XCTAssertEqual(object.sectionIdentifier, "pain")
            XCTAssertEqual(object.text, "Advil")
            XCTAssertEqual(object.shortText, "Adv")
            XCTAssertEqual(object.detail, "(Ibuprofen)")
            XCTAssertEqual(object.isExclusive, true)
            XCTAssertEqual(object.icon?.imageName, "pill")
            
            let jsonData = try encoder.encode(object)
            guard let dictionary = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String : Any]
                else {
                    XCTFail("Encoded object is not a dictionary")
                    return
            }
            
            XCTAssertEqual(dictionary["identifier"] as? String, "advil-ibuprofen")
            XCTAssertEqual(dictionary["sectionIdentifier"] as? String, "pain")
            XCTAssertEqual(dictionary["title"] as? String, "Advil")
            XCTAssertEqual(dictionary["shortText"] as? String, "Adv")
            XCTAssertEqual(dictionary["detail"] as? String, "(Ibuprofen)")
            XCTAssertEqual(dictionary["icon"] as? String, "pill")
            XCTAssertEqual(dictionary["isExclusive"] as? Bool, true)
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testTrackedItem_Codable_Default() {
        let json = """
        {
            "identifier": "Ibuprofen"
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        do {
            let object = try decoder.decode(SBATrackedItemObject.self, from: json)
            
            XCTAssertEqual(object.identifier, "Ibuprofen")
            XCTAssertEqual(object.text, "Ibuprofen")
            XCTAssertNil(object.sectionIdentifier)
            XCTAssertNil(object.title)
            XCTAssertNil(object.shortText)
            XCTAssertNil(object.detail)
            XCTAssertFalse(object.isExclusive)
            XCTAssertNil(object.icon)
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testMedicationItem_Codable() {
        let json = """
        {
            "identifier": "advil-ibuprofen",
            "sectionIdentifier": "pain",
            "title": "Advil",
            "shortText": "Adv",
            "detail": "(Ibuprofen)",
            "isExclusive": true,
            "icon": "pill",
            "injection": true
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        do {
            let object = try decoder.decode(SBAMedicationItem.self, from: json)
            
            XCTAssertEqual(object.identifier, "advil-ibuprofen")
            XCTAssertEqual(object.sectionIdentifier, "pain")
            XCTAssertEqual(object.text, "Advil")
            XCTAssertEqual(object.shortText, "Adv")
            XCTAssertEqual(object.detail, "(Ibuprofen)")
            XCTAssertEqual(object.isExclusive, true)
            XCTAssertEqual(object.icon?.imageName, "pill")
            XCTAssertEqual(object.isContinuousInjection, true)

            let jsonData = try encoder.encode(object)
            guard let dictionary = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String : Any]
                else {
                    XCTFail("Encoded object is not a dictionary")
                    return
            }
            
            XCTAssertEqual(dictionary["identifier"] as? String, "advil-ibuprofen")
            XCTAssertEqual(dictionary["sectionIdentifier"] as? String, "pain")
            XCTAssertEqual(dictionary["title"] as? String, "Advil")
            XCTAssertEqual(dictionary["shortText"] as? String, "Adv")
            XCTAssertEqual(dictionary["detail"] as? String, "(Ibuprofen)")
            XCTAssertEqual(dictionary["icon"] as? String, "pill")
            XCTAssertEqual(dictionary["isExclusive"] as? Bool, true)
            XCTAssertEqual(dictionary["injection"] as? Bool, true)
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }

    func testMedicationItem_Codable_Default() {
        let json = """
        {
            "identifier": "Ibuprofen"
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        do {
            let object = try decoder.decode(SBAMedicationItem.self, from: json)
            
            XCTAssertEqual(object.identifier, "Ibuprofen")
            XCTAssertEqual(object.text, "Ibuprofen")
            XCTAssertNil(object.sectionIdentifier)
            XCTAssertNil(object.title)
            XCTAssertNil(object.shortText)
            XCTAssertNil(object.detail)
            XCTAssertFalse(object.isExclusive)
            XCTAssertNil(object.icon)
            XCTAssertNil(object.isContinuousInjection)
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testMedicationAnswer_Codable() {
        let json = """
        {
            "identifier": "ibuprofen",
            "dosageItems" : [ {
                                "dosage": "10/100 mg",
                                "daysOfWeek": ["Sunday","Tuesday","Thursday"],
                                "timestamps": [{ "timeOfDay" : "08:00" }]
                              }
                            ]
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        do {
            
            let object = try decoder.decode(SBAMedicationAnswer.self, from: json)
            
            XCTAssertEqual(object.identifier, "ibuprofen")
            if let dosageItem = object.dosageItems?.first {
                XCTAssertEqual(dosageItem.dosage, "10/100 mg")
                XCTAssertEqual(dosageItem.scheduleItems?.count, 1)
                XCTAssertEqual(dosageItem.timestamps?.count, 1)
                XCTAssertEqual(dosageItem.daysOfWeek, [.sunday, .tuesday, .thursday])
                XCTAssertNotNil(dosageItem.isAnytime)
                XCTAssertFalse(dosageItem.isAnytime ?? true)
            }
            else {
                XCTFail("Failed to decode dosage item")
            }
            
            let jsonData = try encoder.encode(object)
            guard let dictionary = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String : Any]
                else {
                    XCTFail("Encoded object is not a dictionary")
                    return
            }
            
            XCTAssertEqual(dictionary["identifier"] as? String, "ibuprofen")
            if let items = dictionary["dosageItems"] as? [[String : Any]] {
                XCTAssertEqual(items.count, 1)
                if let dosageDictionary = items.first {
                    XCTAssertEqual(dosageDictionary["dosage"] as? String, "10/100 mg")
                    if let daysOfWeek = dosageDictionary["daysOfWeek"] as? [String] {
                        XCTAssertEqual(Set(daysOfWeek), ["Sunday","Tuesday","Thursday"])
                    }
                    else {
                        XCTFail("Failed to encode the days of week")
                    }
                }
            } else {
                XCTFail("Failed to encode the dosage items")
            }

        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testMedicationAnswer_Codable_Default() {
        let json = """
        {
            "identifier": "ibuprofen",
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        do {
            let object = try decoder.decode(SBAMedicationAnswer.self, from: json)
            
            XCTAssertEqual(object.identifier, "ibuprofen")
            XCTAssertNil(object.dosageItems)
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testTrackedItemsStepNavigator_Codable() {
        
        let json = """
        {
            "identifier":"Test",
            "type":"tracking",
            "items": [
                        { "identifier": "itemA1", "sectionIdentifier" : "a" },
                        { "identifier": "itemA2", "sectionIdentifier" : "a" },
                        { "identifier": "itemB1", "sectionIdentifier" : "b" },
                        { "identifier": "itemB2", "sectionIdentifier" : "b" },
                        { "identifier": "itemC1", "sectionIdentifier" : "c" }
                    ],
            "sections": [{ "identifier": "a" }, { "identifier": "b" }, { "identifier": "c" }]
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        do {
            let object = try decoder.decode(SBATrackedItemsStepNavigator.self, from: json)
            XCTAssertEqual(object.items.count, 5)
            XCTAssertEqual(object.sections?.count ?? 0, 3)

        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testMedicationTrackingStepNavigator_Codable() {
        
        let json = """
        {
            "identifier":"Test",
            "type":"medicationTracking",
            "items": [
                        { "identifier": "itemA1", "sectionIdentifier" : "a" },
                        { "identifier": "itemA2", "sectionIdentifier" : "a" },
                        { "identifier": "itemB1", "sectionIdentifier" : "b" },
                        { "identifier": "itemB2", "sectionIdentifier" : "b" },
                        { "identifier": "itemC1", "sectionIdentifier" : "c" }
                    ],
            "sections": [{ "identifier": "a" }, { "identifier": "b" }, { "identifier": "c" }],
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        do {
            let object = try decoder.decode(SBAMedicationTrackingStepNavigator.self, from: json)
            XCTAssertEqual(object.items.count, 5)
            XCTAssertEqual(object.sections?.count ?? 0, 3)
            XCTAssertNotNil(object.items as? [SBAMedicationItem])
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testTriggerTrackingStepNavigator_Codable() {
        
        let json = """
            {
                "identifier": "logging",
                "type" : "tracking",
                "items": [
                            { "identifier": "itemA1", "sectionIdentifier" : "a" },
                            { "identifier": "itemA2", "sectionIdentifier" : "a" },
                            { "identifier": "itemA3", "sectionIdentifier" : "a" },
                            { "identifier": "itemB1", "sectionIdentifier" : "b" },
                            { "identifier": "itemB2", "sectionIdentifier" : "b" },
                            { "identifier": "itemC1", "sectionIdentifier" : "c" },
                            { "identifier": "itemC2", "sectionIdentifier" : "c" },
                            { "identifier": "itemC3", "sectionIdentifier" : "c" }
                        ],
                "selection": { "title": "What items would you like to track?",
                                "detail": "Select all that apply",
                                "colorMapping" : {
                                                "type" : "placementMapping",
                                                "placement" : { "header" : "primary",
                                                                "body" : "primary",
                                                                "footer" : "white" }}
                            },
                "logging": { "title": "Your logged items",
                             "actions": { "addMore": { "type": "default", "buttonTitle" : "Edit Logged Items" }}
                            }
            }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        do {
            let object = try decoder.decode(SBATrackedItemsStepNavigator.self, from: json)
            XCTAssertEqual(object.identifier, "logging")
            guard let navigator = object.stepNavigator as? SBATrackedItemsStepNavigator else {
                XCTFail("Failed to decode the step navigator. Exiting.")
                return
            }
            XCTAssertEqual(navigator.items.count, 8)
            XCTAssertNil(navigator.sections)
            XCTAssertEqual((navigator.selectionStep as? RSDUIStep)?.title, "What items would you like to track?")
            XCTAssertEqual((navigator.selectionStep as? RSDUIStep)?.detail, "Select all that apply")
            if let _ = (navigator.selectionStep as? RSDDesignableUIStep)?.colorMapping {
            } else {
                XCTFail("Failed to decode the color Theme")
            }
            
            XCTAssertEqual((navigator.loggingStep as? RSDUIStep)?.title, "Your logged items")
            XCTAssertEqual((navigator.loggingStep as? RSDUIStepObject)?.actions?[.addMore]?.buttonTitle, "Edit Logged Items")
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    
    func testTrackedSelectionStepObject_Codable() {
        
        let json = """
        {
            "identifier": "foo",
            "type": "instruction",
            "title": "Hello World!",
            "text": "Some text.",
            "detail": "This is a test.",
            "footnote": "This is a footnote.",
            "image": { "type": "fetchable",
                       "imageName": "before"},
            "nextStepIdentifier": "boo",
            "actions": { "goForward": { "type": "default", "buttonTitle" : "Go, Dogs! Go!" },
                         "cancel": { "type": "default", "iconName" : "closeX" },
                         "learnMore": { "type": "webView", 
                                        "iconName" : "infoIcon",
                                        "url" : "fooInfo" }
                        },
            "shouldHideActions": ["goBackward", "skip"],
            "items" : [ {"identifier" : "itemA1", "sectionIdentifier" : "a"},
                        {"identifier" : "itemA2", "sectionIdentifier" : "a"},
                        {"identifier" : "itemA3", "sectionIdentifier" : "a"},
                        {"identifier" : "itemB1", "sectionIdentifier" : "b"},
                        {"identifier" : "itemB2", "sectionIdentifier" : "b"},
                        {"identifier" : "itemB3", "sectionIdentifier" : "b"}],
            "sections" : [ {"identifier" : "a"}, {"identifier" : "b"}]
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        do {
            
            let object = try decoder.decode(SBATrackedSelectionStepObject.self, from: json)
            
            XCTAssertEqual(object.identifier, "foo")
            XCTAssertEqual(object.title, "Hello World!")
            XCTAssertEqual(object.subtitle, "Some text.")
            XCTAssertEqual(object.detail, "This is a test.")
            XCTAssertEqual(object.footnote, "This is a footnote.")
            XCTAssertEqual((object.imageTheme as? RSDFetchableImageThemeElementObject)?.imageName, "before")
            XCTAssertEqual(object.nextStepIdentifier, "boo")
            
            let goForwardAction = object.action(for: .navigation(.goForward), on: object)
            XCTAssertNotNil(goForwardAction)
            XCTAssertEqual(goForwardAction?.buttonTitle, "Go, Dogs! Go!")
            
            let cancelAction = object.action(for: .navigation(.cancel), on: object)
            XCTAssertNotNil(cancelAction)
            XCTAssertEqual((cancelAction as? RSDUIActionObject)?.iconName, "closeX")
            
            let learnMoreAction = object.action(for: .navigation(.learnMore), on: object)
            XCTAssertNotNil(learnMoreAction)
            XCTAssertEqual((learnMoreAction as? RSDWebViewUIActionObject)?.iconName, "infoIcon")
            XCTAssertEqual((learnMoreAction as? RSDWebViewUIActionObject)?.url, "fooInfo")
            
            XCTAssertTrue(object.shouldHideAction(for: .navigation(.goBackward), on: object) ?? false)
            
            XCTAssertEqual(object.items.count, 6)
            XCTAssertEqual(object.sections?.count ?? 0, 2)
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testTrackedLoggingResultObject_Encodable() {
        
        var result = SBATrackedLoggingResultObject(identifier: "foo")
        result.itemIdentifier = "bah"
        result.timingIdentifier = "09:00"
        result.text = "Text string"
        result.detail = "Detail string"
        result.loggedDate = Date()
        let values = [("a", 1), ("b", 2), ("c", 3)]
        result.children = values.map { (value) -> RSDAnswerResult in
            let answer = RSDAnswerResultObject(identifier: value.0, answerType: .integer)
            answer.value = value.1
            return answer
        }
        
        do {
            
            let object = result
            let jsonData = try encoder.encode(object)
            guard let dictionary = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String : Any]
                else {
                    XCTFail("Encoded object is not a dictionary")
                    return
            }
            
            XCTAssertEqual(dictionary["identifier"] as? String, "foo")
            XCTAssertEqual(dictionary["itemIdentifier"] as? String, "bah")
            XCTAssertEqual(dictionary["timingIdentifier"] as? String, "09:00")
            XCTAssertEqual(dictionary["text"] as? String, "Text string")
            XCTAssertEqual(dictionary["detail"] as? String, "Detail string")
            XCTAssertNotNil(dictionary["loggedDate"] as? String)
            XCTAssertEqual(dictionary["a"] as? Int, 1)
            XCTAssertEqual(dictionary["b"] as? Int, 2)
            XCTAssertEqual(dictionary["c"] as? Int, 3)
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testTriggersJSON() {
        let resourceTransformer = RSDResourceTransformerObject(resourceName: "Triggers", bundle: Bundle.module)
        do {
            let task = try testFactory.decodeTask(with: resourceTransformer)
            guard let navigator = task.stepNavigator as? SBATrackedItemsStepNavigator else {
                XCTFail("Failed to decode expected navigator.")
                return
            }
            
            let selectionStep = navigator.selectionStep
            XCTAssertEqual((selectionStep as? RSDUIStep)?.title, "What triggers would you like to track?")
            XCTAssertEqual((selectionStep as? RSDUIStep)?.detail, "Select all that apply")
            
            let loggingStep = navigator.loggingStep as? SBATrackedItemsLoggingStepObject
            XCTAssertNotNil(navigator.loggingStep)
            XCTAssertNotNil(loggingStep)
            XCTAssertEqual(loggingStep?.title, "Your triggers")
            XCTAssertEqual(loggingStep?.actions?[.addMore]?.buttonTitle, "Edit triggers")

        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testSymptomsJSON() {
        let resourceTransformer = RSDResourceTransformerObject(resourceName: "Symptoms", bundle: Bundle.module)
        do {
            let task = try testFactory.decodeTask(with: resourceTransformer)
            guard let navigator = task.stepNavigator as? SBATrackedItemsStepNavigator else {
                XCTFail("Failed to decode expected navigator.")
                return
            }
            
            let selectionStep = navigator.selectionStep
            XCTAssertEqual((selectionStep as? RSDUIStep)?.title, "What are your Parkinson’s Disease symptoms?")
            XCTAssertEqual((selectionStep as? RSDUIStep)?.detail, "Select all that apply")
            
            let loggingStep = navigator.loggingStep as? SBASymptomLoggingStepObject
            XCTAssertNotNil(navigator.loggingStep)
            XCTAssertNotNil(loggingStep)
            XCTAssertEqual(loggingStep?.title, "Today’s symptoms")
            XCTAssertEqual(loggingStep?.actions?[.addMore]?.buttonTitle, "Edit symptoms")
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testMedAnswersV1Decoding() {
        let json = """
        {
            "items": [{
                    "identifier": "medA3",
                    "dosage": "10 mg",
                    "scheduleItems": [{
                            "timeOfDay": "12:00",
                            "daysOfWeek": [2, 5, 3, 7, 6, 4, 1]
                        },
                        {
                            "timeOfDay": "20:00",
                            "daysOfWeek": [3, 1, 6, 4, 2, 5, 7]
                        },
                        {
                            "timeOfDay": "08:00",
                            "daysOfWeek": [2, 6, 5, 4, 1, 7, 3]
                        }
                    ],
                    "timestamps": [{
                            "loggedDate": "2019-06-04T08:00:00.000-06:00",
                            "timeOfDay": "08:00"
                        },
                        {
                            "loggedDate": "2019-06-04T12:15:00.000-06:00",
                            "timeOfDay": "12:00"
                        },
                        {
                            "loggedDate": "2019-06-04T20:45:00.000-06:00",
                            "timeOfDay": "20:00"
                        }
                    ]
                },
                {
                    "identifier": "medA4",
                    "dosage": "40 mg",
                    "scheduleItems": [{
                            "timeOfDay": "10:30",
                            "daysOfWeek": [2, 4, 6]
                        },
                        {
                            "timeOfDay": "07:30",
                            "daysOfWeek": [2, 6, 4]
                        }
                    ],
                    "timestamps": [{
                            "loggedDate": "2019-06-04T07:45:00.000-06:00",
                            "timeOfDay": "07:30"
                        },
                        {
                            "loggedDate": "2019-06-04T10:30:00.000-06:00",
                            "timeOfDay": "10:30"
                        }
                    ]
                },
                {
                    "identifier": "medA5",
                    "dosage": "5 ml",
                    "scheduleItems": [{
                        "daysOfWeek": [6, 1, 5, 4, 3, 7, 2]
                    }],
                    "timestamps": [{
                            "loggedDate": "2019-06-04T08:00:00.000-06:00",
                            "timeOfDay": "morning"
                        },
                        {
                            "loggedDate": "2019-06-04T12:15:00.000-06:00",
                            "timeOfDay": "afternoon"
                        },
                        {
                            "loggedDate": "2019-06-04T20:45:00.000-06:00",
                            "timeOfDay": "evening"
                        }
                    ]
                },
                {
                    "identifier": "medC3",
                    "dosage": "2 ml",
                    "scheduleItems": [{
                            "timeOfDay": "08:00",
                            "daysOfWeek": [1, 5]
                        },
                        {
                            "timeOfDay": "20:00",
                            "daysOfWeek": [1, 5]
                        }
                    ]
                }
            ],
            "reminders": [
                0
            ],
            "startDate": "2019-06-04T18:12:05.233-06:00",
            "type": "medication",
            "identifier": "review",
            "endDate": "2019-06-04T18:12:05.233-06:00"
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        do {
            let trackingResult = try decoder.decode(SBAMedicationTrackingResult.self, from: json)
            
            XCTAssertNotNil(trackingResult.reminders)
            XCTAssertEqual(trackingResult.reminders?.first, 0)
            XCTAssertEqual(trackingResult.reminders?.count, 1)
            
            let items = trackingResult.medications
            XCTAssertEqual(items.map { $0.identifier }, ["medA3", "medA4", "medA5", "medC3"])

            if let med = trackingResult.medications.first(where: { $0.identifier == "medA3" }) {
                XCTAssertEqual(med.dosageItems?.count, 1)
                if let dosageItem = med.dosageItems?.first {
                    XCTAssertEqual(dosageItem.dosage, "10 mg")
                    XCTAssertNotNil(dosageItem.isAnytime)
                    XCTAssertFalse(dosageItem.isAnytime ?? true)
                    XCTAssertEqual(dosageItem.daysOfWeek, RSDWeekday.all)
                    XCTAssertEqual(dosageItem.timestamps?.count, 3)
                    if let timestamp = dosageItem.timestamps?.first {
                        XCTAssertEqual(timestamp.timeOfDay, "08:00")
                        XCTAssertNotNil(timestamp.loggedDate)
                        XCTAssertEqual(timestamp.timeZone.identifier, "GMT-0600")
                    }
                }
            }
            else {
                XCTFail("Failed to decode medA3")
            }
            
            if let med = trackingResult.medications.first(where: { $0.identifier == "medA5" }) {
                XCTAssertEqual(med.dosageItems?.count, 1)
                if let dosageItem = med.dosageItems?.first {
                    XCTAssertEqual(dosageItem.dosage, "5 ml")
                    XCTAssertNotNil(dosageItem.isAnytime)
                    XCTAssertTrue(dosageItem.isAnytime ?? false)
                    XCTAssertNil(dosageItem.daysOfWeek)
                    XCTAssertEqual(dosageItem.timestamps?.count, 3)
                    if let timestamp = dosageItem.timestamps?.first {
                        XCTAssertNil(timestamp.timeOfDay)
                        XCTAssertNotNil(timestamp.loggedDate)
                        XCTAssertEqual(timestamp.timeZone.identifier, "GMT-0600")
                    }
                }
            }
            else {
                XCTFail("Failed to decode medA3")
            }
        }
        catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testMedAnswersV2Decoding() {
        let json = """
        {
            "revision": 2,
            "identifier": "review",
            "type": "medication",
            "startDate": "2019-06-04T20:42:05.233-06:00",
            "endDate": "2019-06-04T20:47:05.233-06:00",
            "reminders": [0],
            "items": [{
                    "identifier": "medA3",
                    "dosageItems": [{
                        "dosage": "10 mg",
                        "daysOfWeek": [1, 2, 3, 4, 5, 6, 7],
                        "timestamps": [{
                                "timeOfDay": "08:00",
                                "loggedDate": "2019-06-04T08:00:00.000-06:00",
                                "timeZone":"America/Denver"
                            },
                            {
                                "timeOfDay": "12:00",
                                "loggedDate": "2019-06-04T12:15:00.000-06:00",
                                "timeZone":"America/Denver"
                            },
                            {
                                "timeOfDay": "20:00"
                            }
                        ]
                    }]
                },
                {
                    "identifier": "medA4",
                    "dosageItems": [{
                        "dosage": "40 mg",
                        "daysOfWeek": [2, 4, 6],
                        "timestamps": [{
                                "timeOfDay": "07:30",
                                "loggedDate": "2019-06-04T07:45:00.000-06:00",
                                "timeZone":"America/Denver"
                            },
                            {
                                "timeOfDay": "10:30",
                                "loggedDate": "2019-06-04T10:30:00.000-06:00",
                                "timeZone":"America/Denver"
                            }
                        ]
                    }]
                },
                {
                    "identifier": "medA5",
                    "dosageItems": [{
                        "dosage": "5 ml",
                        "timestamps": [{
                                "quantity": 3,
                                "loggedDate": "2019-06-04T08:00:00.000-06:00",
                                "timeZone":"America/Denver"
                            },
                            {
                                "loggedDate": "2019-06-04T12:15:00.000-06:00",
                                "timeZone":"America/Denver"
                            },
                            {
                                "loggedDate": "2019-06-04T20:45:00.000-06:00",
                                "timeZone":"America/Denver"
                            }
                        ]
                    }]
                },
                {
                    "identifier": "medC3",
                    "dosageItems": [{
                            "dosage": "2 ml",
                            "daysOfWeek": [1, 5],
                            "timestamps": [{
                                    "timeOfDay": "08:00"
                                },
                                {
                                    "timeOfDay": "20:00"
                                }
                            ]
                        },
                        {
                            "dosage": "1 ml"
                        }
                    ]
                }
            ]
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        do {
            let trackingResult = try decoder.decode(SBAMedicationTrackingResult.self, from: json)
            
            XCTAssertNotNil(trackingResult.reminders)
            XCTAssertEqual(trackingResult.reminders?.first, 0)
            XCTAssertEqual(trackingResult.reminders?.count, 1)
            
            let items = trackingResult.medications
            XCTAssertEqual(items.map { $0.identifier }, ["medA3", "medA4", "medA5", "medC3"])
            
            if let med = trackingResult.medications.first(where: { $0.identifier == "medA3" }) {
                XCTAssertEqual(med.dosageItems?.count, 1)
                if let dosageItem = med.dosageItems?.first {
                    XCTAssertEqual(dosageItem.dosage, "10 mg")
                    XCTAssertNotNil(dosageItem.isAnytime)
                    XCTAssertFalse(dosageItem.isAnytime ?? true)
                    XCTAssertEqual(dosageItem.daysOfWeek, RSDWeekday.all)
                    XCTAssertEqual(dosageItem.timestamps?.count, 3)
                    if let timestamp = dosageItem.timestamps?.first {
                        XCTAssertEqual(timestamp.timeOfDay, "08:00")
                        XCTAssertNotNil(timestamp.loggedDate)
                        XCTAssertEqual(timestamp.timeZone.identifier, "America/Denver")
                    }
                }
            }
            else {
                XCTFail("Failed to decode medA3")
            }
            
            if let med = trackingResult.medications.first(where: { $0.identifier == "medA4" }) {
                XCTAssertEqual(med.dosageItems?.count, 1)
                if let dosageItem = med.dosageItems?.first {
                    if let timestamp = dosageItem.timestamps?.first {
                        XCTAssertEqual(timestamp.timeZone.identifier, "America/Denver")
                    }
                }
            }
            else {
                XCTFail("Failed to decode medA3")
            }
            
            if let med = trackingResult.medications.first(where: { $0.identifier == "medA5" }) {
                XCTAssertEqual(med.dosageItems?.count, 1)
                if let dosageItem = med.dosageItems?.first {
                    XCTAssertEqual(dosageItem.dosage, "5 ml")
                    XCTAssertNotNil(dosageItem.isAnytime)
                    XCTAssertTrue(dosageItem.isAnytime ?? false)
                    XCTAssertNil(dosageItem.daysOfWeek)
                    XCTAssertEqual(dosageItem.timestamps?.count, 3)
                    if let timestamp = dosageItem.timestamps?.first {
                        XCTAssertNil(timestamp.timeOfDay)
                        XCTAssertNotNil(timestamp.loggedDate)
                        XCTAssertEqual(timestamp.timeZone.identifier, "America/Denver")
                    }
                }
            }
            else {
                XCTFail("Failed to decode medA3")
            }
        }
        catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testMedAnswersV1_UpdateSelection_FromPreviousDay() {
        let json = """
        {
            "items": [{
                    "identifier": "medA3",
                    "dosage": "10 mg",
                    "scheduleItems": [{
                            "timeOfDay": "12:00",
                            "daysOfWeek": [2, 5, 3, 7, 6, 4, 1]
                        },
                        {
                            "timeOfDay": "20:00",
                            "daysOfWeek": [3, 1, 6, 4, 2, 5, 7]
                        },
                        {
                            "timeOfDay": "08:00",
                            "daysOfWeek": [2, 6, 5, 4, 1, 7, 3]
                        }
                    ],
                    "timestamps": [{
                            "loggedDate": "2019-06-04T08:00:00.000-08:00",
                            "timeOfDay": "08:00"
                        },
                        {
                            "loggedDate": "2019-06-04T12:15:00.000-08:00",
                            "timeOfDay": "12:00"
                        },
                        {
                            "loggedDate": "2019-06-04T20:45:00.000-08:00",
                            "timeOfDay": "20:00"
                        }
                    ]
                },
                {
                    "identifier": "medA4",
                    "dosage": "40 mg",
                    "scheduleItems": [{
                            "timeOfDay": "10:30",
                            "daysOfWeek": [2, 4, 6]
                        },
                        {
                            "timeOfDay": "07:30",
                            "daysOfWeek": [2, 6, 4]
                        }
                    ],
                    "timestamps": [{
                            "loggedDate": "2019-06-04T07:45:00.000-08:00",
                            "timeOfDay": "07:30"
                        },
                        {
                            "loggedDate": "2019-06-04T10:30:00.000-08:00",
                            "timeOfDay": "10:30"
                        }
                    ]
                },
                {
                    "identifier": "medA5",
                    "dosage": "5 ml",
                    "scheduleItems": [{
                        "daysOfWeek": [6, 1, 5, 4, 3, 7, 2]
                    }],
                    "timestamps": [{
                            "loggedDate": "2019-06-04T08:00:00.000-08:00",
                            "timeOfDay": "morning"
                        },
                        {
                            "loggedDate": "2019-06-04T12:15:00.000-08:00",
                            "timeOfDay": "afternoon"
                        },
                        {
                            "loggedDate": "2019-06-04T20:45:00.000-08:00",
                            "timeOfDay": "evening"
                        }
                    ]
                },
                {
                    "identifier": "medC3",
                    "dosage": "2 ml",
                    "scheduleItems": [{
                            "timeOfDay": "08:00",
                            "daysOfWeek": [1, 5]
                        },
                        {
                            "timeOfDay": "20:00",
                            "daysOfWeek": [1, 5]
                        }
                    ]
                }
            ],
            "reminders": [
                0
            ],
            "startDate": "2019-06-04T18:12:05.233-07:00",
            "type": "medication",
            "identifier": "review",
            "endDate": "2019-06-04T18:12:05.233-07:00"
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        do {
            let clientData = try JSONSerialization.jsonObject(with: json, options: []) as! SBBJSONValue
            var trackingResult = SBAMedicationTrackingResult(identifier: "foo")
            try trackingResult.updateSelected(from: clientData, with: [])
            
            XCTAssertNotNil(trackingResult.reminders)
            XCTAssertEqual(trackingResult.reminders?.first, 0)
            XCTAssertEqual(trackingResult.reminders?.count, 1)
            
            let items = trackingResult.medications
            XCTAssertEqual(items.map { $0.identifier }, ["medA3", "medA4", "medA5", "medC3"])
            
            if let med = trackingResult.medications.first(where: { $0.identifier == "medA3" }) {
                XCTAssertEqual(med.dosageItems?.count, 1)
                if let dosageItem = med.dosageItems?.first {
                    XCTAssertEqual(dosageItem.dosage, "10 mg")
                    XCTAssertNotNil(dosageItem.isAnytime)
                    XCTAssertFalse(dosageItem.isAnytime ?? true)
                    XCTAssertEqual(dosageItem.daysOfWeek, RSDWeekday.all)
                    XCTAssertEqual(dosageItem.timestamps?.count, 3)
                    if let timestamp = dosageItem.timestamps?.first {
                        XCTAssertEqual(timestamp.timeOfDay, "08:00")
                        XCTAssertNil(timestamp.loggedDate)
                    }
                }
            }
            else {
                XCTFail("Failed to decode medA3")
            }
            
            if let med = trackingResult.medications.first(where: { $0.identifier == "medA5" }) {
                XCTAssertEqual(med.dosageItems?.count, 1)
                if let dosageItem = med.dosageItems?.first {
                    XCTAssertEqual(dosageItem.dosage, "5 ml")
                    XCTAssertNotNil(dosageItem.isAnytime)
                    XCTAssertTrue(dosageItem.isAnytime ?? false)
                    XCTAssertNil(dosageItem.daysOfWeek)
                    XCTAssertEqual(dosageItem.timestamps?.count ?? 0, 0)
                }
            }
            else {
                XCTFail("Failed to decode medA3")
            }
        }
        catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testMedAnswersV2_UpdateSelection_FromPreviousDay() {
        let json = """
        {
            "revision": 2,
            "identifier": "review",
            "type": "medication",
            "startDate": "2019-06-04T18:12:05.233-06:00",
            "endDate": "2019-06-04T18:12:05.233-06:00",
            "reminders": [0],
            "items": [{
                    "identifier": "medA3",
                    "dosageItems": [{
                        "dosage": "10 mg",
                        "daysOfWeek": [1, 2, 3, 4, 5, 6, 7],
                        "timestamps": [{
                                "timeOfDay": "08:00",
                                "loggedDate": "2019-06-04T08:00:00.000-06:00",
                                "timeZone":"America/Denver"
                            },
                            {
                                "timeOfDay": "12:00",
                                "loggedDate": "2019-06-04T12:15:00.000-06:00",
                                "timeZone":"America/Denver"
                            },
                            {
                                "timeOfDay": "20:00"
                            }
                        ]
                    }]
                },
                {
                    "identifier": "medA4",
                    "dosageItems": [{
                        "dosage": "40 mg",
                        "daysOfWeek": [2, 4, 6],
                        "timestamps": [{
                                "timeOfDay": "07:30",
                                "loggedDate": "2019-06-04T07:45:00.000-06:00",
                                "timeZone":"America/Denver"
                            },
                            {
                                "timeOfDay": "10:30",
                                "loggedDate": "2019-06-04T10:30:00.000-06:00",
                                "timeZone":"America/Denver"
                            }
                        ]
                    }]
                },
                {
                    "identifier": "medA5",
                    "dosageItems": [{
                        "dosage": "5 ml",
                        "timestamps": [{
                                "quantity": 3,
                                "loggedDate": "2019-06-04T08:00:00.000-06:00"
                            },
                            {
                                "loggedDate": "2019-06-04T12:15:00.000-06:00"
                            },
                            {
                                "loggedDate": "2019-06-04T20:45:00.000-06:00"
                            }
                        ]
                    }]
                },
                {
                    "identifier": "medC3",
                    "dosageItems": [
                        {
                            "dosage": "1 ml"
                        }
                    ]
                }
            ]
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        do {
            let clientData = try JSONSerialization.jsonObject(with: json, options: []) as! SBBJSONValue
            var trackingResult = SBAMedicationTrackingResult(identifier: "foo")
            try trackingResult.updateSelected(from: clientData, with: [])
            
            XCTAssertNotNil(trackingResult.reminders)
            XCTAssertEqual(trackingResult.reminders?.first, 0)
            XCTAssertEqual(trackingResult.reminders?.count, 1)
            
            let items = trackingResult.medications
            XCTAssertEqual(items.map { $0.identifier }, ["medA3", "medA4", "medA5", "medC3"])
            
            if let med = trackingResult.medications.first(where: { $0.identifier == "medA3" }) {
                XCTAssertEqual(med.dosageItems?.count, 1)
                if let dosageItem = med.dosageItems?.first {
                    XCTAssertEqual(dosageItem.dosage, "10 mg")
                    XCTAssertNotNil(dosageItem.isAnytime)
                    XCTAssertFalse(dosageItem.isAnytime ?? true)
                    XCTAssertEqual(dosageItem.daysOfWeek, RSDWeekday.all)
                    XCTAssertEqual(dosageItem.timestamps?.count, 3)
                    if let timestamp = dosageItem.timestamps?.first {
                        XCTAssertEqual(timestamp.timeOfDay, "08:00")
                        XCTAssertNil(timestamp.loggedDate)
                        XCTAssertEqual(timestamp.timeZone, TimeZone.current)
                    }
                }
            }
            else {
                XCTFail("Failed to decode medA3")
            }
            
            if let med = trackingResult.medications.first(where: { $0.identifier == "medA4" }) {
                XCTAssertEqual(med.dosageItems?.count, 1)
                if let dosageItem = med.dosageItems?.first {
                    if let timestamp = dosageItem.timestamps?.first {
                        XCTAssertEqual(timestamp.timeZone, TimeZone.current)
                    }
                }
            }
            else {
                XCTFail("Failed to decode medA3")
            }
            
            if let med = trackingResult.medications.first(where: { $0.identifier == "medA5" }) {
                XCTAssertEqual(med.dosageItems?.count, 1)
                if let dosageItem = med.dosageItems?.first {
                    XCTAssertEqual(dosageItem.dosage, "5 ml")
                    XCTAssertNotNil(dosageItem.isAnytime)
                    XCTAssertTrue(dosageItem.isAnytime ?? false)
                    XCTAssertNil(dosageItem.daysOfWeek)
                    XCTAssertEqual(dosageItem.timestamps?.count ?? 0, 0)
                }
            }
            else {
                XCTFail("Failed to decode medA5")
            }
            
            if let med = trackingResult.medications.first(where: { $0.identifier == "medC3" }) {
                XCTAssertEqual(med.dosageItems?.count, 1)
                if let dosageItem = med.dosageItems?.first {
                    XCTAssertEqual(dosageItem.dosage, "1 ml")
                    XCTAssertNotNil(dosageItem.isAnytime)
                    XCTAssertTrue(dosageItem.isAnytime ?? false)
                    XCTAssertNil(dosageItem.daysOfWeek)
                    XCTAssertNil(dosageItem.timestamps)
                }
            }
            else {
                XCTFail("Failed to decode medC3")
            }
        }
        catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testMedAnswersV2_UpdateSelection_FromCurrentDay() {
        let json = """
        {
            "revision": 2,
            "identifier": "review",
            "type": "medication",
            "startDate": "2019-06-04T12:30:05.233-06:00",
            "endDate": "2019-06-04T12:32:05.233-06:00",
            "reminders": [0],
            "items": [{
                    "identifier": "medA3",
                    "dosageItems": [{
                        "dosage": "10 mg",
                        "daysOfWeek": [1, 2, 3, 4, 5, 6, 7],
                        "timestamps": [{
                                "timeOfDay": "08:00",
                                "loggedDate": "2019-06-04T08:00:00.000-04:00",
                                "timeZone":"America/New_York"
                            },
                            {
                                "timeOfDay": "12:00",
                                "loggedDate": "2019-06-04T12:15:00.000-06:00",
                                "timeZone":"America/Denver"
                            },
                            {
                                "timeOfDay": "20:00"
                            }
                        ]
                    }]
                },
                {
                    "identifier": "medA4",
                    "dosageItems": [{
                        "dosage": "40 mg",
                        "daysOfWeek": [2, 4, 6],
                        "timestamps": [{
                                "timeOfDay": "07:30",
                                "loggedDate": "2019-06-04T07:45:00.000-04:00",
                                "timeZone":"America/New_York"
                            },
                            {
                                "timeOfDay": "10:30",
                                "loggedDate": "2019-06-04T10:30:00.000-04:00",
                                "timeZone":"America/New_York"
                            }
                        ]
                    }]
                },
                {
                    "identifier": "medA5",
                    "dosageItems": [{
                        "dosage": "5 ml",
                        "timestamps": [{
                                "quantity": 3,
                                "loggedDate": "2019-06-04T08:00:00.000-04:00",
                                "timeZone":"America/New_York"
                            },
                            {
                                "loggedDate": "2019-06-04T12:15:00.000-06:00",
                                "timeZone":"America/Denver"
                            }
                        ]
                    }]
                },
                {
                    "identifier": "medC3",
                    "dosageItems": [
                        {
                            "dosage": "1 ml"
                        }
                    ]
                }
            ]
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        do {
            let currentTimeZone = TimeZone(identifier: "America/Denver")!
            let clientData = try JSONSerialization.jsonObject(with: json, options: []) as! SBBJSONValue
            var trackingResult = SBAMedicationTrackingResult(identifier: "foo", timeZone: currentTimeZone)
            
            var calendar = Calendar.iso8601
            calendar.timeZone = currentTimeZone
            var dateComponents = DateComponents()
            dateComponents.year = 2019
            dateComponents.month = 6
            dateComponents.day = 4
            dateComponents.hour = 20
            dateComponents.minute = 15
            trackingResult.startDate = calendar.date(from: dateComponents)!
            trackingResult.endDate = trackingResult.startDate
            
            try trackingResult.updateSelected(from: clientData, with: [])
            
            XCTAssertNotNil(trackingResult.reminders)
            XCTAssertEqual(trackingResult.reminders?.first, 0)
            XCTAssertEqual(trackingResult.reminders?.count, 1)
            
            let items = trackingResult.medications
            XCTAssertEqual(items.map { $0.identifier }, ["medA3", "medA4", "medA5", "medC3"])
            
            if let med = trackingResult.medications.first(where: { $0.identifier == "medA3" }) {
                XCTAssertEqual(med.dosageItems?.count, 1)
                if let dosageItem = med.dosageItems?.first {
                    XCTAssertEqual(dosageItem.dosage, "10 mg")
                    XCTAssertNotNil(dosageItem.isAnytime)
                    XCTAssertFalse(dosageItem.isAnytime ?? true)
                    XCTAssertEqual(dosageItem.daysOfWeek, RSDWeekday.all)
                    XCTAssertEqual(dosageItem.timestamps?.count, 3)
                    if let timestamps = dosageItem.timestamps, timestamps.count == 3 {
                        let timestamp1 = timestamps[0]
                        XCTAssertEqual(timestamp1.timeOfDay, "08:00")
                        XCTAssertNotNil(timestamp1.loggedDate)
                        XCTAssertEqual(timestamp1.timeZone.identifier, "America/New_York")
                        let timestamp2 = timestamps[1]
                        XCTAssertEqual(timestamp2.timeOfDay, "12:00")
                        XCTAssertNotNil(timestamp2.loggedDate)
                        XCTAssertEqual(timestamp2.timeZone.identifier, "America/Denver")
                    }
                }
            }
            else {
                XCTFail("Failed to decode medA3")
            }
            
            if let med = trackingResult.medications.first(where: { $0.identifier == "medA4" }) {
                XCTAssertEqual(med.dosageItems?.count, 1)
                if let dosageItem = med.dosageItems?.first {
                    if let timestamp = dosageItem.timestamps?.first {
                        XCTAssertEqual(timestamp.timeZone.identifier, "America/New_York")
                    }
                }
            }
            else {
                XCTFail("Failed to decode medA3")
            }
            
            if let med = trackingResult.medications.first(where: { $0.identifier == "medA5" }) {
                XCTAssertEqual(med.dosageItems?.count, 1)
                if let dosageItem = med.dosageItems?.first {
                    XCTAssertEqual(dosageItem.dosage, "5 ml")
                    XCTAssertNotNil(dosageItem.isAnytime)
                    XCTAssertTrue(dosageItem.isAnytime ?? false)
                    XCTAssertNil(dosageItem.daysOfWeek)
                    XCTAssertEqual(dosageItem.timestamps?.count, 2)
                    if let timestamp = dosageItem.timestamps?.first {
                        XCTAssertNil(timestamp.timeOfDay)
                        XCTAssertNotNil(timestamp.loggedDate)
                        XCTAssertEqual(timestamp.timeZone.identifier, "America/New_York")
                    }
                }
            }
            else {
                XCTFail("Failed to decode medA3")
            }
            
            if let med = trackingResult.medications.first(where: { $0.identifier == "medC3" }) {
                XCTAssertEqual(med.dosageItems?.count, 1)
                if let dosageItem = med.dosageItems?.first {
                    XCTAssertEqual(dosageItem.dosage, "1 ml")
                    XCTAssertNotNil(dosageItem.isAnytime)
                    XCTAssertTrue(dosageItem.isAnytime ?? false)
                    XCTAssertNil(dosageItem.daysOfWeek)
                    XCTAssertNil(dosageItem.timestamps)
                }
            }
            else {
                XCTFail("Failed to decode medC3")
            }
        }
        catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testSymptomDecodingV2() {
        let json = """
        {
          "logging" : {
            "Hallucinations" : {
              "severity" : 2,
              "duration" : "DURATION_CHOICE_NOW",
              "medicationTiming" : "pre-medication"
            },
            "Anger" : 3
          },
          "trackedItems" : {
            "startDate" : "2019-07-29T14:15:43.776-06:00",
            "endDate" : "2019-07-29T14:15:43.776-06:00",
            "type" : "loggingCollection",
            "identifier" : "trackedItems",
            "items" : [
              {
                "text" : "Amnesia",
                "identifier" : "Amnesia"
              },
              {
                "loggedDate" : "2019-07-29T14:16:24.561-06:00",
                "severity" : 3,
                "text" : "Anger",
                "identifier" : "Anger"
              },
              {
                "loggedDate" : "2019-07-29T14:16:14.711-06:00",
                "identifier" : "Hallucinations",
                "duration" : "DURATION_CHOICE_NOW",
                "text" : "Hallucinations",
                "medicationTiming" : "pre-medication",
                "severity" : 2
              }
            ]
          }
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        do {
            let object = try decoder.decode(SBASymptomReportData.self, from: json)

            let results = object.trackedItems.symptomResults
            XCTAssertEqual(results.count, 3)
            
            if let first = results.first {
                XCTAssertEqual(first.identifier, "Amnesia")
                XCTAssertNil(first.loggedDate)
            }
            
            if results.count >= 2 {
                let second = results[1]
                XCTAssertEqual(second.identifier, "Anger")
                XCTAssertNotNil(second.loggedDate)
                XCTAssertEqual(second.timeZone.secondsFromGMT(), -6 * 3600)
                XCTAssertEqual(second.severity, .severe)
            }
            
            if let third = results.last {
                XCTAssertEqual(third.identifier, "Hallucinations")
                XCTAssertNotNil(third.loggedDate)
                XCTAssertEqual(third.timeZone.secondsFromGMT(), -6 * 3600)
                XCTAssertEqual(third.severity, .moderate)
                XCTAssertEqual(third.duration, .now)
                XCTAssertEqual(third.medicationTiming, .preMedication)
            }
            
            let jsonData = try encoder.encode(object.trackedItems)
            let jsonResult = try JSONSerialization.jsonObject(with: jsonData, options: [])
            guard let dictionary = jsonResult as? [String : Any],
                let items = dictionary["items"] as? NSArray else {
                    XCTFail("Failed to encode object. \(json)")
                    return
            }
            
            let expectedItems: NSArray = [
                [
                    "text" : "Amnesia",
                    "identifier" : "Amnesia",
                    "type" : "symptom"
                ],
                [
                    "loggedDate" : "2019-07-29T14:16:24.561-06:00",
                    "timeZone" : "GMT-0600",
                    "severity" : 3,
                    "text" : "Anger",
                    "identifier" : "Anger",
                    "type" : "symptom"
                ],
                [
                    "loggedDate" : "2019-07-29T14:16:14.711-06:00",
                    "timeZone" : "GMT-0600",
                    "identifier" : "Hallucinations",
                    "duration" : "DURATION_CHOICE_NOW",
                    "text" : "Hallucinations",
                    "medicationTiming" : "pre-medication",
                    "severity" : 2,
                    "type" : "symptom"
                ]
            ]
            
            XCTAssertEqual(items, expectedItems)
            
            // Check that the symptoms can be re-populated from the report json
            let reportClientData = try JSONSerialization.jsonObject(with: json, options: []) as! NSDictionary
            var result = SBATrackedLoggingCollectionResultObject(identifier: "logging")
            try result.updateSelected(from: reportClientData, with: [])
            
            XCTAssertEqual(result.loggingItems.count, 3)
            
            if let first = result.loggingItems.first {
                XCTAssertEqual(first.identifier, "Amnesia")
                XCTAssertEqual(first.text, "Amnesia")
                XCTAssertNil(first.loggedDate)
                XCTAssertEqual(first.timeZone, TimeZone.current)
                XCTAssertEqual(first.children.count, 0)
            }
            
            if result.loggingItems.count >= 2 {
                let second = result.loggingItems[1]
                XCTAssertEqual(second.identifier, "Anger")
                XCTAssertEqual(second.text, "Anger")
                XCTAssertNil(second.loggedDate)
                XCTAssertEqual(second.timeZone, TimeZone.current)
                XCTAssertEqual(second.children.count, 0)
            }
            
            if let third = result.loggingItems.last {
                XCTAssertEqual(third.identifier, "Hallucinations")
                XCTAssertEqual(third.text, "Hallucinations")
                XCTAssertNil(third.loggedDate)
                XCTAssertEqual(third.timeZone, TimeZone.current)
                XCTAssertEqual(third.children.count, 0)
            }
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testSymptomEncoding() {
        do {
            var trackedItems = SBATrackedLoggingCollectionResultObject(identifier: "trackedItems")
            let item1 = SBATrackedLoggingResultObject(identifier: "Amnesia", text: "Amnesia")
            let item2 = SBATrackedLoggingResultObject(identifier: "Anger",
                                                      text: "Anger",
                                                      detail: nil,
                                                      loggedDate: NSDate(iso8601String: "2019-07-29T14:16:24.561-06:00") as Date,
                                                      timeZone: TimeZone(identifier: "America/Denver")!,
                                                      children: [
                                                        RSDAnswerResultObject(identifier: "severity", answerType: .integer, value: 3)])
            let item3 = SBATrackedLoggingResultObject(identifier: "Hallucinations",
                                                      text: "Hallucinations",
                                                      detail: nil,
                                                      loggedDate: NSDate(iso8601String: "2019-07-29T14:16:14.711-06:00") as Date,
                                                      timeZone: TimeZone(identifier: "America/Denver")!,
                                                      children: [
                                                        RSDAnswerResultObject(identifier: "severity", answerType: .integer, value: 2),
                                                        RSDAnswerResultObject(identifier: "duration", answerType: .string, value: "DURATION_CHOICE_NOW"),
                                                        RSDAnswerResultObject(identifier: "medicationTiming", answerType: .string, value: "pre-medication")])
            let item4 = SBATrackedLoggingResultObject(identifier: "Nightmares",
                                                      text: "Nightmares",
                                                      detail: nil,
                                                      loggedDate: nil,
                                                      timeZone: TimeZone.current,
                                                      children: [
                                                        RSDAnswerResultObject(identifier: "medicationTiming", answerType: .string, value: "pre-medication")])
            trackedItems.loggingItems = [item1, item2, item3, item4]
            
            let jsonData = try encoder.encode(trackedItems)
            let jsonResult = try JSONSerialization.jsonObject(with: jsonData, options: [])
            guard let dictionary = jsonResult as? [String : Any],
                let items = dictionary["items"] as? [NSDictionary] else {
                    XCTFail("Failed to encode object. \(jsonResult)")
                    return
            }
            
            let expectedItems: [NSDictionary] = [
                [
                    "text" : "Amnesia",
                    "identifier" : "Amnesia"
                ],
                [
                    "loggedDate" : "2019-07-29T14:16:24.561-06:00",
                    "timeZone" : "America/Denver",
                    "severity" : 3,
                    "text" : "Anger",
                    "identifier" : "Anger"
                ],
                [
                    "loggedDate" : "2019-07-29T14:16:14.711-06:00",
                    "timeZone" : "America/Denver",
                    "identifier" : "Hallucinations",
                    "duration" : "DURATION_CHOICE_NOW",
                    "text" : "Hallucinations",
                    "medicationTiming" : "pre-medication",
                    "severity" : 2
                ],
                [
                    "text" : "Nightmares",
                    "identifier" : "Nightmares"
                ]
            ]
            
            XCTAssertEqual(items, expectedItems)
            
            if items.count == expectedItems.count {
                XCTAssertEqual(items[0], expectedItems[0])
                XCTAssertEqual(items[1], expectedItems[1])
                XCTAssertEqual(items[2], expectedItems[2])
                XCTAssertEqual(items[3], expectedItems[3])
            }

        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testSymptomDecodingV1() {
        // There is a bug in the old encodings that would add an empty dictionary if the result
        // was nil. Check for this.
        let json = """
        {
          "logging" : {
            "Hallucinations" : {
              "severity" : 2,
              "duration" : "DURATION_CHOICE_NOW",
              "medicationTiming" : "pre-medication"
            },
            "Anger" : 3
          },
          "trackedItems" : {
            "startDate" : "2019-07-29T14:15:43.776-06:00",
            "endDate" : "2019-07-29T14:15:43.776-06:00",
            "type" : "loggingCollection",
            "identifier" : "trackedItems",
            "items" : [
              {
                "text" : "Amnesia",
                "identifier" : "Amnesia",
                "severity" : {},
                "duration" : {}
              },
              {
                "loggedDate" : "2019-07-29T14:16:24.561-06:00",
                "severity" : 3,
                "text" : "Anger",
                "identifier" : "Anger"
              },
              {
                "loggedDate" : "2019-07-29T14:16:14.711-06:00",
                "identifier" : "Hallucinations",
                "duration" : "DURATION_CHOICE_NOW",
                "text" : "Hallucinations",
                "medicationTiming" : "pre-medication",
                "severity" : 2
              }
            ]
          }
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        do {
            let object = try decoder.decode(SBASymptomReportData.self, from: json)
            
            let results = object.trackedItems.symptomResults
            XCTAssertEqual(results.count, 3)
            
            if let first = results.first {
                XCTAssertEqual(first.identifier, "Amnesia")
                XCTAssertNil(first.loggedDate)
            }
            
            if results.count >= 2 {
                let second = results[1]
                XCTAssertEqual(second.identifier, "Anger")
                XCTAssertNotNil(second.loggedDate)
                XCTAssertEqual(second.timeZone.secondsFromGMT(), -6 * 3600)
                XCTAssertEqual(second.severity, .severe)
            }
            
            if let third = results.last {
                XCTAssertEqual(third.identifier, "Hallucinations")
                XCTAssertNotNil(third.loggedDate)
                XCTAssertEqual(third.timeZone.secondsFromGMT(), -6 * 3600)
                XCTAssertEqual(third.severity, .moderate)
                XCTAssertEqual(third.duration, .now)
                XCTAssertEqual(third.medicationTiming, .preMedication)
            }
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
    
    func testTriggersDecoding() {
        // There is a bug in the old encodings that would add an empty dictionary if the result
        // was nil. Check for this.
        let json = """
        {
           "items" : [
              {
                "timingIdentifier" : "",
                "text" : "Humidity",
                "loggedDate" : "2019-10-03T15:26:57.679-06:00",
                "timeZone" : "America/Denver",
                "identifier" : "Humidity",
                "itemIdentifier" : "Humidity"
              },
              {
                "identifier" : "Cold",
                "text" : "Cold"
              }
            ],
            "endDate" : "2019-10-03T15:26:47.284-06:00",
            "type" : "loggingCollection",
            "identifier" : "trackedItems",
            "startDate" : "2019-10-03T15:26:47.284-06:00"
        }
        """.data(using: .utf8)! // our data in native (JSON) format
        
        do {
            let object = try decoder.decode(SBATriggerCollectionResult.self, from: json)
            
            let results = object.triggerResults
            XCTAssertEqual(results.count, 2)
            
            if let cold = results.last {
                XCTAssertEqual(cold.identifier, "Cold")
                XCTAssertNil(cold.loggedDate)
            }
            
            if let humidity = results.first {
                XCTAssertEqual(humidity.identifier, "Humidity")
                XCTAssertNotNil(humidity.loggedDate)
                XCTAssertEqual(humidity.timeZone.identifier, "America/Denver")
            }
            
            let jsonData = try encoder.encode(object)
            let jsonDictionary = try JSONSerialization.jsonObject(with: jsonData, options: [])
            guard let dictionary = jsonDictionary as? [String : Any],
                let items = dictionary["items"] as? NSArray else {
                    XCTFail("Failed to encode object. \(json)")
                    return
            }
            
            let expectedItems: NSArray = [
                [
                    "loggedDate" : "2019-10-03T15:26:57.679-06:00",
                    "timeZone" : "America/Denver",
                    "identifier" : "Humidity",
                    "text" : "Humidity",
                    "type" : "trigger"
                ],
                [
                    "text" : "Cold",
                    "identifier" : "Cold",
                    "type" : "trigger"
                ]
            ]
            
            XCTAssertEqual(items, expectedItems)
            
            // Check that the triggers can be re-populated from the report json
            let reportClientData = try JSONSerialization.jsonObject(with: json, options: []) as! NSDictionary
            var result = SBATrackedLoggingCollectionResultObject(identifier: "logging")
            try result.updateSelected(from: reportClientData, with: [])
            
            XCTAssertEqual(result.loggingItems.count, 2)
            
            if let first = result.loggingItems.first {
                XCTAssertEqual(first.identifier, "Humidity")
                XCTAssertEqual(first.text, "Humidity")
                XCTAssertNil(first.loggedDate)
                XCTAssertEqual(first.timeZone, TimeZone.current)
            }
            
            if let second = result.loggingItems.last {
                XCTAssertEqual(second.identifier, "Cold")
                XCTAssertEqual(second.text, "Cold")
                XCTAssertNil(second.loggedDate)
                XCTAssertEqual(second.timeZone, TimeZone.current)
            }
            
        } catch let err {
            XCTFail("Failed to decode/encode object: \(err)")
            return
        }
    }
}
