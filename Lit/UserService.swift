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
        LocationService.getUserRadiusSetting()
        sendFCMToken()
        Listeners.startListeningToResponses()
        Listeners.startListeningToConversations()
        Listeners.startListeningToFollowers()
        Listeners.startListeningToFollowing()
        Listeners.startListeningToBlocked()
        Listeners.startListeningToBlockedBy()
    }
    
    static func logout() {
        let loginManager = FBSDKLoginManager()
        loginManager.logOut()
        logoutOfFirebase()
    }
    
    static func logoutOfFirebase() {
        mainStore.dispatch(ClearLocations())
        mainStore.dispatch(ClearConversations())
    
        Listeners.stopListeningToAll()
        mainStore.dispatch(ClearSocialState())
        mainStore.dispatch(UserIsUnauthenticated())
        try! FIRAuth.auth()!.signOut()
    }
    
    static func sendFCMToken() {
        if let token = FIRInstanceID.instanceID().token() {
            if let user = mainStore.state.userState.user {
                let fcmRef = ref.child("users/FCMToken/\(user.getUserId())")
                fcmRef.setValue(token)
            }
        }
    }
    
    static func getUser(_ uid:String, completion: @escaping (_ user:User?) -> Void) {
        if let cachedUser = dataCache.object(forKey: "user-\(uid)" as NSString as NSString) as? User {
            completion(cachedUser)
        } else {
            ref.child("users/profile/basic/\(uid)").observe(.value, with: { snapshot in
                var user:User?
                if snapshot.exists() {
                    let dict = snapshot.value as! [String:AnyObject]
                    let name        = dict["name"] as! String
                    let displayName = dict["username"] as! String
                    let imageURL    = dict["profileImageURL"] as! String
                    
                    var verified = false
                    if snapshot.hasChild("verified") {
                        verified = true
                    }
                    user = User(uid: uid, displayName: displayName, name: name, imageURL: imageURL, largeImageURL: nil, bio: nil, verified: verified)
                    dataCache.setObject(user!, forKey: "user-\(uid)" as NSString)
                }
                
                completion(user)
            })
        }
    }
    
    static func getUser(_ uid:String, check:Int, completion: @escaping (_ user:User?, _ check:Int) -> Void) {
        if let cachedUser = dataCache.object(forKey: "user-\(uid)" as NSString as NSString) as? User {
            completion(cachedUser, check)
        } else {
            ref.child("users/profile/basic/\(uid)").observe(.value, with: { snapshot in
                var user:User?
                if snapshot.exists() {
                    let dict = snapshot.value as! [String:AnyObject]
                    let name        = dict["name"] as! String
                    let displayName = dict["username"] as! String
                    let imageURL    = dict["profileImageURL"] as! String
                    
                    var verified = false
                    if snapshot.hasChild("verified") {
                        verified = true
                    }
                    user = User(uid: uid, displayName: displayName, name: name, imageURL: imageURL, largeImageURL: nil, bio: nil, verified: verified)
                    dataCache.setObject(user!, forKey: "user-\(uid)" as NSString)
                }
                
                completion(user, check)
            })
        }
    }
    
    
    static func getUserFullProfile(user:User, completion: @escaping (_ user:User)->()) {
        if user.bio != nil && user.largeImageURL != nil {
            completion(user)
        }
        if user.bio == nil || user.largeImageURL == nil {
            ref.child("users/profile/full/\(user.getUserId())").observe(.value, with: { (snapshot) in
                
                if snapshot.exists() {
                    let dict = snapshot.value as! [String:String]
                    user.largeImageURL   = dict["largeProfileImageURL"]
                    user.bio             = dict["bio"]
                    
                    let uid = user.getUserId()
                    dataCache.removeObject(forKey: "user-\(uid)" as NSString)
                    dataCache.setObject(user, forKey: "user-\(uid)" as NSString)
                }
                completion(user)
            })
        }
    }
    
    static func getUsers(userIds:[String], completionHandler: @escaping (_ users:[User])->()) {
        var users = [User]()
        var loadedCount = 0
        for userId in userIds {
            getUser(userId, completion: { _user in
                if let user = _user {
                    users.append(user)
                }
                loadedCount += 1
                if loadedCount >= userIds.count {
                    DispatchQueue.main.async {
                        completionHandler(users)
                    }
                }
            })
        }
    }
    
    static func sendMessage(conversation:Conversation, message:String, uploadKey:String?, completion: ((_ success:Bool)->())?) {
        let messageRef = ref.child("conversations/\(conversation.getKey())/messages").childByAutoId()
        let uid = mainStore.state.userState.uid
        
        let requestRef = ref.child("api/requests/message").childByAutoId()
        requestRef.setValue([
            "conversation": conversation.getKey(),
            "sender": uid as AnyObject,
            "recipient": conversation.getPartnerId() as AnyObject,
            "text": message as AnyObject,
            "timestamp": [".sv":"timestamp"] as AnyObject
            ])
    }
    
    static func followUser(uid:String) {
        let current_uid = mainStore.state.userState.uid
        
        let socialRef = ref.child("users/social")
        let userRef = socialRef.child("followers/\(uid)/\(current_uid)")
        userRef.setValue(false)
        
        
        let currentUserRef = socialRef.child("following/\(current_uid)/\(uid)")
        currentUserRef.setValue(false, withCompletionBlock: {
            error, ref in
        })
        
        let followRequestRef = ref.child("api/requests/social").childByAutoId()
        followRequestRef.setValue([
            "type": "FOLLOW",
            "sender": current_uid,
            "recipient": uid
        ])
    
        
        unblockUser(uid: uid, completionHandler: { success in })
        
        
    }
    
    static func unfollowUser(uid:String) {
        let current_uid = mainStore.state.userState.uid
        
        let userRef = ref.child("users/social/followers/\(uid)/\(current_uid)")
        userRef.removeValue()
        
        let currentUserRef = ref.child("users/social/following/\(current_uid)/\(uid)")
        currentUserRef.removeValue()
        
        let followRequestRef = ref.child("api/requests/social").childByAutoId()
        followRequestRef.setValue([
            "type": "UNFOLLOW",
            "sender": current_uid,
            "recipient": uid
        ])
    }
    

    
    static func listenToFollowers(uid:String, completion:@escaping (_ followers:[String])->()) {
        let followersRef = ref.child("users/social/followers/\(uid)")
        followersRef.observe(.value, with: { snapshot in
            var _users = [String]()
            if snapshot.exists() {
                let dict = snapshot.value as! [String:Bool]
                
                for (uid, _) in dict {
                    _users.append(uid)
                }
            }
            completion(_users)
        })
    }
    
    
    
    static func listenToFollowing(uid:String, completion:@escaping (_ following:[String])->()) {
        let followingRef = ref.child("users/social/following/\(uid)")
        followingRef.observe(.value, with: { snapshot in
            var _users = [String]()
            if snapshot.exists() {
                let dict = snapshot.value as! [String:Bool]
                
                for (uid, _) in dict {
                    _users.append(uid)
                }
            }
            completion(_users)
        })
    }
    
    static func stopListeningToFollowers(uid:String) {
        if uid != mainStore.state.userState.uid {
            ref.child("users/social/followers/\(uid)").removeAllObservers()
        }
    }
    
    static func stopListeningToFollowing(uid:String) {
        if uid != mainStore.state.userState.uid {
            ref.child("users/social/following/\(uid)").removeAllObservers()
        }
    }
    
    
    
    
    
    
    
    static func uploadProfilePicture(largeImage:UIImage, smallImage:UIImage , completionHandler:@escaping (_ success:Bool, _ largeImageURL:String?, _ smallImageURL:String?)->()) {
        let storageRef = FIRStorage.storage().reference()
        if let largeImageTask = uploadLargeProfilePicture(image: largeImage) {
            largeImageTask.observe(.success, handler: { largeImageSnapshot in
                if let smallImageTask = uploadSmallProfilePicture(image: smallImage) {
                    smallImageTask.observe(.success, handler: { smallImageSnapshot in
                        let largeImageURL = largeImageSnapshot.metadata!.downloadURL()!.absoluteString
                        let smallImageURL =  smallImageSnapshot.metadata!.downloadURL()!.absoluteString
                        completionHandler(true,largeImageURL, smallImageURL)
                    })
                    smallImageTask.observe(.failure, handler: { _ in completionHandler(false , nil, nil) })
                } else { completionHandler(false , nil, nil) }
            })
            largeImageTask.observe(.failure, handler: { _ in completionHandler(false , nil, nil) })
        } else { completionHandler(false , nil, nil)}
        
    }
    
    private static func uploadLargeProfilePicture(image:UIImage) -> FIRStorageUploadTask? {
        guard let user = FIRAuth.auth()?.currentUser else { return nil}
        let storageRef = FIRStorage.storage().reference()
        let imageRef = storageRef.child("user_profiles/\(user.uid)/large")
        if let picData = UIImageJPEGRepresentation(image, 0.6) {
            let contentTypeStr = "image/jpg"
            let metadata = FIRStorageMetadata()
            metadata.contentType = contentTypeStr
            
            let uploadTask = imageRef.put(picData, metadata: metadata) { metadata, error in
                if (error != nil) {
                    // Uh-oh, an error occurred!
                } else {}
            }
            return uploadTask
            
        }
        return nil
    }
    
    private static func uploadSmallProfilePicture(image:UIImage) -> FIRStorageUploadTask? {
        guard let user = FIRAuth.auth()?.currentUser else { return nil}

        let storageRef = FIRStorage.storage().reference()
        let imageRef = storageRef.child("user_profiles/\(user.uid)/small")
        if let picData = UIImageJPEGRepresentation(image, 0.9) {
            let contentTypeStr = "image/jpg"
            let metadata = FIRStorageMetadata()
            metadata.contentType = contentTypeStr
            
            let uploadTask = imageRef.put(picData, metadata: metadata) { metadata, error in
                if (error != nil) {
                    // Uh-oh, an error occurred!
                } else {}
            }
            return uploadTask
            
        }
        return nil
    }
    
    static func updateProfilePictureURL(largeURL:String, smallURL:String, completionHandler:@escaping ()->()) {
        let uid = mainStore.state.userState.uid
        let basicRef = FIRDatabase.database().reference().child("users/profile/basic/\(uid)")
        basicRef.updateChildValues([
            "profileImageURL": smallURL
            ], withCompletionBlock: { error, ref in
                let fullRef = FIRDatabase.database().reference().child("users/profile/full/\(uid)")
                fullRef.updateChildValues([
                    "largeProfileImageURL": largeURL
                    ], withCompletionBlock: { error, ref in
                        
                        completionHandler()
                })
        })
    }
    
    
    static func blockUser(uid:String, completionHandler:@escaping (_ success:Bool)->()) {
        let current_uid = mainStore.state.userState.uid
        
        let socialRef = ref.child("users/social")
        let updateData = [
            "blocked/\(current_uid)/\(uid)":true,
            "blockedby/\(uid)/\(current_uid)":true
        ]
        socialRef.updateChildValues(updateData, withCompletionBlock: { error, ref in
            completionHandler(error == nil)
        })
        
        socialRef.child("followers/\(current_uid)/\(uid)").removeValue()
        socialRef.child("following/\(current_uid)/\(uid)").removeValue()
        socialRef.child("followers/\(uid)/\(current_uid)").removeValue()
        socialRef.child("following/\(uid)/\(current_uid)").removeValue()
        
        for conversation in mainStore.state.conversations {
            if conversation.getPartnerId() == uid {
                muteConversation(conversation: conversation)
            }
        }
        
        UserService.ref.child("users/conversations/\(uid)/\(current_uid)").setValue(false)
    }
    
    static func unblockUser(uid:String, completionHandler:@escaping (_ success:Bool)->()) {
        let current_uid = mainStore.state.userState.uid

        for conversation in mainStore.state.conversations {
            if conversation.getPartnerId() == uid {
                unmuteConversation(conversation: conversation)
            }
        }
        
        let socialRef = ref.child("users/social")
        let updateData:[String:Any?] = [
            "blocked/\(current_uid)/\(uid)":nil,
            "blockedby/\(uid)/\(current_uid)":nil
        ]
        
        socialRef.updateChildValues(updateData, withCompletionBlock: { error, ref in
            completionHandler(error == nil)
        })
        
        
    }
    
    static func muteConversation(conversation:Conversation) {
        let partner = conversation.getPartnerId()
        let uid = mainStore.state.userState.uid
        
        let userRef = UserService.ref.child("users/conversations/\(uid)/\(partner)")
        
        userRef.setValue(false, withCompletionBlock: { error, ref in
            mainStore.dispatch(MuteConversation(conversationKey: conversation.getKey()))
        })
    }
    
    static func unmuteConversation(conversation:Conversation) {
        let partner = conversation.getPartnerId()
        let uid = mainStore.state.userState.uid
        
        let userRef = UserService.ref.child("users/conversations/\(uid)/\(partner)")
        
        userRef.setValue(true, withCompletionBlock: { error, ref in
            mainStore.dispatch(UnmuteConversation(conversationKey: conversation.getKey()))
        })
    }
    
    
    
    
    
}
