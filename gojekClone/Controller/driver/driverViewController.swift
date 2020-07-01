//
//  driverViewController.swift
//  gojekClone
//
//  Created by danny santoso on 25/06/20.
//  Copyright © 2020 danny santoso. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import MapKit
import SwiftKeychainWrapper

class driverViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var driverTableView: UITableView!
    
    var rideRequest : [DataSnapshot] = []
    var locationManager = CLLocationManager()
    var driverLocation = CLLocationCoordinate2D()
    var currentUser = KeychainWrapper.standard.string(forKey: "uid")
    var driverId:String?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization() //ask user request
        locationManager.startUpdatingLocation()
        
        
        Database.database().reference().child("RideRequests").queryOrdered(byChild: "driverId").queryEqual(toValue: currentUser).observe(.childAdded, with: { //.childAdded means whenever there is child added remove it
            (snapshot) in
                if let rideRequestDictionary = snapshot.value as? [String:AnyObject]{
                    if let id = rideRequestDictionary["driverId"] as? String{
                        if let email = rideRequestDictionary["username"] as? String {
                            if let lat = rideRequestDictionary["lat"] as? Double{
                                if let lon = rideRequestDictionary["lon"] as? Double{
                                    self.driverId = id
                                    
                                    
                                    let destination = driverMapViewController(nibName: "driverMapViewController", bundle: nil)
                            
                                    let location = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                                    
                                    destination.requestEmail = email
                                    destination.requestLocation = location
                                    destination.driverLocation = self.driverLocation


                                    self.navigationController?.pushViewController(destination, animated: true)
                                }
                            }
                        }
                    }
                }
            Database.database().reference().child("RideRequests").removeAllObservers()
        })
        
        
        
        Database.database().reference().child("RideRequests").observe(.childAdded, with: {
            (snapshot) in
            if let rideRequestDictionary = snapshot.value as? [String:AnyObject]{
                if let driverLat = rideRequestDictionary["driverLat"] as? Double{
                    
                }else{
                    self.rideRequest.append(snapshot)
                    self.driverTableView.reloadData()
                }
            }
        })

        driverTableView.dataSource = self
        driverTableView.delegate = self
        
        driverTableView.register(UINib(nibName: "driverTableViewCell", bundle: nil), forCellReuseIdentifier: "driverCell")
        
        Timer.scheduledTimer(withTimeInterval: 3, repeats: true, block: {
            (timer) in
                self.driverTableView.reloadData()
        })
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let coord = manager.location?.coordinate{
            driverLocation = coord
        }
    }
    
    @IBAction func temporaryLogout(_ sender: Any) {
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


extension driverViewController: UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rideRequest.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "driverCell", for: indexPath) as! driverTableViewCell
        
        let snapshot = rideRequest[indexPath.row]
        
        if let rideRequestDictionary = snapshot.value as? [String:AnyObject]{
            if let email = rideRequestDictionary["username"] as? String {
                
                if let lat = rideRequestDictionary["lat"] as? Double{
                    if let lon = rideRequestDictionary["lon"] as? Double{
                        
                        let driverCLLocation = CLLocation(latitude: driverLocation.latitude, longitude: driverLocation.longitude)
                        
                        let riderCLLocation = CLLocation(latitude: lat, longitude: lon)
                        
                        let distance = driverCLLocation.distance(from: riderCLLocation) / 1000
                        
                        let roundedDistance = round(distance * 100) / 100
                        cell.cellLabel.text = "\(email) - \(roundedDistance)km away"
                    }
                }
                
            }
        }
        
        
        
        return cell
    }
    
    
}

extension driverViewController: UITableViewDelegate{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let destination = driverMapViewController(nibName: "driverMapViewController", bundle: nil)
        
        let snapshot = rideRequest[indexPath.row]
        
        if let rideRequestDictionary = snapshot.value as? [String:AnyObject]{
            if let email = rideRequestDictionary["email"] as? String {
            
                if let lat = rideRequestDictionary["lat"] as? Double{
                    if let lon = rideRequestDictionary["lon"] as? Double{
                        destination.requestEmail = email
                        
                        let location = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                        
                        destination.requestLocation = location
                        destination.driverLocation = driverLocation
                    }
                }
            }
        }

        self.navigationController?.pushViewController(destination, animated: true)
    }
    
}
