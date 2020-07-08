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

class driverMapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    var locationManager = CLLocationManager()
    var requestLocation = CLLocationCoordinate2D()
    var requestDestinationLocation = CLLocationCoordinate2D()
    var driverLocation = CLLocationCoordinate2D()
    var currentUser = KeychainWrapper.standard.string(forKey: "uid")
    var requestEmail = ""
    var isCalled = false
    var driverEmail:String?
    var driverOnTheWay = false
    var driverLat:String?
    var driverLon:String?
    @IBOutlet weak var directionBtn: UIButton!
    @IBOutlet weak var userDirectionBtn: UIButton!
    @IBOutlet weak var acceptRequest: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        directionBtn.isHidden = true
        userDirectionBtn.isHidden = true
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization() //ask user request
        locationManager.startUpdatingLocation()
        
        mapView.delegate = self

        let region = MKCoordinateRegion(center: requestLocation, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        
        mapView.setRegion(region, animated: false)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = requestLocation
        annotation.title = requestEmail
        mapView.addAnnotation(annotation)
        
        let annotation2 = MKPointAnnotation()
        annotation2.coordinate = requestDestinationLocation
        annotation2.title = "Destination"
        mapView.addAnnotation(annotation2)
        
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
                            self.mapThis()
                            self.directionBtn.isHidden = false
                            self.userDirectionBtn.isHidden = false
                            self.acceptRequest.isHidden = true
                            
                            
                            
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
                                        if let destinationLat = rideRequestDictionary["destinationLat"] as? Double{
                                            if let destinationLon = rideRequestDictionary["destinationLon"] as? Double{
                                                self.driverLocation = CLLocationCoordinate2D(latitude: driverLat, longitude: driverLon)
                                                self.requestLocation = CLLocationCoordinate2D(latitude: userLat, longitude: userLon)
                                                self.requestDestinationLocation = CLLocationCoordinate2D(latitude: destinationLat, longitude: destinationLon)
                                            }
                                        }
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
        let destinationAnno = MKPointAnnotation()
        let driverAnno = MKPointAnnotation()
        
        riderAnno.coordinate = requestLocation
        driverAnno.coordinate = driverLocation
        destinationAnno.coordinate = requestDestinationLocation
        
        riderAnno.title = requestEmail
        driverAnno.title = "Your location"
        destinationAnno.title = "destination"
        
        mapView.addAnnotation(riderAnno)
        mapView.addAnnotation(driverAnno)
        mapView.addAnnotation(destinationAnno)
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
                
                let annotation2 = MKPointAnnotation()
                annotation2.coordinate = requestDestinationLocation
                annotation2.title = "Destination"
                mapView.addAnnotation(annotation2)
                
            }
            
        }
    }
    
    func mapThis() {
        let soucePlaceMark = MKPlacemark(coordinate: requestLocation)
        let destPlaceMark = MKPlacemark(coordinate: requestDestinationLocation)
        
        let sourceItem = MKMapItem(placemark: soucePlaceMark)
        let destItem = MKMapItem(placemark: destPlaceMark)
        
        let destinationRequest = MKDirections.Request()
        destinationRequest.source = sourceItem
        destinationRequest.destination = destItem
        destinationRequest.transportType = .automobile
        destinationRequest.requestsAlternateRoutes = true
        
        let directions = MKDirections(request: destinationRequest)
        directions.calculate { (response, error) in
            guard let response = response else {
                if let error = error {
                    print("Something is wrong :(")
                }
                return
            }
            
          let route = response.routes[0]
          self.mapView.addOverlay(route.polyline)
          self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)

        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let render = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        render.strokeColor = .blue
        return render
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
            directionBtn.isHidden = false
            userDirectionBtn.isHidden = false
            acceptRequest.isHidden = true
            mapThis()
        }
        
        
        

        
    }


    @IBAction func directionBtn(_ sender: Any) {
        //create direction to user in apple map
        let requestCLLocation = CLLocation(latitude: requestDestinationLocation.latitude, longitude: requestDestinationLocation.longitude)
        
        CLGeocoder().reverseGeocodeLocation(requestCLLocation, completionHandler: {
            (placemarks, error) in
        
            if let placemarks = placemarks {
                if placemarks.count > 0 {
                    let placemark = MKPlacemark(placemark: placemarks[0])
                    let mapItem = MKMapItem(placemark: placemark)
                    mapItem.name = "destination"
                    let options = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving]
                    mapItem.openInMaps(launchOptions: options)
                }
            }
        })
    }
    
    @IBAction func directionUserBtn(_ sender: Any) {
        //create direction to user in apple map
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
