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
    var conversations = [Conversation]()
    var socialState: SocialState
    var supportedVersion:Bool = false
}

struct UserState {
    var isAuth: Bool = false
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
            locations:LocationsReducer(action, state: state?.locations),
            conversations:ConversationsReducer(action: action, state: state?.conversations),
            socialState: SocialReducer(action: action, state: state?.socialState),
            supportedVersion: SupportedVersionReducer(action, state: state?.supportedVersion)
        )
    }
}

func SupportedVersionReducer(_ action: Action, state:Bool?) -> Bool {
    var state = state ?? false
    
    switch action {
    case _ as SupportedVersion:
        state = true
        break
    default:
        break
    }
    return state
}
