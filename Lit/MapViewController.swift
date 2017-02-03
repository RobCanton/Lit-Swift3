//
//  MapViewController.swift
//  Lit
//
//  Created by Robert Canton on 2016-10-19.
//  Copyright © 2016 Robert Canton. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController {
    
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    
    fileprivate var location:Location!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let regionRadius: CLLocationDistance = 500
        let coordinate = location.getCoordinates().coordinate
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(coordinate,
                                                                regionRadius * 2.0, regionRadius * 2.0)
        
        self.navigationController?.navigationBar.titleTextAttributes =
            [NSFontAttributeName: UIFont(name: "Avenir-Heavy", size: 16.0)!,
             NSForegroundColorAttributeName: UIColor.white
        ]
        

        addressLabel.text = location.getAddress()
        
        mapView.showsUserLocation = true
        mapView.showsCompass = true
        mapView.showsBuildings = true
        mapView.isPitchEnabled = true
        
        
        mapView.setRegion(coordinateRegion, animated: true)
        let a = MapPin(coordinate: coordinate, title: location.getName(), subtitle: location.getAddress())
        mapView.addAnnotation(a)
        
    }
    
    func setMapLocation(_location:Location) {
        self.location = _location
        title = location.getName()
        
        
    }
    
}

class MapPin : NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    
    init(coordinate: CLLocationCoordinate2D, title: String, subtitle: String) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
    }
}
