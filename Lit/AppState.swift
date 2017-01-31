//
//  AppState.swift
//  Lit
//
//  Created by Robert Canton on 2017-01-30.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import ReSwift

struct AppState: StateType {
    var userState: UserState
    var locations:[Location]

}

struct UserState {
    var isAuth: Bool = false
    var supportedVersion: Bool = false
    var uid: String = ""
    var user:User?
}

struct SocialState {
    var followers = Tree<String>()
    var following = Tree<String>()
}

struct AppReducer: Reducer {
    typealias ReducerStateType = AppState

    
    func handleAction(action: Action, state: AppState?) -> AppState {
        
        return AppState(
            userState: UserStateReducer(action, state: state?.userState),
            locations:LocationsReducer(action, state: state?.locations)
        )
    }
}


func UserStateReducer(_ action: Action, state: UserState?) -> UserState {
    var state = state ?? UserState()
    switch action {
    case _ as UserIsAuthenticated:
        let a = action as! UserIsAuthenticated
        state.isAuth = true
        state.uid = a.user.getUserId()
        state.user = a.user
        break
        
    case _ as UserIsUnauthenticated:
        //Listeners.stopListeningToAll()
        state = UserState()
        break
        
    case _ as UpdateUser:
        let a = action as! UpdateUser
        state.user = a.user
        break
    case _ as UpdateProfileImageURL:
        let a = action as! UpdateProfileImageURL
        state.user!.setImageURLS(a.largeImageURL, smallImageURL: a.smallImageURL)
        break
        
    case _ as SupportedVersion:
        state.supportedVersion = true
        break
    default:
        break
    }
    
    return state
}


struct UserIsAuthenticated: Action {
    let user: User
}

struct UserIsUnauthenticated: Action {}

struct UpdateUser: Action {
    let user: User
}


struct UpdateProfileImageURL: Action {
    let largeImageURL: String
    let smallImageURL: String
}

struct SupportedVersion: Action {}




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
