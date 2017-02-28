//
//  LocationMapViewController.swift
//  Lit
//
//  Created by Robert Canton on 2017-02-27.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import Foundation
import UIKit
import GoogleMaps

class LocationMapViewController: UIViewController {
    
    var location:Location!
    
    var mapView:GMSMapView!
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = location.getName()
        
        
        self.view.backgroundColor = UIColor.black
        let camera = GMSCameraPosition.camera(withTarget: location.getCoordinates().coordinate, zoom: 16.0)

        mapView = GMSMapView.map(withFrame: view.bounds, camera: camera)
        view.addSubview(mapView)
        mapView.backgroundColor = UIColor.black
        
        // Creates a marker in the center of the map.
        let marker = GMSMarker()
        marker.position = location.getCoordinates().coordinate
        marker.title = location.getShortAddress()
        
        if let city = location.getCity() {
            marker.snippet = city
        }
        marker.map = mapView
        marker.appearAnimation = kGMSMarkerAnimationPop
        marker.isFlat = true
        
        marker.groundAnchor = CGPoint(x: 0.5, y: 0.5)
        marker.icon = UIImage(named: "circle_dot")
        mapView.settings.scrollGestures = true
        mapView.settings.rotateGestures = true
        
        mapView.isMyLocationEnabled = true
        mapView.selectedMarker = marker
        
        
        var strokeColor = UIColor.white
        var fillColor = UIColor(white: 1.0, alpha: 0.35)
        
        if location.isActive() {
            strokeColor = accentColor
            fillColor = UIColor(red: 0.0, green: 128/255, blue: 1, alpha: 0.35)
        }
        
        marker.iconView?.tintColor = strokeColor
        
        let circleCenter = location.getCoordinates().coordinate
        let circ = GMSCircle(position: circleCenter, radius: location.getRadius())
        
        circ.fillColor = fillColor
        circ.strokeColor = strokeColor
        circ.strokeWidth = 1
        circ.map = mapView
        
        
        do {
            // Set the map style by passing the URL of the local file.
            if let styleURL = Bundle.main.url(forResource: "mapStyle", withExtension: "json") {
                mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
            } else {
                NSLog("Unable to find style.json")
            }
        } catch {
            NSLog("One or more of the map styles failed to load. \(error)")
        }
        
        mapView.alpha = 0.0
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        UIView.animate(withDuration: 0.15, delay: 0.15, options: .curveEaseIn, animations: {
            self.mapView.alpha = 1.0
        }, completion: nil)
    }
    
    
}
