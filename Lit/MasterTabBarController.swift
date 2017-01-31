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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        mainStore.subscribe(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        mainStore.unsubscribe(self)
    }
    
    
    func newState(state: AppState) {
        
    }
    
    func tracingLocation(_ currentLocation: CLLocation){
        
        let lat = currentLocation.coordinate.latitude
        let lon = currentLocation.coordinate.longitude
        LocationService.requestNearbyLocations(lat, longitude: lon)
    }
    
    func tracingLocationDidFailWithError(_ error: NSError) {
        
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
