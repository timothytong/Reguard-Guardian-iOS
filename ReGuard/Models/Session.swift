//
//  Event.swift
//  ReguardHub
//
//  Created by Timothy Tong on 1/17/21.
//

import Foundation

struct Session: Hashable, Decodable {
    var sessionId: String
    var startTime: String
    var endTime: String?
    var initiatedByDeviceId: String?
    var initiatedByUserId: String?
}

struct ActiveSession: Decodable {
    var activeSession: Session?
}

extension Session: Identifiable {
    var id: Int { return hashValue }
}
