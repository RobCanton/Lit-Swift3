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
}
