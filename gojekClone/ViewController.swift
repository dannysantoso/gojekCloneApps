//
//  ViewController.swift
//  gojekClone
//
//  Created by danny santoso on 21/06/20.
//  Copyright © 2020 danny santoso. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var tfEmail: UITextField!
    @IBOutlet weak var tfPassword: UITextField!
    @IBOutlet weak var loginBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        tfEmail.underlined()
        tfPassword.underlined()
        loginBtn.layer.cornerRadius = loginBtn.frame.size.height / 2
    }


}

