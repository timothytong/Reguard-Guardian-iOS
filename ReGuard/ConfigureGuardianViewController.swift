//
//  ConfigureGuardianViewController.swift
//  ReGuard
//
//  Created by Timothy Tong on 2/7/21.
//

import Foundation
import UIKit

class ConfigureGuardianViewController: UIViewController {
    @IBOutlet weak var logoutButton: UIButton!
    private let authSessionManager = AuthSessionManager.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hideKeyboardWhenTapped()
    }
    
    @IBAction func logoutButtonClicked(_ sender: Any) {
        authSessionManager.logout {
            self.showSimpleAlert(title: "Success", description: "You have been logged out") {
                DispatchQueue.main.async {
                    (UIApplication.shared.delegate as? AppDelegate)?.renderRoot()
                }
            }
        } onError: { Error in
            self.showSimpleAlert(title: "Error", description: "Error signing out, please try again.", onComplete: nil)
        }

    }
}
