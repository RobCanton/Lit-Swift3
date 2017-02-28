//
//  LocationFooterView.swift
//  Lit
//
//  Created by Robert Canton on 2017-01-31.
//  Copyright © 2017 Robert Canton. All rights reserved.
//

import UIKit
import GoogleMaps

class LocationFooterView: UITableViewHeaderFooterView {


    @IBOutlet weak var mapContainer: UIView!
    override func awakeFromNib() {
        super.awakeFromNib()
        
        
        
    }
    
    func setLocationInfo(location:Location) {

        let camera = GMSCameraPosition.camera(withTarget: location.getCoordinates().coordinate, zoom: 16.0)
        
        let mapView = GMSMapView.map(withFrame: mapContainer.bounds, camera: camera)
        mapContainer.addSubview(mapView)
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
        mapView.settings.scrollGestures = false
        mapView.settings.rotateGestures = false
        mapView.isMyLocationEnabled = true
        mapView.isUserInteractionEnabled = false
        mapView.alpha = 0.0
        //mapView.selectedMarker = marker
        
        
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
        
        UIView.animate(withDuration: 0.15, delay: 0.15, options: .curveEaseIn, animations: {
            mapView.alpha = 1.0
        }, completion: nil)
    }

}
