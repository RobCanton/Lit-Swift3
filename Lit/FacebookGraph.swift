//
//  FacebookGraph.swift
//  Lit
//
//  Created by Robert Canton on 2016-11-09.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import Firebase
import FBSDKCoreKit
import FBSDKLoginKit

class FacebookGraph {

    static func requestFacebookFriendIds(completion:@escaping (_ success: Bool, _ fb_ids:[String])->()) {
        FBSDKGraphRequest(graphPath: "me/friends", parameters: nil).start {(connection, result, error) -> Void in
            var fb_ids = [String]()
            if error != nil {
                NSLog(error.debugDescription)
                completion(false, fb_ids)
                return
            }
            
            let r = result as! [String:Any]
            
            let data = r["data"] as! [NSDictionary]
            for item in data {
                if let id = item["id"] as? String {
                    fb_ids.append(id)
                }
            }
            completion(true, fb_ids)
        }
    }
    
    
    static func getFacebookFriends(completion:@escaping (_ success: Bool, _ userIds:[String])->()) {
        
        let ref = FIRDatabase.database().reference()
        requestFacebookFriendIds(completion: { success, fb_ids in
            var _users = [String]()
            
            if !success {
                completion(false, _users)
                return
            }
            
            
            if fb_ids.count == 0 {
                completion(true, _users)
                return
            }
            
            var count = 0
            for id in fb_ids {
                
                let ref = ref.child("users/facebook/\(id)")
                ref.observeSingleEvent(of: .value, with: { snapshot in
                    if snapshot.exists()
                    {
                        print(snapshot.value!)
                        _users.append(snapshot.value! as! String)
                    }
                    count += 1
                    if count >= fb_ids.count {
                        completion(true, _users)
                        return
                    }
                })
            }
            
            
        })
    }
    
    
    static func getProfilePicture(completion:@escaping (_ imageURL:String?)->()) {
        let params: [String : Any] = ["redirect": false, "height": 720, "width": 720, "type": "large"]
        
        FBSDKGraphRequest(graphPath: "me/picture", parameters: params).start {(connection, result, error) -> Void in
            var imageUrl:String?
            if error != nil {
                NSLog(error.debugDescription)
                return
            }
            else {
                let dictionary = result as? NSDictionary
                let data = dictionary?.object(forKey: "data") as? NSDictionary
                imageUrl = data?.object(forKey: "url") as? String
            }
            completion(imageUrl)
        }
    }
}
