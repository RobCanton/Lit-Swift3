//
//  LocationService.swift
//  Lit
//
//  Created by Robert Canton on 2017-01-31.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import ReSwift
import CoreLocation
import Firebase


class LocationService {
    
    static fileprivate let locationsCache = NSCache<NSString, AnyObject>()
    
    static fileprivate let ref = FIRDatabase.database().reference()
    
    static var shouldCalculateNearbyArea:Bool = true
    
    static var radius = 50
    
    static func requestNearbyLocations(_ latitude:Double, longitude:Double) {
        
        let uid = mainStore.state.userState.uid
        let apiRef = ref.child("api/requests/location_updates/\(uid)")
        apiRef.setValue([
            "lat": latitude,
            "lon": longitude,
            "rad": radius
            ])
        
    }
    
    static func handleLocationsResponse(_ locationKeys:[String:Double]) {
        getLocations(locationKeys, completion:  { locations in
            Listeners.stopListeningToLocations()
            mainStore.dispatch(LocationsRetrieved(locations: locations))
            Listeners.startListeningToLocations()
        })
    }
    
    
    static func getLocations(_ locationDict:[String:Double], completion: @escaping (_ locations: [Location]) -> ()) {
        var locations = [Location]()
        var count = 0
        
        for (key, dist) in locationDict {
            getLocation(key, completion: { location in
                if location != nil {
                    location!.setDistance(dist)
                    locations.append(location!)
                }
                
                count += 1
                
                if count >= locationDict.count {
                    DispatchQueue.main.async {
                        completion(locations)
                    }
                }
            })
        }
    }
    
    static func getLocation(_ locationKey:String, completion: @escaping (_ location:Location?)->()) {
        if let cachedData = locationsCache.object(forKey: locationKey as NSString) as? Location {
            return completion(cachedData)
        }
        
        let locRef = ref.child("locations/info/basic/\(locationKey)")
        
        locRef.observeSingleEvent(of: .value, with: { snapshot in
            var location:Location?
            
            if snapshot.exists() {
                let dict         = snapshot.value as! [String:AnyObject]
                let name         = dict["name"] as! String
                let coordinates  = dict["coordinates"] as! [String:Double]
                let lat          = coordinates["latitude"]!
                let lon          = coordinates["longitude"]!
                let imageURL     = dict["imageURL"] as! String
                let address      = dict["address"] as! String
                
                location = Location(key: locationKey, name: name, latitude: lat, longitude: lon, imageURL: imageURL, address: address,
                                    phone: nil, email: nil, website: nil, desc: nil)
                locationsCache.setObject(location!, forKey: locationKey as NSString)
            }
            
            completion(location)
        })
    }
    
    static func getLocationDetails(_ location:Location, completion: @escaping (_ location:Location?)->()) {
        if location.phone != nil && location.website != nil {
            completion(location)
        }
        
        let locRef = ref.child("locations/info/details/\(location.getKey())")
        
        locRef.observeSingleEvent(of: .value, with: { snapshot in
            
            if snapshot.exists() {
            
                let dict         = snapshot.value as! [String:String]
                location.phone   = dict["phone"]
                location.email   = dict["email"]
                location.website = dict["website"]
                location.desc    = dict["description"]

                let key = location.getKey()
                locationsCache.removeObject(forKey: key as NSString)
                locationsCache.setObject(location, forKey: key as NSString)
            }
            
            completion(location)
        })
    }
    
    static func getUserRadiusSetting() {
        let uid = mainStore.state.userState.uid
        let settingsRef = ref.child("users/settings/\(uid)/search_radius")
        settingsRef.observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists() {
                radius = snapshot.value! as! Int
                print("User radius setting: \(radius)")
            }
        })
    }

        
}
