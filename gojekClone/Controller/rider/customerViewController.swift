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
    var driverLocation = CLLocationCoordinate2D()
    var driverOnTheWay = false
    
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
                
                if let rideRequestDictionary = snapshot.value as? [String:AnyObject]{
                    if let driverLat = rideRequestDictionary["driverLat"] as? Double{
                        if let driverLon = rideRequestDictionary["driverlon"] as? Double{
                            self.driverLocation = CLLocationCoordinate2D(latitude: driverLat, longitude: driverLon)
                            self.driverOnTheWay = true
                            self.displayDriverAndUser()
                            
                            
                            //get driver data when they moved / updated
                            if let email = Auth.auth().currentUser?.email {
                                Database.database().reference().child("RideRequests").queryOrdered(byChild: "email").queryEqual(toValue: email).observe(.childChanged, with: {
                                    snapshot in
                                    
                                        if let rideRequestDictionary = snapshot.value as? [String:AnyObject]{
                                            if let driverLat = rideRequestDictionary["driverLat"] as? Double{
                                                if let driverLon = rideRequestDictionary["driverlon"] as? Double{
                                                    self.driverLocation = CLLocationCoordinate2D(latitude: driverLat, longitude: driverLon)
                                                    self.driverOnTheWay = true
                                                    self.displayDriverAndUser()
                                                }
                                            }
                                        }
                                })
                            }
                        }
                    }
                }
                
                
            })
        }
        
    }
    
    func displayDriverAndUser(){
        let driverCLLocation = CLLocation(latitude: driverLocation.latitude, longitude: driverLocation.longitude)
        let riderCLLocation = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        
        let distance = driverCLLocation.distance(from: riderCLLocation) / 1000
        
        let roundedDistance = round(distance * 100) / 100
        orderBtn.setTitle("Your Driver is \(roundedDistance) km away", for: .normal)
        
        map.removeAnnotations(map.annotations)
        
        let latDelta = abs(driverLocation.latitude - userLocation.latitude) * 2 + 0.005
        let lonDelta = abs(driverLocation.longitude - userLocation.longitude) * 2 + 0.005
        let region = MKCoordinateRegion(center: userLocation, span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta))
        map.setRegion(region, animated: true)
        
        let riderAnno = MKPointAnnotation()
        let driverAnno = MKPointAnnotation()
        
        riderAnno.coordinate = userLocation
        driverAnno.coordinate = driverLocation
        
        riderAnno.title = "your location"
        driverAnno.title = "Driver location"
        
        map.addAnnotation(riderAnno)
        map.addAnnotation(driverAnno)
        
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let coordinate = manager.location?.coordinate{
            let center = CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
            userLocation = center
            
            
            if isCalled {
                displayDriverAndUser()
                
                
            }else{
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
    }
    
    @IBAction func orderBtn(_ sender: Any) {
        if !driverOnTheWay{
            
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
    }
    @IBAction func logout(_ sender: Any) {
        try? Auth.auth().signOut()
        navigationController?.popToRootViewController(animated: true)
    }
}
