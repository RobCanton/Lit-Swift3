//
//  NotificationService.swift
//  Lit
//
//  Created by Robert Canton on 2017-02-15.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit
import UserNotifications
import Firebase
import ReSwift

class NotificationService: NSObject, CLLocationManagerDelegate {
    
    static let shared: NotificationService = {
        let instance = NotificationService()
        return instance
    }()
    
    fileprivate var badgeNumber = 0
    fileprivate var messageBadge = 0
    fileprivate var activityBadge = 0
    fileprivate var socialBadge = 0
    
    
    
    override init() {
        super.init()
        
    }
    
    func setMessageBadgeNumber(_ number:Int) {
        messageBadge = number
        setNotificationBadges()
    }
    
    func setNotificationBadges() {
        let total = messageBadge + activityBadge + socialBadge
        
        UIApplication.shared.applicationIconBadgeNumber = total
        let uid = mainStore.state.userState.uid
        let ref = FIRDatabase.database().reference().child("users/notifications/\(uid)/badge")
        ref.setValue(total)
        
        
    }

}

