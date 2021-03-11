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
    @IBOutlet weak var deviceNameField: UITextField!
    @IBOutlet weak var majorLocationField: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var minorLocationField: UITextField!
    @IBOutlet weak var navbar: UINavigationBar!
    
    private let networkManager = NetworkManager.shared
    private let authSessionManager = AuthSessionManager.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hideKeyboardWhenTapped()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    @IBAction func saveButtonClicked(_ sender: Any) {
        let major = majorLocationField.text!
        let minor = minorLocationField.text!
        let deviceName = deviceNameField.text!
        if !minor.isEmpty && major.isEmpty {
            showSimpleAlert(title: "Invalid Input", description: "Missing Major Location.", onComplete: nil)
            return
        }
        var location: String? = nil
        if !major.isEmpty {
            location = major
        }
        if !minor.isEmpty {
            location = location! + "@@\(minor)"
        }
        networkManager.saveGuardian(userId: authSessionManager.currentUser!.userId, deviceId: UIDevice.current.identifierForVendor!.uuidString, location: location, nickname: deviceName) { [weak self] in
            self?.showSimpleAlert(title: "Success", description: "Guardian device successfully set up.", onComplete: {
                self?.performSegue(withIdentifier: "unwindToDetectionView", sender: nil)
            })
        } onError: { [weak self] in
            self?.showSimpleAlert(title: "Error", description: "Unable to set up Guardian device.", onComplete: {
                
            })
        }
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
