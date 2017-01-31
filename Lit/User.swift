//
//  User.swift
//  Lit
//
//  Created by Robert Canton on 2016-08-10.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import Foundation


class Comment: NSObject {
    
    fileprivate var key:String                    // Key in database
    fileprivate var author:String
    fileprivate var text:String
    fileprivate var date:Date
    
    
    
    init(key:String, author:String, text:String, timestamp:Double)
    {
        self.key          = key
        self.author       = author
        self.text         = text
        self.date    = Date(timeIntervalSince1970: timestamp/1000)
    }
    
    /* Getters */
    
    func getKey() -> String
    {
        return key
    }
    
    func getAuthor()-> String
    {
        return author
    }
    
    func getText() -> String
    {
        return text
    }
    
    func getDate() -> Date
    {
        return date
    }
    
}


class User:NSObject, NSCoding {
    var uid: String
    var displayName: String
    var name: String?
    var imageURL: String
    var largeImageURL: String?
    var bio: String?
    
    init(uid:String, displayName:String, name:String?, imageURL: String, largeImageURL: String?, bio: String?)
    {
        self.uid           = uid
        self.displayName   = displayName
        self.name          = name
        self.imageURL      = imageURL
        self.largeImageURL = largeImageURL
        self.bio           = bio
    }
    
    required convenience init(coder decoder: NSCoder) {
        
        let uid = decoder.decodeObject(forKey: "uid") as! String
        let displayName = decoder.decodeObject(forKey: "displayName") as! String
        let name = decoder.decodeObject(forKey: "name") as? String
        let imageURL = decoder.decodeObject(forKey: "imageURL") as! String
        let largeImageURL = decoder.decodeObject(forKey: "largeImageURL") as? String
        let bio = decoder.decodeObject(forKey: "bio") as? String

        self.init(uid: uid, displayName: displayName, name: name, imageURL: imageURL, largeImageURL: largeImageURL, bio: bio)

    }

    
    func encode(with coder: NSCoder) {
        coder.encode(uid, forKey: "uid")
        coder.encode(displayName, forKey: "displayName")
        coder.encode(name, forKey: "name")
        coder.encode(imageURL, forKey: "imageURL")
        coder.encode(largeImageURL, forKey: "largeImageURL")
        coder.encode(bio, forKey: "bio")
    }
    

    
    func getUserId() -> String {
        return uid
    }
    
    func getDisplayName() -> String {
        return displayName
    }
    
    func getName() -> String? {
        return name
    }
    
    func getImageUrl() -> String {
        return imageURL
    }
    
    func setImageURLS(_ largeImageURL:String, smallImageURL:String) {
        self.largeImageURL = largeImageURL
        self.imageURL = smallImageURL
    }
    
}
