//
//  MasterTabBarController.swift
//  Lit
//
//  Created by Robert Canton on 2017-01-31.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import UIKit
import ReSwift
import CoreLocation
import Firebase
import NVActivityIndicatorView
import SwiftMessages
import UserNotifications
import Whisper

class MasterTabBarController: UITabBarController, StoreSubscriber, UITabBarControllerDelegate, GPSServiceDelegate {
    typealias StoreSubscriberStateType = AppState

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        _center = tabBar.center
        _hiddenCenter = CGPoint(x: _center.x, y: _center.y * 2)
        
        visibleFrame = tabBar.frame
        hiddenFrame = CGRect(x: visibleFrame.origin.x, y: visibleFrame.origin.y, width: visibleFrame.width, height: 0)
        
        visibleViewFrame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height )
        
        delegate = self
        tabBarController?.delegate = self

        tabBar.isTranslucent = false
        tabBar.backgroundColor = UIColor.black
        self.tabBar.setValue(true, forKey: "_hidesShadow")
        
        GPSService.sharedInstance.delegate = self
        GPSService.sharedInstance.startUpdatingLocation()
        
        self.setupMiddleButton()
    }
    
    var authListener: FIRAuthStateDidChangeListenerHandle?
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        mainStore.subscribe(self)
        
        authListener = FIRAuth.auth()?.addStateDidChangeListener { auth, user in
            if let theUser = user {
                // User is signed in.
            } else {
                self.performSegue(withIdentifier: "logout", sender: self)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        mainStore.unsubscribe(self)
        
        if self.authListener != nil {
           FIRAuth.auth()?.removeStateDidChangeListener(self.authListener!)
        }
    }
    
    
    
    
    func newState(state: AppState) {
        
        var activeLocations = [Location]()
        for location in mainStore.state.locations {
            if location.isActive() {
                activeLocations.append(location)
            }
        }
        
        if activeLocations.count > 0 {
            activateLocations(activeLocations: activeLocations)
            
        } else {
            deactivateLocation()
        }
        
        messageNotifications()
    }
    
    var isActive = false
    var activeTitle:String?
    
    func activateLocations(activeLocations:[Location]) {
        if isActive { return }
        isActive = true

        if !visible { return }
        
        cameraActivity?.startAnimating()

        if activeLocations.count == 1 {
            activeTitle = "You are near \(activeLocations[0].getName())."
        } else {
            activeTitle = "You are near \(activeLocations.count) places."
        }
        
        // Instantiate a message view from the provided card view layout. SwiftMessages searches for nib
        // files in the main bundle first, so you can easily copy them into your project and make changes.
        let view: TacoDialogView = try! SwiftMessages.viewFromNib()
        view.configureDropShadow()
        view.setMessage(activeTitle!)
        view.tappedAction = {
            SwiftMessages.hide()
            self.presentCamera()
        }
        
        
        var config = SwiftMessages.Config()
        
        // Slide up from the bottom.
        config.presentationStyle = .top
        
        // Display in a window at the specified window level: UIWindowLevelStatusBar
        // displays over the status bar while UIWindowLevelNormal displays under.
        config.presentationContext = .window(windowLevel: UIWindowLevelStatusBar)
        
        // Disable the default auto-hiding behavior.
        config.duration = .forever
        
        // Dim the background like a popover view. Hide when the background is tapped.
        config.dimMode = .color(color: UIColor(white: 0.0, alpha: 0.5), interactive: true)//.gray(interactive: false)
        
        // Enable the interactive pan-to-hide gesture.
        config.interactiveHide = true
        
        // Specify a status bar style to if the message is displayed directly under the status bar.
        config.preferredStatusBarStyle = .lightContent
        
        config.eventListeners.append() { event in
            if case .didHide = event {
                self.showActiveMurmur()
            }
        }
        
        
        config.ignoreDuplicates = true
        if self.visible {
            SwiftMessages.show(config: config, view: view)
        }
        
        
        
        
    }
    
    func showActiveMurmur() {
        if !isActive { return }
        guard let title = activeTitle else { return }

        var m = Murmur(title: title,
                       backgroundColor: UIColor.white,
                       titleColor: UIColor.black,
                       font: UIFont.systemFont(ofSize: 12.0, weight: UIFontWeightSemibold),
                       action: nil)
        m.action = {
            self.presentCamera()
        }
        Whisper.show(whistle: m, action: .present)
    }
    
    func deactivateLocation() {
        if !isActive { return }
        isActive = false
        cameraButton.layer.borderColor = UIColor.white.cgColor
        cameraActivity?.stopAnimating()
        Whisper.hide()
    }
    
    
    
    func tracingLocation(_ currentLocation: CLLocation){
        
        let lat = currentLocation.coordinate.latitude
        let lon = currentLocation.coordinate.longitude
        LocationService.requestNearbyLocations(lat, longitude: lon)
    }
    
    func tracingLocationDidFailWithError(_ error: NSError) {
        
    }
    
    
    func messageNotifications() {
        var count = 0
        for conversation in getNonEmptyConversations() {
            if !conversation.seen {
                count += 1
            }
        }
        if count > 0 {
            tabBar.items?[3].badgeValue = "\(count)"
        } else {
            tabBar.items?[3].badgeValue = nil
        }
        NotificationService.shared.setMessageBadgeNumber(count)
    }
    
    
    
    var cameraButton:UIButton!
    let cameraDefaultWidth:CGFloat = 2.2
    let cameraActiveWidth:CGFloat = 4
    var cameraActivity:NVActivityIndicatorView!
    func setupMiddleButton() {
        if cameraButton == nil {
            cameraButton = UIButton(frame: CGRect(x: 0, y: 0, width: 56, height: 56))
            var menuButtonFrame = cameraButton.frame
            menuButtonFrame.origin.y = self.tabBar.bounds.height - menuButtonFrame.height - 8
            menuButtonFrame.origin.x = self.tabBar.bounds.width/2 - menuButtonFrame.size.width/2
            cameraButton.frame = menuButtonFrame
            
            cameraButton.backgroundColor = UIColor.black
            cameraButton.layer.cornerRadius = menuButtonFrame.height/2
            cameraButton.layer.borderColor = UIColor.white.cgColor
            cameraButton.layer.borderWidth = cameraActiveWidth
            //menuButton.setImage(UIImage(named: "camera"), forState: UIControlState.Normal)
            cameraButton.tintColor = UIColor.white
            cameraButton.isUserInteractionEnabled = false
            
            self.tabBar.addSubview(cameraButton)
            
            cameraActivity = NVActivityIndicatorView(frame: cameraButton.bounds, type: .ballScaleRipple, color: UIColor.white, padding: 1.0, speed: 0.75)
            
            self.cameraButton.addSubview(cameraActivity)
            cameraActivity.isUserInteractionEnabled = false
            
            let hitArea = UIButton(frame: CGRect(x: 0, y: 0, width: 70, height: 66))
            hitArea.backgroundColor = UIColor(red: 1.0, green: 0, blue: 0, alpha: 0.0)
            var hitAreaFrame = hitArea.frame
            hitAreaFrame.origin.y = self.tabBar.bounds.height - hitAreaFrame.height - 2
            hitAreaFrame.origin.x = self.tabBar.bounds.width/2 - hitAreaFrame.size.width/2
            hitArea.frame = hitAreaFrame
            self.tabBar.addSubview(hitArea)
            
            hitArea.addTarget(self, action: #selector(presentCamera), for: .touchUpInside)
            hitArea.isUserInteractionEnabled = true
        }
    }
    func presentCamera() {
        //deactivateLocation()
        Whisper.hide()
        self.performSegue(withIdentifier: "showCamera", sender: self)
    }
    
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if let _ = viewController as? DummyViewController {
            presentCamera()
            return false
        }
        return true
    }
    
    @IBAction func unwindFromViewController(sender: UIStoryboardSegue) {
    }
    
    
    override func segueForUnwinding(to toViewController: UIViewController, from fromViewController: UIViewController, identifier: String?) -> UIStoryboardSegue {
        let segue = CameraUnwindTransition(identifier: identifier, source: fromViewController, destination: toViewController)
        return segue
    }

    var _center:CGPoint!
    var _hiddenCenter:CGPoint!
    var visibleFrame:CGRect!
    var hiddenFrame:CGRect!
    
    var visibleViewFrame:CGRect!
    var hiddenViewFrame:CGRect!
    
    var visible = true
    
    func setTabBarVisible(_visible:Bool, animated:Bool) {
        
        if visible == _visible {
            return
        }
        visible = _visible
        
        DispatchQueue.main.async {
            
            if self.visible {
                self.tabBar.center = self._center
                self.tabBar.isUserInteractionEnabled = true
                self.tabBar.frame = self.visibleFrame
                
                UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [], animations: {
                    self.tabBar.alpha = 1.0
                    
                }, completion: { result in
                })
            } else {
                Whisper.hide()
                UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [], animations: {
                    self.tabBar.alpha = 0.0
                    
                }, completion: { result in
                    self.tabBar.isUserInteractionEnabled = false
                    self.tabBar.frame = self.hiddenFrame
                    self.tabBar.center = self._hiddenCenter
                    
                })
            }
        }
        
    }
}

class DummyViewController:UIViewController{}
