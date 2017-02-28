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
    fileprivate static var listeningToFollowers = false
    fileprivate static var listeningToFollowing = false
    fileprivate static var listeningToBlocked = false
    fileprivate static var listeningToBlockedBy = false
    
    static func stopListeningToAll() {
        stopListeningToLocations()
        stopListeningToConversatons()
        stopListeningToFollowers()
        stopListeningToFollowing()
        stopListeningToResponses()
        stopListeningToBlocked()
        stopListeningToBlockedBy()
    }
    
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
                            let visitorSnap = visitor as! FIRDataSnapshot
                            
                            if !mainStore.state.socialState.blockedBy.contains(visitorSnap.key) {
                                visitors.append((visitor as AnyObject).key)
                            }
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
                    let conversation = Conversation(key: pairKey, partner_uid: partner, listening: listening)
                    mainStore.dispatch(ConversationAdded(conversation: conversation))
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
    
    static func startListeningToFollowers() {
        if !listeningToFollowers {
            listeningToFollowers = true
            let current_uid = mainStore.state.userState.uid
            let followersRef = ref.child("users/social/followers/\(current_uid)")
            
            /** Listen for a Follower Added */
            followersRef.observe(.childAdded, with: { snapshot in
                if snapshot.exists() {
                    if snapshot.value! is Bool {
                        mainStore.dispatch(AddFollower(uid: snapshot.key))
                    }
                }
            })
            
            
            /** Listen for a Follower Removed */
            followersRef.observe(.childRemoved, with: { snapshot in
                if snapshot.exists() {
                    if snapshot.value! is Bool {
                        mainStore.dispatch(RemoveFollower(uid: snapshot.key))
                    }
                }
            })
        }
    }
    
    static func startListeningToFollowing() {
        if !listeningToFollowing {
            listeningToFollowing = true
            let current_uid = mainStore.state.userState.uid
            let followingRef = ref.child("users/social/following/\(current_uid)")
            
            /**
             Listen for a Following Added
             */
            followingRef.observe(.childAdded, with: { snapshot in
                if snapshot.exists() {
                    if snapshot.value! is Bool {
                        mainStore.dispatch(AddFollowing(uid: snapshot.key))
                    }
                    
                }
            })
            
            
            /**
             Listen for a Following Removed
             */
            followingRef.observe(.childRemoved, with: { snapshot in
                if snapshot.exists() {
                    if snapshot.value! is Bool {
                        mainStore.dispatch(RemoveFollowing(uid: snapshot.key))
                    }
                }
            })

        }
    }
    
    static func stopListeningToFollowers() {
        let current_uid = mainStore.state.userState.uid
        ref.child("users/social/followers/\(current_uid)").removeAllObservers()
        listeningToFollowers = false
    }
    
    static func stopListeningToFollowing() {
        let current_uid = mainStore.state.userState.uid
        ref.child("users/social/followers/\(current_uid)").removeAllObservers()
        listeningToFollowing = false
    }
    
    
    static func startListeningToBlocked() {
        if !listeningToBlocked {
            listeningToBlocked = true
            let current_uid = mainStore.state.userState.uid
            let blockedRef = ref.child("users/social/blocked/\(current_uid)")
            
            /** Listen for a Blocked Added */
            blockedRef.observe(.childAdded, with: { snapshot in
                if snapshot.exists() {
                    if snapshot.value! is Bool {
                        mainStore.dispatch(AddBlocked(uid: snapshot.key))
                    }
                }
            })
            
            
            /** Listen for a Blocked Removed */
            blockedRef.observe(.childRemoved, with: { snapshot in
                if snapshot.exists() {
                    if snapshot.value! is Bool {
                        mainStore.dispatch(RemoveBlocked(uid: snapshot.key))
                    }
                }
            })
        }
    }
    
    static func startListeningToBlockedBy() {
        if !listeningToBlockedBy {
            listeningToBlockedBy = true
            let current_uid = mainStore.state.userState.uid
            let blockedByRef = ref.child("users/social/blockedby/\(current_uid)")
            
            /** Listen for a Blocked By Added */
            blockedByRef.observe(.childAdded, with: { snapshot in
                if snapshot.exists() {
                    if snapshot.value! is Bool {
                        mainStore.dispatch(AddBlockedBy(uid: snapshot.key))
                    }
                }
            })
            
            
            /** Listen for a Blocked By Removed */
            blockedByRef.observe(.childRemoved, with: { snapshot in
                if snapshot.exists() {
                    if snapshot.value! is Bool {
                        mainStore.dispatch(RemoveBlockedBy(uid: snapshot.key))
                    }
                }
            })
        }
    }
    
    static func stopListeningToBlocked() {
        let current_uid = mainStore.state.userState.uid
        ref.child("users/social/blocked/\(current_uid)").removeAllObservers()
        listeningToBlocked = false
    }
    
    static func stopListeningToBlockedBy() {
        let current_uid = mainStore.state.userState.uid
        ref.child("users/social/blockedby/\(current_uid)").removeAllObservers()
        listeningToBlockedBy = false
    }
    
}
