//
//  Location.swift
//  Lit
//
//  Created by Robert Canton on 2016-07-27.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

//
import CoreLocation

class Location:NSObject, NSCoding {
    
    fileprivate var key:String                    // Key in database
    fileprivate var name:String
    fileprivate var coordinates:CLLocation
    fileprivate var imageURL:String
    fileprivate var address:String
    fileprivate var radius:Double
    
    var phone:String?
    var email:String?
    var website:String?
    var desc:String?
    
    
    fileprivate var distance:Double?
    
    var visitors = [String]()
    fileprivate var postKeys = [String]()

    fileprivate var friendsCount = 0
    
    var imageOnDiskURL:URL?
    
    
    init(key:String, name:String, latitude:Double, longitude: Double, radius: Double, imageURL:String, address:String, phone:String?, email:String?, website:String?, desc:String?)
    {
        self.key          = key
        self.name         = name
        self.coordinates  = CLLocation(latitude: latitude, longitude: longitude)
        self.radius       = radius
        self.imageURL     = imageURL
        self.address      = address
        self.phone        = phone
        self.email        = email
        self.website      = website
        self.desc         = desc
        
    }
    
    required convenience init(coder decoder: NSCoder) {
        
        let key = decoder.decodeObject(forKey: "key") as! String
        let name = decoder.decodeObject(forKey: "name") as! String
        let latitude = decoder.decodeObject(forKey: "latitude") as! Double
        let longitude = decoder.decodeObject(forKey: "longitude") as! Double
        let radius = decoder.decodeObject(forKey: "radius") as! Double
        let imageURL = decoder.decodeObject(forKey: "imageURL") as! String
        let address = decoder.decodeObject(forKey: "address") as! String
        let phone = decoder.decodeObject(forKey: "phone") as? String
        let email = decoder.decodeObject(forKey: "email") as? String
        let website = decoder.decodeObject(forKey: "website") as? String
        let desc = decoder.decodeObject(forKey: "desc") as? String
        
        self.init(key:key, name:name, latitude:latitude, longitude: longitude, radius: radius, imageURL:imageURL, address:address, phone: phone, email: email, website: website, desc: desc)
    }
    
    
    func encode(with coder: NSCoder) {
        coder.encode(key, forKey: "key")
        coder.encode(name, forKey: "name")
        coder.encode(coordinates.coordinate.latitude, forKey: "latitude")
        coder.encode(coordinates.coordinate.longitude, forKey: "longitude")
        coder.encode(radius, forKey: "radius")
        coder.encode(imageURL, forKey: "imageURL")
        coder.encode(address, forKey: "address")
        coder.encode(phone, forKey: "phone")
        coder.encode(email, forKey: "email")
        coder.encode(website, forKey: "website")
        coder.encode(desc, forKey: "desc")
    }
    
    /* Getters */
    
    func getKey() -> String
    {
        return key
    }
    
    func getName()-> String
    {
        return name
    }
    
    func getCoordinates() -> CLLocation
    {
        return coordinates
    }
    
    func getRadius() -> Double {
        return radius
    }
    
    func getImageURL() -> String
    {
        return imageURL
    }
    
    func getAddress() -> String
    {
        return address
    }
    
    func getShortAddress() -> String {
        if let index = address.lowercased().characters.index(of: ",") {
            return address.substring(to: index)
        }
        return address
    }
    
    
    func findVisitor(_ uid:String) -> Int? {
        for i in 0 ..< visitors.count {
            let visitor = visitors[i]
            if visitor == uid {
                return i
            }
        }
        
        return nil
    }
    
    func addVisitor(_ visitor:String) {
        if findVisitor(visitor) == nil{
            visitors.append(visitor)
        }
    }
    
    func removeVisitor(_ _visitor:String) {
        
        if let i = findVisitor(_visitor) {
            visitors.remove(at: i)
        }
    }
    
    func getVisitors() -> [String] {
        return visitors
    }
    
    func getVisitorsCount() -> Int {
        return visitors.count
    }
    
    func getFriendsCount() -> Int {
        return friendsCount
    }
    
    func addPost(_ key:String) {
        postKeys.append(key)
    }
    
    func removePost(_ _key:String) {
        for i in 0 ..< postKeys.count {
            let key = postKeys[i]
            if key == _key {
                postKeys.remove(at: i)
                break
            }
        }
    }
    
    
    func getPostKeys() -> [String] {
        return postKeys
    }
    
    
    func setDistance(_ distance:Double) {
        self.distance = distance
    }
    
    func getDistance() -> Double? {
        return distance
    }
    
    func isActive() -> Bool {
        if distance != nil {
            if distance! < radius / 1000 {
                return true
            }
        }
        return false
    }
    
}
