//
//  ConfirmCodeViewController.swift
//  ReGuard
//
//  Created by Timothy Tong on 1/31/21.
//

import Foundation
import UIKit
import AmplifyPlugins

class ConfirmCodeViewController: UIViewController {
    
    @IBOutlet weak var codeTextField: OneTimeCodeTextField!
    @IBOutlet weak var resendCodeButton: UIButton!
    
    var email: String?
    var authSessionManager = AuthSessionManager.shared
    
    @IBAction func resendCodeBtnClicked(_ sender: Any) {
        guard let email = email else {
            print("Where tf is auth session mgr / email???")
            return
        }
        
        authSessionManager.resendConfirmationCode(email: email) { [weak self] in
            self?.showSimpleAlert(title: "Code Sent", description: "A new confirmation code has been sent.", onComplete: nil)
        } onError: { [weak self] error in
            self?.showSimpleAlert(title: "Error", description: "An error occurred while requesting a new code. Please try again", onComplete: nil)
        }

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    override func viewDidLoad() {
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        codeTextField.configure()
        codeTextField.didEnterLastDigit = { [weak self] code in
            guard let email = self?.email, let authManager = self?.authSessionManager else { return }
            authManager.confirm(email: email, code: code) {
                self?.showSimpleAlert(title: "Sign Up Complete", description: "Log in to activate guardian.", onComplete: {
                                        self?.performSegue(withIdentifier: "ConfirmCodeVCUnwindToLoginSegue", sender: nil)})
            } onError: { (error) in
                DispatchQueue.main.async {
                    self?.codeTextField.clear()
                }
                if let err = error.underlyingError as? AWSCognitoAuthError {
                    switch err {
                    case .codeExpired:
                        print("Code expired!")
                        self?.showSimpleAlert(title: "Code Expired", description: "Click \"Resend\" to request a new one.", onComplete: nil)
                        return
                    case .codeMismatch:
                        print("Incorrect code!")
                        self?.showSimpleAlert(title: "Invalid Code", description: "The code entered is invalid, please doublecheck the confirmation code.", onComplete: nil)
                        return
                    default:
                        print("Unknown error case")
                    }
                }
                self?.showSimpleAlert(title: "Unknown Error", description: error.localizedDescription, onComplete: {
                    self?.performSegue(withIdentifier: "ConfirmCodeVCUnwindToLoginSegue", sender: nil)
                })
            }
        }
    }
}
