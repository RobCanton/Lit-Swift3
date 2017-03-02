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

    static func requestFacebookFriendIds(completion:@escaping (_ fb_ids:[String])->()) {
        FBSDKGraphRequest(graphPath: "me/friends", parameters: nil).start {(connection, result, error) -> Void in
            if error != nil {
                NSLog(error.debugDescription)
                return
            }
            
            let r = result as! [String:Any]
            var fb_ids = [String]()
            let data = r["data"] as! [NSDictionary]
            for item in data {
                if let id = item["id"] as? String {
                    fb_ids.append(id)
                }
            }
            completion(fb_ids)
        }
    }
    
    
    static func getFacebookFriends(completion:@escaping (_ userIds:[String])->()) {
        
        let ref = FIRDatabase.database().reference()
        requestFacebookFriendIds(completion: { fb_ids in
            var _users = [String]()
            
            
            if fb_ids.count == 0 {
                completion(_users)
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
                        completion(_users)
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
