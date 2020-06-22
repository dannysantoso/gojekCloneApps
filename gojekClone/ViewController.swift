//
//  ViewController.swift
//  gojekClone
//
//  Created by danny santoso on 21/06/20.
//  Copyright © 2020 danny santoso. All rights reserved.
//

import UIKit
import FirebaseAuth

class ViewController: UIViewController {

    @IBOutlet weak var tfEmail: UITextField!
    @IBOutlet weak var tfPassword: UITextField!
    @IBOutlet weak var submitBtn: UIButton!
    @IBOutlet weak var isDriverLabel: UILabel!
    @IBOutlet weak var switchBtn: UISwitch!
    @IBOutlet weak var changeBtn: UIButton!
    @IBOutlet weak var changeLabel: UILabel!
    @IBOutlet weak var alertLabel: UILabel!
    
    var isSignUp = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        returnKeyboard()
        dismissKeyboard()
        
        tfEmail.underlined()
        tfPassword.underlined()
        
        submitBtn.layer.cornerRadius = submitBtn.frame.size.height / 2
    }
    
    func displayAlert(title:String, message:String){
        let alertControl = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertControl.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alertControl, animated: true, completion: nil)
    }
    
    func returnKeyboard(){
        tfEmail.delegate = self
        tfPassword.delegate = self
    }
    
    func dismissKeyboard(){
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc func handleTap(){
        self.view.endEditing(true)
    }
    
    @IBAction func submitBtn(_ sender: Any) {
        if tfEmail.text == "" || tfPassword.text == "" {
            alertLabel.text = "please fill all the field"
//            displayAlert(title: "Invalid Information", message: "please fill all the field")
        } else {
            if let email = tfEmail.text {
                if let password = tfPassword.text {
                    if isSignUp == true {
                        //sign up
                        Auth.auth().createUser(withEmail: email, password: password, completion: {
                            (user, error) in
                            if error != nil {
                                self.displayAlert(title: "Error", message: error!.localizedDescription)
                            }else{
                                print("Sign Up Success")
                            }
                        })
                    } else {
                        //login
                        Auth.auth().signIn(withEmail: email, password: password, completion: {
                            (user, error) in
                            if error != nil {
                                self.displayAlert(title: "Error", message: error!.localizedDescription)
                            }else{
                                print("Sign In Success")
                                let destination = customerViewController(nibName: "customerViewController", bundle: nil)
                                
                                self.navigationController?.pushViewController(destination, animated: true)
                            }
                        })
                    }
                }
            }
        }
    }
    
    @IBAction func changeBtn(_ sender: Any) {
        if isSignUp == true{
            submitBtn.setTitle("Login", for: .normal)
            changeBtn.setTitle("Sign Up", for: .normal)
            changeLabel.text = "Don't have an account ?"
            switchBtn.isHidden = true
            isDriverLabel.isHidden = true
            isSignUp = false
        }else{
            submitBtn.setTitle("Sign Up", for: .normal)
            changeBtn.setTitle("Sign In", for: .normal)
            changeLabel.text = "Already have an account ?"
            switchBtn.isHidden = false
            isDriverLabel.isHidden = false
            isSignUp = true
        }
        
    }
    
    @IBAction func tfEmail(_ sender: Any) {
        alertLabel.text = ""
    }
    
    @IBAction func tfPassword(_ sender: Any) {
        alertLabel.text = ""
    }
    
    
}

