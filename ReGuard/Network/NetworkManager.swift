//
//  EventFetcher.swift
//  ReguardHub
//
//  Created by Timothy Tong on 1/17/21.
//

import Foundation
public struct NetworkManager {
    
    static let shared = NetworkManager()
    private let encoder = JSONEncoder()
    
    private init() {
    }
    
    //private let urlRoot = "http://reguard-backend.eba-fb3wmizg.us-east-1.elasticbeanstalk.com"
    private let urlRoot = "http://localhost:3000"
    
    func getDeviceForUser(userId: String, deviceId: String, onComplete: @escaping (SingleDevice?) -> Void) {
        print("Loading user device..")
        guard let url = URL(string: "\(urlRoot)/api/v1/user/\(userId)/device/\(deviceId)") else {
            print("Unable to generate URL to retrieve Guardian Device")
            onComplete(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let err = error {
                print("Error fetching user guardian - \(err)")
                onComplete(nil)
            }
            guard let data = data else {
                print("Error - No guardian data returned")
                onComplete(nil)
                return
            }
            
            do {
                let deviceInfo = try JSONDecoder().decode(SingleDevice.self, from: data)
                print("Got an active device: \(deviceInfo)")
                onComplete(deviceInfo)
            } catch {
                print("Unable to decode response data to SingleDevicve: \(error)")
                onComplete(nil)
            }
            
        }.resume()
    }
    
    func getActiveSession(userId: String, deviceId: String, onComplete: @escaping (Session?) -> Void) {
        print("Loading active session..")
        guard let url = URL(string: "\(urlRoot)/api/v1/session/active?userId=\(userId)&deviceId=\(deviceId)") else {
            print("Unable to generate URL to retrieve ActiveSession")
            onComplete(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let err = error {
                print("Error fetching user session - \(err)")
                onComplete(nil)
            }
            guard let data = data else {
                print("Error - No session data returned")
                onComplete(nil)
                return
            }
            
            do {
                let activeSesh = try JSONDecoder().decode(ActiveSession.self, from: data)
                print("Got an active session: \(activeSesh)")
                onComplete(activeSesh.activeSession)
            } catch {
                print("Unable to decode response data to ActiveSession: \(error)")
            }
            
        }.resume()
    }
    
    func saveGuardian(userId: String, deviceId: String, location: String?, nickname: String?, onComplete: @escaping (() -> Void), onError: @escaping (() -> Void)) {
        
        guard let url = URL(string: "\(urlRoot)/api/v1/user/\(userId)/register_device") else { return }
        
        var request = URLRequest(url: url)
        
        let parameters = DeviceParams(id: deviceId, nickname: nickname, location: location)
        do {
            let data = try encoder.encode(parameters)
            request.httpBody = data
        } catch {
            print("Error encoding JSON.. \(error)")
        }
        standardPost(request: request, onComplete: onComplete, onError: onError)
    }
    
    private func standardPost(request: URLRequest, onComplete: (() -> Void)?, onError: (() -> Void)?) {
        var request = request
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let response = response as? HTTPURLResponse,
                  error == nil else {                                              // check for fundamental networking error
                print("error", error ?? "Unknown error")
                return
            }
            
            guard (200 ... 299) ~= response.statusCode else {                    // check for http errors
                print("statusCode should be 2xx, but is \(response.statusCode)")
                print("response = \(response)")
                onError?()
                return
            }
            
            let responseString = String(data: data, encoding: .utf8)
            print("responseString = \(responseString)")
            onComplete?()
        }.resume()
    }
}
