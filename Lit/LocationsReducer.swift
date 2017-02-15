//
//  LocationsReducer.swift
//  Lit
//
//  Created by Robert Canton on 2017-02-01.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import ReSwift


func LocationsReducer(_ action: Action, state:[Location]?) -> [Location] {
    var state = state ?? [Location]()
    
    switch action {
    case _ as LocationsRetrieved:
        let a = action as! LocationsRetrieved
        state = a.locations
        break
    case _ as SetVisitorsForLocation:
        let a = action as! SetVisitorsForLocation
        state[a.locationIndex].visitors = a.visitors
        break
    case _ as AddPostToLocation:
        let a = action as! AddPostToLocation
        state[a.locationIndex].addPost(a.key)
        break
    case _ as RemovePostFromLocation:
        let a = action as! RemovePostFromLocation
        state[a.locationIndex].removePost(a.key)
        break
    case _ as ClearLocations:
        state = [Location]()
    default:
        break
    }
    return state
}


struct LocationsRetrieved: Action {
    let locations: [Location]
}

struct SetActiveLocation: Action {
    let locationKey: String
}


struct SetVisitorsForLocation: Action {
    let locationIndex:Int
    let visitors:[String]
}

struct AddPostToLocation: Action {
    let locationIndex:Int
    let key:String
}

struct RemovePostFromLocation: Action {
    let locationIndex:Int
    let key:String
}


struct SetLocations: Action {
    let locations: [String]
}

/* Destructive Actions */

struct ClearLocations: Action {}

struct SetActiveLocations: Action {
    let indexes:[Int]
}

struct ClearActiveLocations: Action {}
