//
//  MockSBBActivityManager.swift
//  BridgeAppTests
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
import Research
import BridgeSDK
@testable import BridgeApp

open class MockSBBActivityManager : NSObject, SBBActivityManagerProtocol {
    
    public var schedules = Array<SBBScheduledActivity>()
    
    public var finishedPersistentSchedules = [SBBScheduledActivity]()
    
    public var guids = Set<GuidMap>()
    
    public struct GuidMap : Hashable {
        let identifier : RSDIdentifier
        let activityGuid : String
        let schedulePlanGuid : String
    }
    
    public func createTaskGroup(_ identifier: String, _ activityIdentifiers: [String], _ schedulePlanGuid: String? = nil,_ activityGuidMap: [String : String]? = nil) -> SBAActivityGroupObject {
        let group = SBAActivityGroupObject(identifier: identifier,
                                           title: nil,
                                           journeyTitle: nil,
                                           image: nil,
                                           activityIdentifiers: activityIdentifiers.map { RSDIdentifier(rawValue: $0) },
                                           notificationIdentifier: nil,
                                           schedulePlanGuid: schedulePlanGuid,
                                           activityGuidMap: activityGuidMap)
        SBABridgeConfiguration.shared.addMapping(with: group)
        return group
    }
    
    public func createTaskSchedule(with identifier: RSDIdentifier, scheduledOn: Date, expiresOn: Date?, finishedOn: Date?, clientData: SBBJSONValue?, schedulePlanGuid: String?, activityGuid: String?) -> SBBScheduledActivity {
        
        let schedule = self.createSchedule(with: identifier, scheduledOn: scheduledOn, expiresOn: expiresOn, finishedOn: finishedOn, clientData: clientData, schedulePlanGuid: schedulePlanGuid, activityGuid: activityGuid, activityType: "task")
        schedule.activity.task = SBBTaskReference(dictionaryRepresentation: [ "identifier" : identifier.stringValue ])
        
        schedules.append(schedule)
        return schedule
    }
    
    public func createSurveySchedule(with identifier: RSDIdentifier, scheduledOn: Date, expiresOn: Date?, finishedOn: Date?, clientData: SBBJSONValue?, schedulePlanGuid: String?, activityGuid: String?) -> SBBScheduledActivity {
        
        let schedule = self.createSchedule(with: identifier, scheduledOn: scheduledOn, expiresOn: expiresOn, finishedOn: finishedOn, clientData: clientData, schedulePlanGuid: schedulePlanGuid, activityGuid: activityGuid, activityType: "survey")
        
        let guid = UUID().uuidString
        schedule.activity.survey = SBBSurveyReference(dictionaryRepresentation:[
            "identifier" : identifier.stringValue,
            "guid" : guid,
            "href" : "http://example.org/\(guid)"])
        
        schedules.append(schedule)
        return schedule
    }
    
    public func createSchedule(with identifier: RSDIdentifier, scheduledOn: Date, expiresOn: Date?, finishedOn: Date?, clientData: SBBJSONValue?, schedulePlanGuid: String?, activityGuid: String?, activityType: String) -> SBBScheduledActivity {
        
        let guidMap: GuidMap = {
            if schedulePlanGuid != nil && activityGuid != nil {
                // Return the specific guid map.
                return GuidMap(identifier: identifier, activityGuid: activityGuid!, schedulePlanGuid: schedulePlanGuid!)
            }
            else if let guid = activityGuid {
                // Return the matching guid map or create if nil
                return guids.first(where: { $0.activityGuid == guid }) ??
                    GuidMap(identifier: identifier, activityGuid: guid, schedulePlanGuid: UUID().uuidString)
            }
            else if let guid = schedulePlanGuid {
                // Return the matching identifier map or create if nil
                return guids.first(where: { $0.identifier == identifier && guid == $0.schedulePlanGuid }) ??
                    GuidMap(identifier: identifier, activityGuid: UUID().uuidString, schedulePlanGuid: guid)
            }
            else {
                // Return the matching identifier map or create if nil
                return guids.first(where: { $0.identifier == identifier }) ??
                    GuidMap(identifier: identifier, activityGuid: UUID().uuidString, schedulePlanGuid: UUID().uuidString)
            }
        }()
        
        self.guids.insert(guidMap)
        let guid = guidMap.activityGuid
        let scheduledOnString = (scheduledOn as NSDate).iso8601StringUTC()!
        let schedule = SBBScheduledActivity(dictionaryRepresentation: [
            "guid" : "\(guid):\(scheduledOnString)"
            ])!
        schedule.schedulePlanGuid = guidMap.schedulePlanGuid
        schedule.scheduledOn = scheduledOn
        schedule.expiresOn = expiresOn
        schedule.startedOn = finishedOn?.addingTimeInterval(-3 * 60)
        schedule.finishedOn = finishedOn
        schedule.clientData = clientData
        schedule.persistent = NSNumber(value: (expiresOn == nil))
        let activity = SBBActivity(dictionaryRepresentation: [
            "activityType" : activityType,
            "guid" : guid,
            "label" : identifier.stringValue
            ])!
        schedule.activity = activity

        return schedule
    }
    
    @discardableResult
    public func createPersistentSchedule(from schedule: SBBScheduledActivity) -> SBBScheduledActivity? {
        guard let finishedOn = schedule.finishedOn, let activityId = schedule.activityIdentifier else { return nil }
        
        let newSchedule = self.createSchedule(with: RSDIdentifier(rawValue: activityId),
                                   scheduledOn: finishedOn,
                                   expiresOn: nil,
                                   finishedOn: nil,
                                   clientData: nil,
                                   schedulePlanGuid: schedule.schedulePlanGuid,
                                   activityGuid: schedule.activity.guid,
                                   activityType: schedule.activity.activityType)
        
        newSchedule.activity.task = schedule.activity.task?.copy(with: activityId)
        newSchedule.activity.survey = schedule.activity.survey?.copy(with: activityId)
        newSchedule.activity.compoundActivity = schedule.activity.compoundActivity?.copy(with: activityId)
        
        schedules.append(newSchedule)
        return newSchedule
    }
    
    private func addFinishedPersistent(_ scheduledActivities: [SBBScheduledActivity]) {
        let filtered = scheduledActivities.filter { $0.persistentValue && $0.isCompleted }
        self.finishedPersistentSchedules.append(contentsOf: filtered)
    }
    
    public let offMainQueue = DispatchQueue(label: "org.sagebionetworks.BridgeApp.TestActivityManager")
    
    public func getScheduledActivities(from scheduledFrom: Date, to scheduledTo: Date, cachingPolicy policy: SBBCachingPolicy, withCompletion completion: @escaping SBBActivityManagerGetCompletionBlock) -> URLSessionTask {
        offMainQueue.async {
            
            // add a new schedule for the finished persistent schedules.
            self.finishedPersistentSchedules.forEach {
                self.createPersistentSchedule(from: $0)
            }
            self.finishedPersistentSchedules.removeAll()
            
            let predicate = SBBScheduledActivity.availablePredicate(from: scheduledFrom, to: scheduledTo)
            let filtered = Array(self.schedules.filter { predicate.evaluate(with: $0) })
            completion(filtered, nil)
        }
        return URLSessionTask()
    }
    
    public func getScheduledActivities(from scheduledFrom: Date, to scheduledTo: Date, withCompletion completion: @escaping SBBActivityManagerGetCompletionBlock) -> URLSessionTask {
        return self.getScheduledActivities(from: scheduledFrom, to: scheduledTo, cachingPolicy: .fallBackToCached, withCompletion: completion)
    }
    
    public func getScheduledActivities(forDaysAhead daysAhead: Int, daysBehind: Int, cachingPolicy policy: SBBCachingPolicy, withCompletion completion: @escaping SBBActivityManagerGetCompletionBlock) -> URLSessionTask {
        fatalError("Deprecated")
    }
    
    public func getScheduledActivities(forDaysAhead daysAhead: Int, cachingPolicy policy: SBBCachingPolicy, withCompletion completion: @escaping SBBActivityManagerGetCompletionBlock) -> URLSessionTask {
        fatalError("Deprecated")
    }
    
    public func getScheduledActivities(forDaysAhead daysAhead: Int, withCompletion completion: @escaping SBBActivityManagerGetCompletionBlock) -> URLSessionTask {
        fatalError("Deprecated")
    }
    
    public func start(_ scheduledActivity: SBBScheduledActivity, asOf startDate: Date, withCompletion completion: SBBActivityManagerUpdateCompletionBlock? = nil) -> URLSessionTask {
        
        offMainQueue.async {
            if let schedule = self.schedules.first(where: { scheduledActivity.guid == $0.guid }) {
                schedule.startedOn = startDate
            } else {
                scheduledActivity.startedOn = startDate
                self.schedules.append(scheduledActivity)
            }
            completion?("passed", nil)
        }
        return URLSessionTask()
    }
    
    public func finish(_ scheduledActivity: SBBScheduledActivity, asOf finishDate: Date, withCompletion completion: SBBActivityManagerUpdateCompletionBlock? = nil) -> URLSessionTask {
        
        offMainQueue.async {
            if let schedule = self.schedules.first(where: { scheduledActivity.guid == $0.guid }) {
                schedule.finishedOn = finishDate
            } else {
                scheduledActivity.finishedOn = finishDate
                self.schedules.append(scheduledActivity)
            }
            self.addFinishedPersistent([scheduledActivity])
            completion?("passed", nil)
        }
        return URLSessionTask()
    }
    
    public func delete(_ scheduledActivity: SBBScheduledActivity, withCompletion completion: SBBActivityManagerUpdateCompletionBlock? = nil) -> URLSessionTask {
        offMainQueue.async {
            self.schedules.remove(where: { scheduledActivity.guid == $0.guid })
            completion?("passed", nil)
        }
        return URLSessionTask()
    }
    
    public func setClientData(_ clientData: SBBJSONValue, for scheduledActivity: SBBScheduledActivity, withCompletion completion: SBBActivityManagerUpdateCompletionBlock? = nil) -> URLSessionTask {
        offMainQueue.async {
            if let schedule = self.schedules.first(where: { scheduledActivity.guid == $0.guid }) {
                schedule.clientData = clientData
            } else {
                scheduledActivity.clientData = clientData
                self.schedules.append(scheduledActivity)
            }
            completion?("passed", nil)
        }
        return URLSessionTask()
    }
    
    public func updateScheduledActivities(_ scheduledActivities: [Any], withCompletion completion: SBBActivityManagerUpdateCompletionBlock? = nil) -> URLSessionTask {
        
        guard let scheduledActivities = scheduledActivities as? [SBBScheduledActivity]
            else {
                fatalError("Objects not of expected cast.")
        }
        
        offMainQueue.async {
            scheduledActivities.forEach { (scheduledActivity) in
                self.schedules.remove(where: { scheduledActivity.guid == $0.guid })
            }
            self.schedules.append(contentsOf: scheduledActivities)
            self.addFinishedPersistent(scheduledActivities)
            completion?("passed", nil)
        }
        return URLSessionTask()
    }
    
    public func getCachedSchedules(using predicate: NSPredicate, sortDescriptors: [NSSortDescriptor]?, fetchLimit: UInt) throws -> [SBBScheduledActivity] {
        
        var results = schedules.filter { predicate.evaluate(with: $0) }
        if let sortDescriptors = sortDescriptors {
            results = (results as NSArray).sortedArray(using: sortDescriptors) as! [SBBScheduledActivity]
        }
        
        return ((fetchLimit > 0) && (fetchLimit < results.count)) ? Array(results[..<Int(fetchLimit)]) : results
    }
}
