//
//  UIViewControllerExtension.swift
//  ReGuard
//
//  Created by Timothy Tong on 2/1/21.
//

import UIKit

extension UIViewController {
    
    func hideKeyboardWhenTapped() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func showSimpleAlert(title: String, description: String, onComplete: (() -> Void)?) {
        DispatchQueue.main.async {
            let dialog = UIAlertController(title: title, message: description, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: {_ in onComplete?()})
            dialog.addAction(okAction)
            self.present(dialog, animated: true, completion: nil)
        }
    }
}
