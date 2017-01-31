//
//  UserService.swift
//  Lit
//
//  Created by Robert Canton on 2017-01-31.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import Firebase
import FBSDKLoginKit


let dataCache = NSCache<NSString, AnyObject>()

class UserService {
    
    static let ref = FIRDatabase.database().reference()
    
    static func login(_ user:User) {
        mainStore.dispatch(UserIsAuthenticated(user: user))
        Listeners.startListeningToResponses()
        Listeners.startListeningToConversations()
    }
    
    static func logout() {
        let loginManager = FBSDKLoginManager()
        loginManager.logOut()
        logoutOfFirebase()
    }
    
    static func logoutOfFirebase() {
        try! FIRAuth.auth()!.signOut()
        mainStore.dispatch(UserIsUnauthenticated())
        mainStore.dispatch(ClearLocations())
        mainStore.dispatch(ClearConversations())
        Listeners.stopListeningToResponses()
        Listeners.stopListeningToLocations()
        Listeners.stopListeningToConversatons()
    }
    
    static func getUser(_ uid:String, completion: @escaping (_ user:User?) -> Void) {
        if let cachedUser = dataCache.object(forKey: uid as NSString) as? User {
            completion(cachedUser)
        } else {
            ref.child("users/profile/basic/\(uid)").observe(.value, with: { snapshot in
                let dict = snapshot.value as! [String:AnyObject]
                var user:User?
                if snapshot.exists() {
                    let name        = dict["name"] as! String
                    let displayName = dict["username"] as! String
                    let imageURL    = dict["profileImageURL"] as! String
                    user = User(uid: uid, displayName: displayName, name: name, imageURL: imageURL, largeImageURL: nil, bio: nil)
                    dataCache.setObject(user!, forKey: uid as NSString)
                }
                
                completion(user)
            })
        }
    }
}
