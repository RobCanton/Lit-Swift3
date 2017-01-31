//
//  Listeners.swift
//  Lit
//
//  Created by Robert Canton on 2017-01-31.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import ReSwift
import Firebase


class Listeners {

    fileprivate static let ref = FIRDatabase.database().reference()
    
    fileprivate static var listeningToLocations = false
    fileprivate static var listeningToResponses = false
    fileprivate static var listeningToConversations = false
    
    static func startListeningToLocations() {
        if !listeningToLocations {
            listeningToLocations = true
            let locations = mainStore.state.locations
            
            for i in 0 ..< locations.count {
                let location = locations[i]
                let locationRef = ref.child("locations")
                
                locationRef.child("visitors/\(location.getKey())").observe(.value, with: { snapshot in
                    var visitors = [String]()
                    if snapshot.exists() {
                        for visitor in snapshot.children {
                            visitors.append((visitor as AnyObject).key)
                        }
                    }
                    mainStore.dispatch(SetVisitorsForLocation(locationIndex: i, visitors: visitors))
                })
            }
        }
    }
    
    static func stopListeningToLocations() {
        let locations = mainStore.state.locations
        
        for location in locations {
            let locationRef = ref.child("locations")
            locationRef.child("visitors/\(location.getKey())").removeAllObservers()
            locationRef.child("uploads/\(location.getKey())").removeAllObservers()
        }
        
        listeningToLocations = false
    }
    
    static func startListeningToResponses() {
        if !listeningToResponses {
            listeningToResponses = true
            let current_uid = mainStore.state.userState.uid
            let responsesRef = ref.child("api/responses")
            
            /**
             Listen for a Following Added
             */
            let locationUpdatesRef = responsesRef.child("location_updates/\(current_uid)")
            locationUpdatesRef.observe(.value, with: { snapshot in
                if snapshot.exists() {
                    let dict = snapshot.value! as! [String:Double]
                    LocationService.handleLocationsResponse(dict)
                    locationUpdatesRef.removeValue()
                }
            })
        }
    }
    
    static func stopListeningToResponses() {
        let current_uid = mainStore.state.userState.uid
        ref.child("api/responses/location_updates/\(current_uid)").removeAllObservers()
        listeningToResponses = false
    }
    
    static func startListeningToConversations() {
        if !listeningToConversations {
            listeningToConversations = true
            
            let uid = mainStore.state.userState.uid
            let conversationsRef = ref.child("users/conversations/\(uid)")
            conversationsRef.observe(.childAdded, with: { snapshot in
                if snapshot.exists() {
                    
                    let partner = snapshot.key
                    let pairKey = createUserIdPairKey(uid1: uid, uid2: partner)
                    let listening = snapshot.value! as! Bool
                    if listening {
                        print("Listening to: \(pairKey)")
                        let conversation = Conversation(key: pairKey, partner_uid: partner)
                        mainStore.dispatch(ConversationAdded(conversation: conversation))
                    } else {
                        print("Not listening to: \(pairKey)")
                    }
                }
            })
        }
    }
    
    static func stopListeningToConversatons() {
        let uid = mainStore.state.userState.uid
        let conversationsRef = ref.child("users/conversations/\(uid)")
        conversationsRef.removeAllObservers()
        listeningToConversations = false
    }
    
    
    
    
}
