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
import FirebaseAuth
import SwiftKeychainWrapper

class driverMapViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    var locationManager = CLLocationManager()
    var requestLocation = CLLocationCoordinate2D()
    var driverLocation = CLLocationCoordinate2D()
    var currentUser = KeychainWrapper.standard.string(forKey: "uid")
    var requestEmail = ""
    var isCalled = false
    var driverEmail:String?
    var driverOnTheWay = false
    var driverLat:String?
    var driverLon:String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization() //ask user request
        locationManager.startUpdatingLocation()

        let region = MKCoordinateRegion(center: requestLocation, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        
        mapView.setRegion(region, animated: false)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = requestLocation
        annotation.title = requestEmail
        mapView.addAnnotation(annotation)
        
        checkLogin()
        
    }
    
    func checkLogin(){
        if let email = Auth.auth().currentUser?.email {
            driverEmail = email
            
            Database.database().reference().child("RideRequests").queryOrdered(byChild: "driverEmail").queryEqual(toValue: email).observe(.childAdded, with: { //.childAdded means whenever there is child added remove it
                (snapshot) in
                self.isCalled = true
                
                
                
                //this for stop the observe doing
                Database.database().reference().child("RideRequests").removeAllObservers()
                
                if let rideRequestDictionary = snapshot.value as? [String:AnyObject]{
                    if let driverLat = rideRequestDictionary["driverLat"] as? Double{
                        if let driverLon = rideRequestDictionary["driverlon"] as? Double{
                            self.driverLocation = CLLocationCoordinate2D(latitude: driverLat, longitude: driverLon)
                            self.driverOnTheWay = true
                            self.driverLat = String(driverLat)
                            self.driverLon = String(driverLon)
                            self.displayDriverAndUser()
                            
                            
//                            //get driver data when they moved / updated
//                            if let email = Auth.auth().currentUser?.email {
//                                Database.database().reference().child("RideRequests").queryOrdered(byChild: "driverEmail").queryEqual(toValue: email).observe(.childChanged, with: {
//                                    snapshot in
//                                    
//                                        if let rideRequestDictionary = snapshot.value as? [String:AnyObject]{
//                                            if let driverLat = rideRequestDictionary["driverLat"] as? Double{
//                                                if let driverLon = rideRequestDictionary["driverlon"] as? Double{
//                                                    self.driverLocation = CLLocationCoordinate2D(latitude: driverLat, longitude: driverLon)
//                                                    self.driverOnTheWay = true
//                                                    self.driverLat = String(driverLat)
//                                                    self.driverLon = String(driverLon)
//                                                    self.displayDriverAndUser()
//                                                }
//                                            }
//                                        }
//                                })
//                            }
                        }
                    }
                }
                
                
            })
        }
    }
    
    func displayDriverAndUser(){
        if let email = Auth.auth().currentUser?.email {
            Database.database().reference().child("RideRequests").queryOrdered(byChild: "driverEmail").queryEqual(toValue: email).observe(.childChanged, with: {
                snapshot in
                
                    if let rideRequestDictionary = snapshot.value as? [String:AnyObject]{
                        if let driverLat = rideRequestDictionary["driverLat"] as? Double{
                            if let driverLon = rideRequestDictionary["driverlon"] as? Double{
                                if let userLat = rideRequestDictionary["lat"] as? Double{
                                    if let userLon = rideRequestDictionary["lon"] as? Double{
                                        self.driverLocation = CLLocationCoordinate2D(latitude: driverLat, longitude: driverLon)
                                        self.requestLocation = CLLocationCoordinate2D(latitude: userLat, longitude: userLon)
                                    }
                                }
                            }
                        }
                    }
            })
        }
        
        let driverCLLocation = CLLocation(latitude: driverLocation.latitude, longitude: driverLocation.longitude)
        let riderCLLocation = CLLocation(latitude: requestLocation.latitude, longitude: requestLocation.longitude)
        
        let distance = driverCLLocation.distance(from: riderCLLocation) / 1000
        
        let roundedDistance = round(distance * 100) / 100
//        orderBtn.setTitle("Your Driver is \(roundedDistance) km away", for: .normal)
        
        mapView.removeAnnotations(mapView.annotations)
        
        let latDelta = abs(driverLocation.latitude - requestLocation.latitude) * 2 + 0.005
        let lonDelta = abs(driverLocation.longitude - requestLocation.longitude) * 2 + 0.005
        let region = MKCoordinateRegion(center: requestLocation, span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta))
        mapView.setRegion(region, animated: true)
        
        let riderAnno = MKPointAnnotation()
        let driverAnno = MKPointAnnotation()
        
        riderAnno.coordinate = requestLocation
        driverAnno.coordinate = driverLocation
        
        riderAnno.title = requestEmail
        driverAnno.title = "Your location"
        
        mapView.addAnnotation(riderAnno)
        mapView.addAnnotation(driverAnno)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let coordinate = manager.location?.coordinate{
            let center = CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
            driverLocation = center
            
            
            if isCalled {
                
                if driverLon != nil && driverLat != nil {
                    displayDriverAndUser()
                }
                
                if let email = Auth.auth().currentUser?.email {
                    Database.database().reference().child("RideRequests").queryOrdered(byChild: "driverEmail").queryEqual(toValue: email).observe(.childAdded, with: {
                    (snapshot) in
                    snapshot.ref.updateChildValues(["driverLat":self.driverLocation.latitude,
                                                    "driverlon":self.driverLocation.longitude])
                    Database.database().reference().child("RideRequests").removeAllObservers()
                    })
                }
                
                
            }else{
                let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)) //span how much space show up
                mapView.setRegion(region, animated: true)
                
                //remove all the annotation before creating a new 1, to prevent duplicated annotations
                mapView.removeAnnotations(mapView.annotations)
                
                //create annotation to know where is the user
                let annotation = MKPointAnnotation()
                annotation.coordinate = center
                annotation.title = "your location"
                mapView.addAnnotation(annotation)
                
            }
            
        }
    }
    

    @IBAction func acceptRequest(_ sender: Any) {
        if isCalled == false {
            //update ride request
            Database.database().reference().child("RideRequests").queryOrdered(byChild: "email").queryEqual(toValue: requestEmail).observe(.childAdded, with: {
                (snapshot) in
                snapshot.ref.updateChildValues(["driverLat": self.driverLocation.latitude,
                                                "driverlon": self.driverLocation.longitude,
                                                "driverId": self.currentUser,
                                                "driverEmail": self.driverEmail])
                Database.database().reference().child("RideRequests").removeAllObservers()
            })
            
            isCalled = true
        }
        
        
        
        //create direction to user in apple map
//        let requestCLLocation = CLLocation(latitude: requestLocation.latitude, longitude: requestLocation.longitude)
//
//        CLGeocoder().reverseGeocodeLocation(requestCLLocation, completionHandler: {
//            (placemarks, error) in
//
//            if let placemarks = placemarks {
//                if placemarks.count > 0 {
//                    let placemark = MKPlacemark(placemark: placemarks[0])
//                    let mapItem = MKMapItem(placemark: placemark)
//                    mapItem.name = self.requestEmail
//                    let options = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving]
//                    mapItem.openInMaps(launchOptions: options)
//                }
//            }
//        })
        
    }


}
