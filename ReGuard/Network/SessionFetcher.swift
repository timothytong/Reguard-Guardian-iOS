//
//  EventFetcher.swift
//  ReguardHub
//
//  Created by Timothy Tong on 1/17/21.
//

import Foundation
public struct SessionFetcher {
    
    private let urlRoot = "http://reguard-backend.eba-fb3wmizg.us-east-1.elasticbeanstalk.com"
    
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
}
