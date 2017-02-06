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
import AVFoundation
import Whisper

class Upload {
    
    var userProfile = false
    var toProfile = false
    var toStory = false
    var locationKey:String = ""
    
    var caption:String = ""
    
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
            
            var uploadingMurmer = Murmur(title: "Uploading...")
            uploadingMurmer.backgroundColor = UIColor(white: 0.04, alpha: 1.0)
            uploadingMurmer.titleColor = UIColor.lightGray
            show(whistle: uploadingMurmer, action: .show(60.0))
            
            // Upload file and metadata to the object
            let storageRef = FIRStorage.storage().reference()
            let uploadTask = storageRef.child("user_uploads/images/\(uid)/\(postKey)").put(data, metadata: metadata) { metadata, error in
                
                if (error != nil) {
                    // HANDLE ERROR
                    hide()
                    var murmur = Murmur(title: "Unable to upload.")
                    murmur.backgroundColor = errorColor
                    murmur.titleColor = UIColor.white
                    show(whistle: murmur, action: .show(5.0))
                } else {
                    // Metadata contains file metadata such as size, content-type, and download URL.
                    let downloadURL = metadata!.downloadURL()
                    let obj = [
                        "author": uid,
                        "caption": upload.caption,
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
                        hide()
                        if error == nil {
                            var murmur = Murmur(title: "Image uploaded!")
                            murmur.backgroundColor = accentColor
                            murmur.titleColor = UIColor.white
                            show(whistle: murmur, action: .show(3.0))
                        } else {
                            var murmur = Murmur(title: "Unable to upload.")
                            murmur.backgroundColor = errorColor
                            murmur.titleColor = UIColor.white
                            show(whistle: murmur, action: .show(5.0))
                        }
                    })
                    
                }
            }
            completion()
        }
        
    }
    
    private static func uploadVideoStill(url:URL, postKey:String, completion:@escaping (_ thumb_url:String)->()) {
        let storageRef = FIRStorage.storage().reference()
        if let videoStill = generateVideoStill(url: url) {
            if let data = UIImageJPEGRepresentation(videoStill, 0.5) {
                let stillMetaData = FIRStorageMetadata()
                stillMetaData.contentType = "image/jpg"
                let uid = mainStore.state.userState.uid
                _ = storageRef.child("user_uploads/images/\(uid)/\(postKey)").put(data, metadata: stillMetaData) { metadata, error in
                    if (error != nil) {
                        
                    } else {
                        let thumbURL = metadata!.downloadURL()!
                        completion(thumbURL.absoluteString)
                    }
                }
            }
        }
    }
    
    private static func generateVideoStill(url:URL) -> UIImage?{
        do {
            let asset = AVAsset(url: url)
            let imgGenerator = AVAssetImageGenerator(asset: asset)
            imgGenerator.appliesPreferredTrackTransform = true
            let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(0, 1), actualTime: nil)
            let image = UIImage(cgImage: cgImage)
            return image
        } catch let error as NSError {
            print("Error generating thumbnail: \(error)")
            return nil
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
                    
                    comments.sort(by: { return $0 < $1 })
                    
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
    
    static func addView(postKey:String) {
        let ref = FIRDatabase.database().reference()
        let uid = mainStore.state.userState.uid
        
        let postRef = ref.child("uploads/\(postKey)/views/\(uid)")
        postRef.setValue([".sv":"timestamp"])
        
    }
    
    static func addComment(postKey:String, comment:String) {
        let ref = FIRDatabase.database().reference()
        let uid = mainStore.state.userState.uid
        
        let postRef = ref.child("uploads/\(postKey)/comments").childByAutoId()
        postRef.setValue([
            "author": uid,
            "text":comment,
            "timestamp":[".sv":"timestamp"]
        ])
    }
    
    
    static func reportItem(item:StoryItem, type:ReportType, showNotification:Bool, completion:@escaping ((_ success:Bool)->())) {
        let ref = FIRDatabase.database().reference()
        let uid = mainStore.state.userState.uid
        let reportRef = ref.child("reports/\(uid)/\(item.getKey())")
        let value: [String: Any] = [
            "type": type.rawValue,
            "timeStamp": [".sv": "timestamp"]
        ]
        reportRef.setValue(value, withCompletionBlock: { error, ref in
            if error == nil {
                if showNotification {
//                    var murmur = Murmur(title: "Report Sent!")
//                    murmur.backgroundColor = accentColor
//                    murmur.titleColor = UIColor.whiteColor()
//                    show(whistle: murmur, action: .Show(3.0))
                    
                }
            } else {
                if showNotification {
//                    var murmur = Murmur(title: "Report failed to send.")
//                    murmur.backgroundColor = errorColor
//                    murmur.titleColor = UIColor.whiteColor()
//                    show(whistle: murmur, action: .Show(3.0))
                }
                completion(false)
            }
        })
    }
    
    static func removeItemFromLocation(item:StoryItem, completion:@escaping (()->())) {
        let ref = FIRDatabase.database().reference()
        let locationRef = ref.child("locations/uploads/\(item.locationKey)/\(item.authorId)/\(item.key)")
        locationRef.removeValue(completionBlock: { error, _locationRef in
            if error == nil {
                let uploadRef = ref.child("uploads/\(item.key)/meta/toLocation")
                uploadRef.setValue(false, withCompletionBlock: { error, _uploadRef in
                    if error == nil {
                        item.toLocation = false
                        dataCache.setObject(item, forKey: "upload-\(item.key)" as NSString)
                        completion()
                    } else {
                        completion()
                    }
                })
            } else {
                completion()
            }
        })
    }
    
    static func removeItemFromStory(item:StoryItem, completion:@escaping (()->())) {
        let ref = FIRDatabase.database().reference()
        let storyRef = ref.child("users/activity/\(item.authorId)/\(item.key)")
        storyRef.removeValue(completionBlock: { error, _locationRef in
            if error == nil {
                let uploadRef = ref.child("uploads/\(item.key)/meta/toStory")
                uploadRef.setValue(false, withCompletionBlock: { error, _uploadRef in
                    if error == nil {
                        item.toStory = false
                        dataCache.setObject(item, forKey: "upload-\(item.key)" as NSString)
                        completion()
                    } else {
                        completion()
                    }
                })
            } else {
                completion()
            }
        })
    }
    
    static func removeItemFromProfile(item:StoryItem, completion:@escaping (()->())) {
        let ref = FIRDatabase.database().reference()
        let storyRef = ref.child("users/uploads/\(item.authorId)/\(item.key)")
        storyRef.removeValue(completionBlock: { error, _locationRef in
            if error == nil {
                let uploadRef = ref.child("uploads/\(item.key)/meta/toProfile")
                uploadRef.setValue(false, withCompletionBlock: { error, _uploadRef in
                    if error == nil {
                        item.toProfile = false
                        dataCache.setObject(item, forKey: "upload-\(item.key)" as NSString)
                        completion()
                    } else {
                        completion()
                    }
                })
            } else {
                completion()
            }
        })
    }
    
    static func deleteItem(item:StoryItem, completion:@escaping (()->())){
        removeItemFromLocation(item: item, completion: {
            removeItemFromStory(item: item, completion: {
                removeItemFromProfile(item: item, completion: completion)
            })
        })
    }

}

enum ReportType:String {
    case Inappropriate = "Inappropriate"
    case Spam          = "Spam"
}
