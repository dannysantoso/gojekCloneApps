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
import SwiftKeychainWrapper

class customerViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var orderBtn: UIButton!
    
    var locationManager = CLLocationManager()
    var userLocation = CLLocationCoordinate2D()
    var isCalled = false
    var driverLocation = CLLocationCoordinate2D()
    var driverOnTheWay = false
    var currentUser = KeychainWrapper.standard.string(forKey: "uid")
    var driverLat: String?
    var driverLon: String?
    var username: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization() //ask user request
        locationManager.startUpdatingLocation()
        
        Database.database().reference().child("users").child(currentUser!).observe(.value, with: {
            snapshot in
                if let rideRequestDictionary = snapshot.value as? [String:AnyObject]{
                    if let username = rideRequestDictionary["username"] as? String{
                        self.username = username
                    }
                }
                
        })
        
        
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
                            self.driverLat = String(driverLat)
                            self.driverLon = String(driverLon)
                            self.displayDriverAndUser()
                            
                            
//                            //get driver data when they moved / updated
//                            if let email = Auth.auth().currentUser?.email {
//                                Database.database().reference().child("RideRequests").queryOrdered(byChild: "email").queryEqual(toValue: email).observe(.childChanged, with: {
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
            //get driver data when they moved / updated
            if let email = Auth.auth().currentUser?.email {
                Database.database().reference().child("RideRequests").queryOrdered(byChild: "email").queryEqual(toValue: email).observe(.childChanged, with: {
                    snapshot in
                    
                        if let rideRequestDictionary = snapshot.value as? [String:AnyObject]{
                            if let driverLat = rideRequestDictionary["driverLat"] as? Double{
                                if let driverLon = rideRequestDictionary["driverlon"] as? Double{
                                    if let userLat = rideRequestDictionary["lat"] as? Double{
                                        if let userLon = rideRequestDictionary["lon"] as? Double{
                                            self.driverLocation = CLLocationCoordinate2D(latitude: driverLat, longitude: driverLon)
                                            self.userLocation = CLLocationCoordinate2D(latitude: userLat, longitude: userLon)
                                        }
                                    }
                                }
                            }
                        }
                })
            }
        
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
                if driverLon != nil && driverLat != nil {
                    displayDriverAndUser()
                }
                
                if let email = Auth.auth().currentUser?.email {
                    Database.database().reference().child("RideRequests").queryOrdered(byChild: "email").queryEqual(toValue: email).observe(.childAdded, with: {
                    (snapshot) in
                    snapshot.ref.updateChildValues(["lat":self.userLocation.latitude,
                                                    "lon":self.userLocation.longitude])
                    Database.database().reference().child("RideRequests").removeAllObservers()
                    })
                }
                
                
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
                                                                    "userID":currentUser,
                                                                    "username":username,
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
//        try? Auth.auth().signOut()
//        KeychainWrapper.standard.removeObject(forKey: "uid")
//        KeychainWrapper.standard.removeObject(forKey: "type")
//        navigationController?.popToRootViewController(animated: true)
        
        //jika user logout
        try? Auth.auth().signOut()
        KeychainWrapper.standard.removeObject(forKey: "uid")
        KeychainWrapper.standard.removeObject(forKey: "type")
                
        //membuat rootviewcontroller baru
        let onboardingViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "welcome")
        let navigationController = UINavigationController()
        navigationController.viewControllers = [onboardingViewController]
        view.window?.rootViewController = navigationController
        view.window?.makeKeyAndVisible()
        
        self.view.window?.rootViewController?.dismiss(animated: true, completion: nil)
    }
}
