//
//  AuthSessionManager.swift
//  ReGuard
//
//  Created by Timothy Tong on 1/27/21.
//

import Foundation
import Amplify
import AmplifyPlugins

enum AuthState {
    case signUp
    case login
    case confirmCode(email: String)
    case session(user: AuthUser)
}

final class AuthSessionManager {
    static let shared = AuthSessionManager()
    
    var authState: AuthState = .login
    
    private init() {
        configureAmplify()
        getCurrentUser {}
    }
    
    private func configureAmplify() {
        do {
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.configure()
            print("Amplify configured successfully")
        } catch {
            print("Unable to configure amplify: \(error)")
        }
    }
    
    func getCurrentUser(onDone: () -> Void) {
        if let user = Amplify.Auth.getCurrentUser() {
            authState = .session(user: user)
            onDone()
        }
    }
    
    func showSignUp() {
        authState = .signUp
    }
    
    func showLogin() {
        authState = .login
    }
    
    func resendConfirmationCode(email: String, onDone: @escaping (() -> Void), onError: @escaping ((AuthError) -> Void)) {
        Amplify.Auth.resendSignUpCode(for: email) { result in
            switch result {
            case .success(let details):
                print("Resend sign up code success details", details)
                onDone()
            case .failure(let error):
                onError(error)
            }
        }
    }
    
    func login(email: String, password: String, onDone: @escaping ((AuthSignInResult) -> Void), onError: @escaping ((AuthError) -> Void)) {
        Amplify.Auth.signIn(username: email, password: password, options: nil, listener: { [weak self] result in
            switch result {
            case .success(let loginResult):
                print("Login result:", loginResult)
                if (loginResult.isSignedIn) {
                    self?.getCurrentUser() {
                        onDone(loginResult)
                    }
                } else {
                    onDone(loginResult)
                }
            case .failure(let error):
                print("Login error:", error)
                onError(error)
            }
        })
    }
    
    func signUp(email: String, password: String, onDone: @escaping (() -> Void), onError: @escaping ((AuthError) -> Void)) {
        Amplify.Auth.signUp(username: email, password: password, options: nil) { result in
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
                onError(error)
            }
        }
    }
    
    func confirm(email: String, code: String, onDone: @escaping (() -> Void), onError: @escaping ((AuthError) -> Void)) {
        Amplify.Auth.confirmSignUp(for: email, confirmationCode: code) { result in
            switch result {
            case.success(let confirmResult):
                print("Confirm result", confirmResult)
                if confirmResult.isSignupComplete {
                    onDone()
                }
            case .failure(let error):
                print("Failed to confirm code:", error)
                onError(error)
            }
        }
    }
    
    func logout(onDone: @escaping (() -> Void), onError: @escaping ((AuthError) -> Void)) {
        Amplify.Auth.signOut { result in
            print("Sign out result: \(result)")
            switch result {
            case .success(let signoutResult):
                self.authState = .login
                onDone()
            case .failure(let error):
                print("Error signing out: \(error)")
                onError(error)
            }
        }
    }
}
