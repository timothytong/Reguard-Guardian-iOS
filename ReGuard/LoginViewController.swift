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
    
    var authSessionManager: AuthSessionManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
 
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "SignUpButtonClickedSegue" {
            (segue.destination as! SignupViewController).authSessionManager = authSessionManager
        }
    }
}
