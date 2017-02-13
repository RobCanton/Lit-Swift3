//
//  StoryItem.swift
//  Lit
//
//  Created by Robert Canton on 2016-08-08.
//  Copyright © 2016 Robert Canton. All rights reserved.
//
import Foundation
import UIKit
import AVFoundation

protocol ItemDelegate {
    func itemDownloaded()
}

enum ContentType:Int {
    case image = 1
    case video = 2
    case invalid =  0
}


class StoryItem: NSObject, NSCoding {
    
    var key:String                    // Key in database
    var authorId:String
    var caption:String
    var locationKey:String
    var downloadUrl:URL
    var videoURL:URL?
    var contentType:ContentType
    var dateCreated: Date
    var length: Double
    
    var toProfile:Bool
    var toStory:Bool
    var toLocation:Bool
    
    var viewers:[String:Double]
    var likes:[String:Double]
    var comments:[Comment]
    
    var delegate:ItemDelegate?

    dynamic var image: UIImage?
    dynamic var videoFilePath: URL?
    dynamic var videoData:Data?
    
    init(key: String, authorId: String, caption:String, locationKey:String, downloadUrl: URL, videoURL:URL?, contentType: ContentType, dateCreated: Double, length: Double,
         toProfile: Bool, toStory: Bool, toLocation:Bool, viewers:[String:Double], likes:[String:Double], comments: [Comment])
    {
        
        self.key          = key
        self.authorId     = authorId
        self.caption      = caption
        self.locationKey  = locationKey
        self.downloadUrl  = downloadUrl
        self.videoURL     = videoURL
        self.contentType  = contentType
        self.dateCreated  = Date(timeIntervalSince1970: dateCreated/1000) as Date
        self.length       = length
        self.toProfile    = toProfile
        self.toStory      = toStory
        self.toLocation   = toLocation
        self.viewers      = viewers
        self.likes        = likes
        self.comments     = comments

    }
    
    required convenience init(coder decoder: NSCoder) {
        
        let key         = decoder.decodeObject(forKey: "key") as! String
        let authorId    = decoder.decodeObject(forKey: "authorId") as! String
        let caption     = decoder.decodeObject(forKey: "caption") as! String
        let locationKey = decoder.decodeObject(forKey: "imageUrl") as! String
        let downloadUrl = decoder.decodeObject(forKey: "downloadUrl") as! URL
        let ctInt       = decoder.decodeObject(forKey: "contentType") as! Int
        let dateCreated = decoder.decodeObject(forKey: "dateCreated") as! Double
        let length      = decoder.decodeObject(forKey: "length") as! Double
        let videoURL    = decoder.decodeObject(forKey: "videoURL") as? URL
        let toProfile   = decoder.decodeBool(forKey: "toProfile")
        let toStory     = decoder.decodeBool(forKey: "toStory")
        let toLocation  = decoder.decodeBool(forKey: "toLocation")
        
        var viewers = [String:Double]()
        if let _viewers = decoder.decodeObject(forKey: "viewers") as? [String:Double] {
            viewers = _viewers
        }
        
        var likes = [String:Double]()
        if let _likes = decoder.decodeObject(forKey: "likes") as? [String:Double] {
            likes = _likes
        }
        
        var comments = [Comment]()
        if let _comments = decoder.decodeObject(forKey: "comments") as? [Comment] {
            comments = _comments
        }
        
        var contentType:ContentType = .invalid
        switch ctInt {
        case 1:
            contentType = .image
            break
        case 2:
            contentType = .video
            break
        default:
            break
        }
        
        self.init(key: key, authorId: authorId, caption: caption, locationKey:locationKey, downloadUrl: downloadUrl, videoURL: videoURL, contentType: contentType, dateCreated: dateCreated, length: length, toProfile: toProfile, toStory: toStory, toLocation: toLocation, viewers: viewers, likes: likes, comments: comments)
    }
    
    
    func encode(with coder: NSCoder) {
        coder.encode(key, forKey: "key")
        coder.encode(authorId, forKey: "authorId")
        coder.encode(caption, forKey: "caption")
        coder.encode(downloadUrl, forKey: "downloadUrl")
        coder.encode(contentType.rawValue, forKey: "contentType")
        coder.encode(dateCreated, forKey: "dateCreated")
        coder.encode(length, forKey: "length")
        coder.encode(toProfile, forKey: "toProfile")
        coder.encode(toStory, forKey: "toStory")
        coder.encode(toLocation, forKey: "toLocation")
        coder.encode(viewers, forKey: "viewers")
        coder.encode(likes, forKey: "likes")
        coder.encode(comments, forKey: "comments")
        if videoURL != nil {
            coder.encode(videoURL!, forKey: "videoURL")
        }
    }
    
    func getKey() -> String {
        return key
    }
    
    func getAuthorId() -> String {
        return authorId
    }
    
    func getLocationKey() -> String {
        return locationKey
    }
    
    func getDownloadUrl() -> URL {
        return downloadUrl
    }
    
    func getVideoURL() -> URL? {
        return videoURL
    }
    
    func getContentType() -> ContentType? {
        return contentType
    }
    
    func getDateCreated() -> Date? {
        return dateCreated
    }
    
    func getLength() -> Double {
        return length
    }
    
    func needsDownload() -> Bool{
        if contentType == .image {
            if image != nil {
                return false
            }
            if let savedImage = UploadService.readImageFromFile(withKey: key) {
                image = savedImage
                return false
            }
        }
        
        if contentType == .video {
            if let _ = UploadService.readVideoFromFile(withKey: key) {
                return false
            }
        }  
        return true
    }
    
    func download() {
//        if !needsDownload() {
//            self.delegate?.itemDownloaded()
//            return
//        }
        
        UploadService.retrieveImage(byKey: key, withUrl: downloadUrl, completion: { image, fromFile in
            self.image = image
            if self.contentType == .image {
                self.delegate?.itemDownloaded()
            } else if self.contentType == .video {
                if let _ = UploadService.readVideoFromFile(withKey: self.key) {
                    self.delegate?.itemDownloaded()
                } else {
                    UploadService.retrieveVideo(byAuthor: self.authorId, withKey: self.key, completion: { data in
                        self.delegate?.itemDownloaded()
                    })
                }
                
                
            }
        })
    }
    
    func hasViewed() -> Bool{
        return viewers[mainStore.state.userState.uid] != nil
    }
    
    func addView(_ uid:String) {
        self.viewers[uid] = 0
        cache()
    }
    
    func addComment(_ comment:Comment) {
        for _comment in comments {
            if _comment.getKey() == comment.getKey() { return }
        }
        
        self.comments.append(comment)
        cache()
    }
    
    
    
    func addLike(_ uid:String) {
       self.likes[uid] = 0
        cache()
    }
    
    func removeLike(_ uid:String) {
        self.likes[uid] = nil
        cache()
    }
    
    func getLikesList() -> [String] {
        var list = [String]()
        for (uid, _) in likes {
            list.append(uid)
        }
        return list
    }
    
    func getViewsList() -> [String] {
        var list = [String]()
        for (uid, _) in viewers {
            list.append(uid)
        }
        return list
    }
    
    func editCaption(caption:String) {
        self.caption = caption
        cache()
    }
    
    func cache() {
        dataCache.removeObject(forKey: "upload-\(key)" as NSString)
        dataCache.setObject(self, forKey: "upload-\(key)" as NSString)
    }
    
    func postPoints() -> Int {
        var count = 0
        if toProfile { count += 1 }
        if toStory { count += 1 }
        if toLocation { count += 1 }
        return count
    }
    
}

func < (lhs: StoryItem, rhs: StoryItem) -> Bool {
    return lhs.dateCreated.compare(rhs.dateCreated) == .orderedAscending
}

func > (lhs: StoryItem, rhs: StoryItem) -> Bool {
    return lhs.dateCreated.compare(rhs.dateCreated) == .orderedDescending
}

func == (lhs: StoryItem, rhs: StoryItem) -> Bool {
    return lhs.dateCreated.compare(rhs.dateCreated) == .orderedSame
}
