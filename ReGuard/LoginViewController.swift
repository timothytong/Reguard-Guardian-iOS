//
//  LoginViewController.swift
//  ReGuard
//
//  Created by Timothy Tong on 1/27/21.
//

import Foundation
import UIKit
import Amplify
import AmplifyPlugins

class LoginViewController: UIViewController {
    
    let authSessionManager = AuthSessionManager.shared
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = true
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        self.hideKeyboardWhenTapped()
        self.loginButton.layer.cornerRadius = 10
        super.viewDidLoad()
    }
 
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "SignUpButtonClickedSegue" {
            (segue.destination as! SignupViewController).authSessionManager = authSessionManager
        } else if segue.identifier == "LoginToConfirmCodeVCSegue" {
            let vc = segue.destination as! ConfirmCodeViewController
            vc.email = emailField.text
        }
    }
    
    @IBAction func loginButtonClicked(_ sender: Any) {
        authSessionManager.login(email: emailField.text!, password: passwordField.text!, onDone: { result in
            if (result.isSignedIn) {
                print("Signed in, rerendering root")
                DispatchQueue.main.async {
                    (UIApplication.shared.delegate as! AppDelegate).renderRoot()
                }
                return
            }
            switch result.nextStep {
            case .confirmSignUp(let info):
                print("Confirm sign up with additional info", info)
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "LoginToConfirmCodeVCSegue", sender: nil)
                }
            default:
                print("I don't know what to do")
            }
            
            
        }, onError: { error in
            
        })
    }
    
    @IBAction func unwindToLogin(_ seg: UIStoryboardSegue) {
        
    }
}
