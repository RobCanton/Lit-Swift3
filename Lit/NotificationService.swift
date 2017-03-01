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

class NotificationService: NSObject, CLLocationManagerDelegate, UNUserNotificationCenterDelegate {
    
    static let shared: NotificationService = {
        let instance = NotificationService()
        return instance
    }()
    
    fileprivate var badgeNumber = 0
    fileprivate var messageBadge = 0
    fileprivate var activityBadge = 0
    fileprivate var socialBadge = 0
    
    
    var followPromptShown = false
    var messagePromptShown = false
    
    
    
    
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
    
    func registerForUserNotifications() {
        
        if notificationsEnabled() { return }
        if #available(iOS 10.0, *) {
            let center  = UNUserNotificationCenter.current()
            center.delegate = self
            center.requestAuthorization(options: [.sound, .alert, .badge]) { (granted, error) in
                if error == nil{
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
        else {
            UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.sound, .alert, .badge], categories: nil))
            UIApplication.shared.registerForRemoteNotifications()
        }

    }
    
    func notificationsEnabled() -> Bool {
        if #available(iOS 10.0, *) {
            let isRegisteredForRemoteNotifications = UIApplication.shared.isRegisteredForRemoteNotifications

            if isRegisteredForRemoteNotifications {
                return true
            } else {
                return false
            }
        } else {
            let notificationType = UIApplication.shared.currentUserNotificationSettings!.types
            if notificationType == [] {
                return false
            } else {
                return true
            }
        }
    }
    
    
    //Called when a notification is delivered to a foreground app.
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        //completionHandler([.alert, .badge, .sound])
    }
    
    //Called to let your app know which action was selected by the user for a given notification.
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        completionHandler()
    }
    
    

}

