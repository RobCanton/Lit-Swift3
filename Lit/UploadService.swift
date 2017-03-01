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
    
    static func writeImageToFile(withKey key:String, image:UIImage) {
        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory().appending("upload_image-\(key).jpg"))//uploadsFileURL.appendingPathComponent("\(key).jpg")
        if let jpgData = UIImageJPEGRepresentation(image, 1.0) {
            try! jpgData.write(to: fileURL, options: [.atomic])
        }
    }
    
    static func readImageFromFile(withKey key:String) -> UIImage? {
        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory().appending("upload_image-\(key).jpg"))
        return UIImage(contentsOfFile: fileURL.path)
    }
    
    fileprivate static func downloadImage(withUrl url:URL, completion: @escaping (_ image:UIImage?)->()) {
        
        URLSession.shared.dataTask(with: url, completionHandler:
            { (data, response, error) in
                if error != nil {
                    if error?._code == -999 {
                        return
                    }
                    return completion(nil)
                }
                
                DispatchQueue.main.async {
                    
                    let image = UIImage(data: data!)
                    return completion(image!)
                }
                
        }).resume()
    }
    
    static func retrieveImage(byKey key: String, withUrl url:URL, completion: @escaping (_ image:UIImage?, _ fromFile:Bool)->()) {
        if let image = readImageFromFile(withKey: key) {
            completion(image, true)
        } else {
            downloadImage(withUrl: url, completion: { image in
                if image != nil {
                    writeImageToFile(withKey: key, image: image!)
                }
                completion(image, false)
            })
        }
    }
    
    static func writeVideoToFile(withKey key:String, video:Data) -> URL {
        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory().appending("upload_video-\(key).mp4"))
        try! video.write(to: fileURL, options: [.atomic])
        return fileURL
    }
    
    static func readVideoFromFile(withKey key:String) -> URL? {
        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory().appending("upload_video-\(key).mp4"))
        do {
            let _ = try Data(contentsOf: fileURL)
            
            return fileURL
        } catch let error as Error{
            print("ERROR: \(error.localizedDescription)")
            return nil
        }
    }
    
    
    fileprivate static func downloadVideo(byAuthor author:String, withKey key:String, completion: @escaping (_ data:Data?)->()) {
        let videoRef = FIRStorage.storage().reference().child("user_uploads/videos/\(author)/\(key)")
        
        // Download in memory with a maximum allowed size of 2MB (2 * 1024 * 1024 bytes)
        videoRef.data(withMaxSize: 2 * 1024 * 1024) { (data, error) -> Void in
            if (error != nil) {
                print("Error - \(error!.localizedDescription)")
                completion(nil)
            } else {
                return completion(data!)
            }
        }
    }
    
    static func retrieveVideo(byAuthor author:String, withKey key:String, completion: @escaping (_ videoUrl:URL?, _ fromFile:Bool)->()) {
        if let data = readVideoFromFile(withKey: key) {
            completion(data, true)
        } else {
            downloadVideo(byAuthor: author, withKey: key, completion: { data in
                if data != nil {
                    let url = writeVideoToFile(withKey: key, video: data!)
                    completion(url, false)
                }
                completion(nil, false)
            })
        }
    }

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
            uploadingMurmer.font = UIFont.systemFont(ofSize: 12.0, weight: UIFontWeightSemibold)
            show(whistle: uploadingMurmer, action: .show(60.0))
            
            // Upload file and metadata to the object
            let storageRef = FIRStorage.storage().reference()
            let uploadTask = storageRef.child("user_uploads/images/\(uid)/\(postKey)").put(data, metadata: metadata) { metadata, error in
                
                if (error != nil) {
                    // HANDLE ERROR
                    hide()
                    showFailureNotification("Error uploading image.")
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
                            showSuccessNotification("Image uploaded!")
                        } else {
                            showFailureNotification("Error uploading image.")
                        }
                    })
                    
                }
            }
            completion()
        }
        
    }
    
    static func uploadVideo(upload:Upload, completion:(_ success:Bool)->()){
        
        //If upload has no destination do not upload it
        if !upload.toProfile && !upload.toStory && upload.locationKey == "" { return }
        
        if upload.videoURL == nil { return }
        
        let uid = mainStore.state.userState.uid
        let url = upload.videoURL!
        
        let ref = FIRDatabase.database().reference()
        let dataRef = ref.child("uploads").childByAutoId()
        let postKey = dataRef.key
        
        var uploadingMurmer = Murmur(title: "Uploading...")
        uploadingMurmer.backgroundColor = UIColor(white: 0.04, alpha: 1.0)
        uploadingMurmer.titleColor = UIColor.lightGray
        uploadingMurmer.font = UIFont.systemFont(ofSize: 12.0, weight: UIFontWeightSemibold)
        show(whistle: uploadingMurmer, action: .show(60.0))
        completion(true)
        
        uploadVideoStill(url: url, postKey: postKey, completion: { thumbURL in
            
            let data = NSData(contentsOf: url)
            
            let metadata = FIRStorageMetadata()
            let contentTypeStr = "video/mp4"
            let playerItem = AVAsset(url: url)
            let length = CMTimeGetSeconds(playerItem.duration)
            metadata.contentType = contentTypeStr
            
            let storageRef = FIRStorage.storage().reference()
            let uploadTask = storageRef.child("user_uploads/videos/\(uid)/\(postKey)").put(data as! Data, metadata: metadata) { metadata, error in
                if (error != nil) {
                    // HANDLE ERROR
                    hide()
                    showFailureNotification("Error uploading video.")
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
                        "videoURL": downloadURL!.absoluteString,
                        "url": thumbURL,
                        "contentType": contentTypeStr,
                        "dateCreated": [".sv": "timestamp"],
                        "length": length
                    ] as [String:Any]
                    dataRef.child("meta").setValue(obj, withCompletionBlock: { error, _ in
                        hide()
                        if error == nil {
                            showSuccessNotification("Video uploaded!")
                        } else {
                            showFailureNotification("Error uploading video.")
                        }
                    })
                }
            }
            
        })
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
    
    static func compressVideo(inputURL: URL, outputURL: URL, handler:@escaping (_ session: AVAssetExportSession)-> Void) {
        let urlAsset = AVURLAsset(url: inputURL, options: nil)
        if let exportSession = AVAssetExportSession(asset: urlAsset, presetName: AVAssetExportPresetMediumQuality) {
            exportSession.outputURL = outputURL
            exportSession.outputFileType = AVFileTypeMPEG4
            exportSession.shouldOptimizeForNetworkUse = true
            
            exportSession.exportAsynchronously { () -> Void in
                handler(exportSession)
            }
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
                    let caption = meta["caption"] as! String
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
                    var likes = [String:Double]()
                    if snapshot.hasChild("likes") {
                        likes = dict["likes"] as! [String:Double]
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
                    
                    item = StoryItem(key: key, authorId: authorId, caption: caption, locationKey: locationKey, downloadUrl: downloadUrl,videoURL: videoURL, contentType: contentType, dateCreated: dateCreated, length: length, toProfile: toProfile, toStory: toStory, toLocation: toLocation, viewers: viewers,likes:likes, comments: comments)
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
    
    static func addLike(post:StoryItem) {

        let ref = FIRDatabase.database().reference()
        let uid = mainStore.state.userState.uid
        
        let postRef = ref.child("api/requests/like").childByAutoId()
        postRef.setValue([
            "sender": uid,
            "recipient": post.getAuthorId(),
            "postKey": post.getKey(),
            "isVideo": post.getContentType() == .video,
            "timestamp":[".sv":"timestamp"]
        ])
    }
    
    static func removeLike(postKey:String) {
        let ref = FIRDatabase.database().reference()
        let uid = mainStore.state.userState.uid
        
        let postRef = ref.child("uploads/\(postKey)/likes/\(uid)")
        postRef.removeValue()
    }
    
    static func addComment(post:StoryItem, comment:String) {
        if comment == "" { return }
        let ref = FIRDatabase.database().reference()
        let uid = mainStore.state.userState.uid
        
        let postRef = ref.child("api/requests/comment").childByAutoId()
        postRef.setValue([
            "sender": uid,
            "recipient": post.getAuthorId(),
            "postKey": post.getKey(),
            "text":comment,
            "isVideo": post.getContentType() == .video,
            "timestamp":[".sv":"timestamp"]
        ])
    }
    
    static func editCaption(postKey:String, caption:String) {
        let ref = FIRDatabase.database().reference()
        let uploadRef = ref.child("uploads/\(postKey)/meta/caption")
        uploadRef.setValue(caption)
    }
    
    
    static func reportItem(item:StoryItem, type:ReportType, showNotification:Bool, completion:@escaping ((_ success:Bool)->())) {
        let ref = FIRDatabase.database().reference()
        let uid = mainStore.state.userState.uid
        let reportRef = ref.child("reports/\(uid):\(item.getKey())")
        let value: [String: Any] = [
            "sender": uid,
            "itemKey": item.getKey(),
            "type": type.rawValue,
            "timestamp": [".sv": "timestamp"]
        ]
        reportRef.setValue(value, withCompletionBlock: { error, ref in
            completion(error == nil )
        })
    }
    
    static func removeItemFromLocation(item:StoryItem, completion:@escaping (()->())) {
        var type = "image"
        if item.contentType == .video {
            type = "video"
        }
        
        let ref = FIRDatabase.database().reference()
        let updates:[String:Any?] = [
            "locations/uploads/\(item.locationKey)/\(item.authorId)/\(item.key)": nil,
            "uploads/\(item.key)/meta/toLocation": false
        ]
        
        ref.updateChildValues(updates, withCompletionBlock: { error, ref in
            if error == nil {
                item.toLocation = false
                dataCache.setObject(item, forKey: "upload-\(item.key)" as NSString)
                
                var type = "Image"
                if item.contentType == .video {
                    type = "Video"
                }
                
                showSuccessNotification("\(type) removed!")
                completion()
            } else {
                var type = "image"
                if item.contentType == .video {
                    type = "video"
                }
                
                showFailureNotification("Unable to remove \(type).")
                completion()
            }
        })
    }
    
    static func removeItemFromStory(item:StoryItem, completion:@escaping (()->())) {
        var type = "image"
        if item.contentType == .video {
            type = "video"
        }
        
        let ref = FIRDatabase.database().reference()
        let updates:[String:Any?] = [
            "users/activity/\(item.authorId)/\(item.key)": nil,
            "uploads/\(item.key)/meta/toStory": false
        ]
        
        ref.updateChildValues(updates, withCompletionBlock: { error, ref in
            if error == nil {
                item.toStory = false
                dataCache.setObject(item, forKey: "upload-\(item.key)" as NSString)
                
                var type = "Image"
                if item.contentType == .video {
                    type = "Video"
                }
                
                showSuccessNotification("\(type) removed!")
                completion()
            } else {
                var type = "image"
                if item.contentType == .video {
                    type = "video"
                }
                
                showFailureNotification("Unable to remove \(type).")
                completion()
            }
        })
    }
    
    static func removeItemFromProfile(item:StoryItem, completion:@escaping (()->())) {
        
        let ref = FIRDatabase.database().reference()
        let updates:[String:Any?] = [
            "users/uploads/\(item.authorId)/\(item.key)": nil,
            "uploads/\(item.key)/meta/toProfile": false
        ]
        
        ref.updateChildValues(updates, withCompletionBlock: { error, ref in
            if error == nil {
                item.toProfile = false
                dataCache.setObject(item, forKey: "upload-\(item.key)" as NSString)
                
                var type = "Image"
                if item.contentType == .video {
                    type = "Video"
                }
                
                showSuccessNotification("\(type) removed!")
                completion()
            } else {
                var type = "image"
                if item.contentType == .video {
                    type = "video"
                }
                
                showFailureNotification("Unable to remove \(type).")
                completion()
            }
        })
    }
    
    static func deleteItem(item:StoryItem, completion:@escaping (()->())){
        
        let ref = FIRDatabase.database().reference()
        let updates:[String:Any?] = [
            "users/uploads/\(item.authorId)/\(item.key)": nil,
            "uploads/\(item.key)/meta/toProfile": false,
            "users/activity/\(item.authorId)/\(item.key)": nil,
            "uploads/\(item.key)/meta/toStory": false,
            "locations/uploads/\(item.locationKey)/\(item.authorId)/\(item.key)": nil,
            "uploads/\(item.key)/meta/toLocation": false
        ]
        
        ref.updateChildValues(updates, withCompletionBlock: { error, ref in
            if error == nil {
                item.toProfile = false
                item.toLocation = false
                item.toStory = false
                dataCache.setObject(item, forKey: "upload-\(item.key)" as NSString)
                
                var type = "Image"
                if item.contentType == .video {
                    type = "Video"
                }
                
                showSuccessNotification("\(type) deleted!")
                completion()
            } else {
                
                var type = "image"
                if item.contentType == .video {
                    type = "video"
                }
                
                showFailureNotification("Unable to delete \(type).")
                completion()
            }
        })
    }
    
    private static func showSuccessNotification(_ message:String) {
        var murmur = Murmur(title: message)
        murmur.backgroundColor = accentColor
        murmur.titleColor = UIColor.white
        murmur.font = UIFont.systemFont(ofSize: 12.0, weight: UIFontWeightSemibold)
        show(whistle: murmur, action: .show(2.0))
    }
    
    private static func showFailureNotification(_ message:String) {
        var murmur = Murmur(title: message)
        murmur.backgroundColor = errorColor
        murmur.titleColor = UIColor.white
        murmur.font = UIFont.systemFont(ofSize: 12.0, weight: UIFontWeightSemibold)
        show(whistle: murmur, action: .show(3.0))
    }

}

enum ReportType:String {
    case Inappropriate = "InappropriateContent"
    case Spam          = "SpamContent"
    case InappropriateProfile = "InappropriateProfile"
    case Harassment = "Harassment"
    case Bot = "Bot"
    case Other = "Other"
}
