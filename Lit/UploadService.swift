//
//  UploadService.swift
//  Lit
//
//  Created by Robert Canton on 2017-01-31.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import Firebase
import CoreLocation

class Upload {
    
    var userProfile = false
    var toProfile = false
    var toStory = false
    var locationKey:String = ""
    
    var coordinates:CLLocation?
    var image:UIImage?
    var videoURL:URL?
}

class UploadService {

    static func sendImage(upload:Upload, completion:(()->())) {
        
        //If upload has no destination do not upload it
        if !upload.toProfile && !upload.toStory && upload.locationKey == "" { return }
        
        if upload.image == nil { return }
        
        let uid = mainStore.state.userState.uid
        
        let ref = FIRDatabase.database().reference()
        let dataRef = ref.child("uploads").childByAutoId()
        let postKey = dataRef.key
        
        if let data = UIImageJPEGRepresentation(upload.image!, 0.5) {
            // Create a reference to the file you want to upload
            // Create the file metadata
            let contentTypeStr = "image/jpg"
            let metadata = FIRStorageMetadata()
            metadata.contentType = contentTypeStr
            
//            var uploadingMurmer = Murmur(title: "Uploading...")
//            uploadingMurmer.backgroundColor = UIColor(white: 0.04, alpha: 1.0)
//            uploadingMurmer.titleColor = UIColor.lightGrayColor()
//            show(whistle: uploadingMurmer, action: .Show(60.0))
            
            // Upload file and metadata to the object
            let storageRef = FIRStorage.storage().reference()
            let uploadTask = storageRef.child("user_uploads/images/\(uid)/\(postKey)").put(data, metadata: metadata) { metadata, error in
                
                if (error != nil) {
                    // HANDLE ERROR
//                    hide()
//                    var murmur = Murmur(title: "Unable to upload.")
//                    murmur.backgroundColor = errorColor
//                    murmur.titleColor = UIColor.whiteColor()
//                    show(whistle: murmur, action: .Show(5.0))
                } else {
                    // Metadata contains file metadata such as size, content-type, and download URL.
                    let downloadURL = metadata!.downloadURL()
                    let obj = [
                        "author": uid,
                        "toProfile": upload.toProfile,
                        "toStory": upload.toStory,
                        "toLocation": upload.locationKey != "",
                        "location": upload.locationKey,
                        "url": downloadURL!.absoluteString,
                        "contentType": contentTypeStr,
                        "dateCreated": [".sv": "timestamp"],
                        "length": 5.0
                    ] as [String : Any]
                    dataRef.child("meta").setValue(obj, withCompletionBlock: { error, _ in
                        //hide()
//                        if error == nil {
//                            var murmur = Murmur(title: "Image uploaded!")
//                            murmur.backgroundColor = accentColor
//                            murmur.titleColor = UIColor.whiteColor()
//                            show(whistle: murmur, action: .Show(3.0))
//                        } else {
//                            var murmur = Murmur(title: "Unable to upload.")
//                            murmur.backgroundColor = errorColor
//                            murmur.titleColor = UIColor.whiteColor()
//                            show(whistle: murmur, action: .Show(5.0))
//                        }
                    })
                    
                }
            }
            completion()
        }
        
    }
    
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
