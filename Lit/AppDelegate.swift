//
//  AppDelegate.swift
//  Lit
//
//  Created by Robert Canton on 2017-01-30.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit
import ReSwift
import Firebase
import UserNotifications
import AVFoundation
import GoogleMaps
import GooglePlaces

let mainStore = Store<AppState>(
    reducer: AppReducer(),
    state: nil
)

let accentColor = UIColor(red: 0, green: 128/255, blue: 1, alpha: 1)
let positiveColor = UIColor(red: 0, green: 128/255, blue: 1, alpha: 1)
let errorColor  = UIColor(red: 1, green: 80/255, blue: 50/255, alpha: 1)

let usernameLengthLimit = 16

let selectedColor:UIColor = UIColor(white: 0.15, alpha: 1.0)

let inRangeDistance = 0.15

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)

        FIRApp.configure()
        
        GMSServices.provideAPIKey("AIzaSyCQJh5Rz0hDTh0CM9SEmTPlX8TymeQ4po0")
        GMSPlacesClient.provideAPIKey("AIzaSyCQJh5Rz0hDTh0CM9SEmTPlX8TymeQ4po0")
        
        let colorView = UIView()
        colorView.backgroundColor = selectedColor
        UITableViewCell.appearance().selectedBackgroundView = colorView
        
        let cancelButtonAttributes: NSDictionary = [NSForegroundColorAttributeName: UIColor.white]
        UIBarButtonItem.appearance().setTitleTextAttributes(cancelButtonAttributes as? [String : AnyObject], for: UIControlState.normal)
        UITabBar.appearance().tintColor = UIColor.white
        
        UIApplication.shared.setStatusBarStyle(UIStatusBarStyle.lightContent, animated: true)
        
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: .mixWithOthers)
            //print("AVAudioSession Category Playback OK")
            do {
                try AVAudioSession.sharedInstance().setActive(true)
                //print("AVAudioSession is Active")
            } catch _ as NSError {
                //print(error.localizedDescription)
            }
        } catch _ as NSError {
            //print(error.localizedDescription)
        }
        
        return true
    }
    

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {

    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        FBSDKAppEvents.activateApp()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        clearTmpDirectory()
    }
    
    func clearTmpDirectory() {
        print("Clear temp directory")
        do {
            let tmpDirectory = try FileManager.default.contentsOfDirectory(atPath: NSTemporaryDirectory())
            try tmpDirectory.forEach { file in
                let path = String.init(format: "%@%@", NSTemporaryDirectory(), file)
                try FileManager.default.removeItem(atPath: path)
            }
        } catch {
            print(error)
        }
    }


}

