//
//  customerViewController.swift
//  gojekClone
//
//  Created by danny santoso on 22/06/20.
//  Copyright © 2020 danny santoso. All rights reserved.
//

import UIKit
import MapKit
import FirebaseDatabase
import FirebaseAuth

class customerViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var orderBtn: UIButton!
    
    var locationManager = CLLocationManager()
    var userLocation = CLLocationCoordinate2D()
    var isCalled = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization() //ask user request
        locationManager.startUpdatingLocation()
        
        
        if let email = Auth.auth().currentUser?.email {
            Database.database().reference().child("RideRequests").queryOrdered(byChild: "email").queryEqual(toValue: email).observe(.childAdded, with: { //.childAdded means whenever there is child added remove it
                (snapshot) in
                self.isCalled = true
                self.orderBtn.setTitle("Cancel", for: .normal)
                
                //this for stop the observe doing
                Database.database().reference().child("RideRequests").removeAllObservers()
            })
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let coordinate = manager.location?.coordinate{
            let center = CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
            userLocation = center
            let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)) //span how much space show up
            map.setRegion(region, animated: true)
            
            //remove all the annotation before creating a new 1, to prevent duplicated annotations
            map.removeAnnotations(map.annotations)
            
            //create annotation to know where is the user
            let annotation = MKPointAnnotation()
            annotation.coordinate = center
            annotation.title = "your location"
            map.addAnnotation(annotation)
            
        }
    }
    
    @IBAction func orderBtn(_ sender: Any) {
        
        if let email = Auth.auth().currentUser?.email {
            if isCalled == false {
                let rideRequestDictionary : [String: Any] = [
                                                                "email":email,
                                                                "lat":self.userLocation.latitude,
                                                                "lon":self.userLocation.longitude
                                                            ]
                
                Database.database().reference().child("RideRequests").childByAutoId().setValue(rideRequestDictionary)
                
                self.isCalled = true
                self.orderBtn.setTitle("Cancel", for: .normal)
            }else{
                self.isCalled = false
                self.orderBtn.setTitle("Order", for: .normal)
                Database.database().reference().child("RideRequests").queryOrdered(byChild: "email").queryEqual(toValue: email).observe(.childAdded, with: { //.childAdded means whenever there is child added remove it
                    (snapshot) in
                    snapshot.ref.removeValue()
                    //this for stop the observe doing
                    Database.database().reference().child("RideRequests").removeAllObservers()
                })
            }
            
        }
    }
    @IBAction func logout(_ sender: Any) {
        try? Auth.auth().signOut()
        navigationController?.popToRootViewController(animated: true)
    }
}
