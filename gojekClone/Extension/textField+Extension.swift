//
//  textField+Extension.swift
//  gojekClone
//
//  Created by danny santoso on 22/06/20.
//  Copyright © 2020 danny santoso. All rights reserved.
//

import Foundation
import UIKit

extension UITextField {
    func underlined(){
        let border = CALayer()
        let width = CGFloat(1.5)
        border.borderColor = UIColor.systemGray.cgColor
        border.frame = CGRect(x: 0, y: self.frame.size.height - width, width:  self.frame.size.width, height: self.frame.size.height)
        border.borderWidth = width
        border.cornerRadius = width / 2
        self.layer.addSublayer(border)
        self.layer.masksToBounds = true
    }
}

extension UIViewController: UITextFieldDelegate {
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
