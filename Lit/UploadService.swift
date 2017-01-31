//
//  UploadService.swift
//  Lit
//
//  Created by Robert Canton on 2017-01-31.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import Firebase



class UploadService {
    
    
    static func getUpload(key:String, completion: @escaping (_ item:StoryItem?)->()) {
        if let cachedUpload = dataCache.object(forKey: "upload-\(key)" as NSString) as? StoryItem {
            return completion(cachedUpload)
        }
        
        let ref = FIRDatabase.database().reference()
        let postRef = ref.child("uploads/\(key)")
        
        postRef.observeSingleEvent(of: .value, with: { snapshot in
        
            var item:StoryItem?
            
            if snapshot.exists() {
                
                let dict = snapshot.value as! [String:AnyObject]
                
                let meta = dict["meta"] as! [String:AnyObject]
                var viewers = [String:Double]()
                var comments = [Comment]()
                
                if meta["delete"] == nil {
                    
                    let key = key
                    let authorId = meta["author"] as! String
                    let locationKey = meta["location"] as! String
                    let downloadUrl = URL(string: meta["url"] as! String)!
                    let contentTypeStr = meta["contentType"] as! String
                    var contentType = ContentType.invalid
                    var videoURL:URL?
                    if contentTypeStr == "image/jpg" {
                        contentType = .image
                    } else if contentTypeStr == "video/mp4" {
                        contentType = .video
                        if meta["videoURL"] != nil {
                            videoURL = URL(string: meta["videoURL"] as! String)!
                        }
                    }
                    
                    let toProfile = meta["toProfile"] as! Bool
                    let toStory = meta["toStory"] as! Bool
                    let toLocation = meta["toLocation"] as! Bool
                    
                    let dateCreated = meta["dateCreated"] as! Double
                    let length = meta["length"] as! Double
                    
                    var viewers = [String:Double]()
                    if snapshot.hasChild("views") {
                        viewers = dict["views"] as! [String:Double]
                    }
                    
                    var comments = [Comment]()
                    if snapshot.hasChild("comments") {
                        let commentsDict = dict["comments"] as! [String:AnyObject]
                        for (key, object) in commentsDict {
                            let key = key
                            let author = object["author"] as! String
                            let text = object["text"] as! String
                            let timestamp = object["timestamp"] as! Double
                            
                            let comment = Comment(key: key, author: author, text: text, timestamp: timestamp)
                            comments.append(comment)
                        }
                    }
                    
                    //comments.sortInPlace({ return $0 < $1 })
                    
                    item = StoryItem(key: key, authorId: authorId,locationKey: locationKey, downloadUrl: downloadUrl,videoURL: videoURL, contentType: contentType, dateCreated: dateCreated, length: length, toProfile: toProfile, toStory: toStory, toLocation: toLocation, viewers: viewers, comments: comments)
                    dataCache.setObject(item!, forKey: "upload-\(key)" as NSString)
                }
            }
            return completion(item)
        })
    }
    
    static func downloadStory(postKeys:[String], completion: @escaping (_ story:[StoryItem])->()) {
        var story = [StoryItem]()
        var loadedCount = 0
        for postKey in postKeys {
            
            getUpload(key: postKey, completion: { item in
                
                if let _ = item {
                    story.append(item!)
                }
                loadedCount += 1
                if loadedCount >= postKeys.count {
                    DispatchQueue.main.async {
                        completion(story)
                    }
                }
                
            })
        }
    }
}
