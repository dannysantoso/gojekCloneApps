//
//  driverMapViewController.swift
//  gojekClone
//
//  Created by danny santoso on 25/06/20.
//  Copyright © 2020 danny santoso. All rights reserved.
//

import UIKit
import MapKit
import FirebaseDatabase

class driverMapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    var requestLocation = CLLocationCoordinate2D()
    var driverLocation = CLLocationCoordinate2D()
    var requestEmail = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let region = MKCoordinateRegion(center: requestLocation, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        
        mapView.setRegion(region, animated: false)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = requestLocation
        annotation.title = requestEmail
        mapView.addAnnotation(annotation)
    }

    @IBAction func acceptRequest(_ sender: Any) {
        //update ride request
        Database.database().reference().child("RiderRequests").queryOrdered(byChild: "email").queryEqual(toValue: requestEmail).observe(.childAdded, with: {
            (snapshot) in
            snapshot.ref.updateChildValues(["driverLat": self.driverLocation.latitude,
                                            "driverlon": self.driverLocation.longitude])
            Database.database().reference().child("RideRequests").removeAllObservers()
        })
        
        
        //create direction to user
        let requestCLLocation = CLLocation(latitude: requestLocation.latitude, longitude: requestLocation.longitude)
        
        CLGeocoder().reverseGeocodeLocation(requestCLLocation, completionHandler: {
            (placemarks, error) in
            
            if let placemarks = placemarks {
                if placemarks.count > 0 {
                    let placemark = MKPlacemark(placemark: placemarks[0])
                    let mapItem = MKMapItem(placemark: placemark)
                    mapItem.name = self.requestEmail
                    let options = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving]
                    mapItem.openInMaps(launchOptions: options)
                }
            }
        })
        
    }


}
