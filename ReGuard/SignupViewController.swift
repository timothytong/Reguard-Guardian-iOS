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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewDidLoad() {
        self.confirmButton.layer.cornerRadius = 19.5
        print("Session Manager:", authSessionManager)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        self.hideKeyboardWhenTapped()
        super.viewDidLoad()
    }
    
    @IBAction func confirmButtonClicked(_ sender: UIButton) {
        print("Email: \(emailField.text), password: \(passwordField.text)")
        if let email = emailField.text, let password = passwordField.text {
            self.authSessionManager?.signUp(email: email, password: password, onDone: {
                print("Done sign up!")
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "ShowConfirmCodeVCSegue", sender: email)
                }
            }, onError: { error in
                DispatchQueue.main.async {
                    print(error)
                    let dialog = UIAlertController(title:"Unable to Sign Up", message: error.errorDescription, preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .default, handler: {(alert:UIAlertAction!) -> Void in})
                    dialog.addAction(okAction)
                    self.present(dialog, animated: true, completion: nil)
                }
            })
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowConfirmCodeVCSegue" {
            let vc = segue.destination as! ConfirmCodeViewController
            vc.email = emailField.text
        }
    }
}
