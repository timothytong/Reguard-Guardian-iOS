//
//  AuthSessionManager.swift
//  ReGuard
//
//  Created by Timothy Tong on 1/27/21.
//

import Foundation
import Amplify

enum AuthState {
    case signUp
    case login
    case confirmCode(email: String)
    case session(user: AuthUser)
}

final class AuthSessionManager {
    var authState: AuthState = .login
    
    init() {
        getCurrentUser()
    }
    
    func getCurrentUser() {
        if let user = Amplify.Auth.getCurrentUser() {
            authState = .session(user: user)
        }
    }
    
    func showSignUp() {
        authState = .signUp
    }
    
    func showLogin() {
        authState = .login
    }
    
    func signUp(email: String, password: String, onDone: @escaping (() -> Void), onError: @escaping ((String) -> Void)) {
        Amplify.Auth.signUp(username: email, password: password, options: nil) { [weak self] result in
            switch result {
            case .success(let signupResult):
                print("Signup result:", signupResult)
                switch signupResult.nextStep {
                case .done:
                    print("Signup finished")
                    onDone()
                case .confirmUser(let details, _):
                    print(details ?? "no details")
                    onDone()
                }
            case .failure(let error):
                print("Signup error:", error)
                onError(error.errorDescription)
            }
        }
    }
    
    func confirm(email: String, code: String) {
        Amplify.Auth.confirmSignUp(for: email, confirmationCode: code) { [weak self] result in
            switch result {
            case.success(let confirmResult):
                print("Confirm result", confirmResult)
                if confirmResult.isSignupComplete {
                    DispatchQueue.main.async {
                        self?.showLogin()
                    }
                }
            case .failure(let error):
                print("Failed to confirm code:", error)
            }
        }
    }
}
