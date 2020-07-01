//
//  createProfileViewController.swift
//  gojekClone
//
//  Created by danny santoso on 28/06/20.
//  Copyright © 2020 danny santoso. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import SwiftKeychainWrapper

class createProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var addPhoto: UIButton!
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var tfName: UITextField!
    
    var imagePicker:UIImagePickerController!
    var imageSelected = false
    var username:String!
    var currentUser = KeychainWrapper.standard.string(forKey: "uid")
    var typeUser = KeychainWrapper.standard.string(forKey: "type")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setImagePicker()
        
        

        // Do any additional setup after loading the view.
    }
    
    func setImagePicker(){
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
    }

    @IBAction func btnSubmit(_ sender: Any) {
        if tfName.text != nil && tfName.text != "" {
            
            username = tfName.text
            
            guard let image = profileImage.image, imageSelected == true else{
                print("Image must be selected")
                return
            }
            
            
            //menyimpan gambar ke dalam firebase storage
            
            if let imageData = image.jpegData(compressionQuality: 0.2){
                let imgUid = NSUUID().uuidString
                
                let metadata = StorageMetadata()
                metadata.contentType = "image/jpeg"
                let storageRef = Storage.storage().reference().child(imgUid)
                storageRef.putData(imageData, metadata: metadata) { (metadata, error) in

                        if error != nil {
                            print("did not upload img")
                            return
                        } else {
                            storageRef.downloadURL(completion: {(url, error) in
                            if error != nil {
                                print(error!.localizedDescription)
                                return
                            }
                            let downloadURL = url?.absoluteString
                            
                            if let url = downloadURL {
                                
                                self.setUser(img: url)
                            }
                        }
                    )}
                }
            
            }
        
        }
        
    }
    
    //menyimpan data ke dalam firebase database
    func setUser(img: String){
        let userData = [
            "username": username!,
            "userImg": img
        ]
        
        //menyimpan datanya ke firebase database
        let location = Database.database().reference().child("users").child(currentUser!)
        
        location.setValue(userData)
        
        if typeUser == "driver"{
            
            let destination = driverViewController(nibName: "driverViewController", bundle: nil)
            let navigationController = UINavigationController()
            navigationController.viewControllers = [destination]
            self.view.window?.rootViewController = navigationController
            self.view.window?.makeKeyAndVisible()
            self.view.window?.rootViewController?.dismiss(animated: true, completion: nil)
            
        }else{
            
            let destination = customerViewController(nibName: "customerViewController", bundle: nil)
            let navigationController = UINavigationController()
            navigationController.viewControllers = [destination]
            self.view.window?.rootViewController = navigationController
            self.view.window?.makeKeyAndVisible()
            self.view.window?.rootViewController?.dismiss(animated: true, completion: nil)
            
        }
        
    }
    
    //ngedisplay image picker untuk memilih gambar dari library, photo
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let image = info[.editedImage] as? UIImage {
            profileImage.image = image
            imageSelected = true
        } else {
            print("image wasnt selected")
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func btnAddPhoto(_ sender: Any) {
        present(imagePicker, animated: true, completion: nil)
    }
}
