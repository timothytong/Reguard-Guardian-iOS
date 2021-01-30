//
//  SignupViewController.swift
//  ReGuard
//
//  Created by Timothy Tong on 1/28/21.
//

import Foundation
import UIKit

class SignupViewController: UIViewController {
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    var authSessionManager: AuthSessionManager?
    
    override func viewDidLoad() {
        print("Session Manager:", authSessionManager)
    }
    
    @IBAction func confirmButtonClicked(_ sender: UIButton) {
        
        print("Email: \(emailField.text), password: \(passwordField.text)")
        if let email = emailField.text, let password = passwordField.text {
            self.authSessionManager?.signUp(email: email, password: password, onDone: {
                print("Done sign up!")
                DispatchQueue.main.async {
                    self.dismiss(animated: true)
                }
            }, onError: { error in
                DispatchQueue.main.async {
                    let dialog = UIAlertController(title:"Unable to Sign Up", message: error, preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .default, handler: {(alert:UIAlertAction!) -> Void in})
                    dialog.addAction(okAction)
                    self.present(dialog, animated: true, completion: nil)
                }
            })
        }
 
        // timothykytong@gmail.com
    }
   
}

