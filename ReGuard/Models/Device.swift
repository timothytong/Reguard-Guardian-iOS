//
//  Device.swift
//  ReGuard
//
//  Created by Timothy Tong on 2/7/21.
//

import Foundation

struct Device: Hashable, Decodable, Identifiable {
    var id: String
    var name: String
    var location: String?
    var status: String
}

struct SingleDevice: Decodable {
    var device: Device?
}

struct DeviceList: Decodable {
    var devices: [Device]
}

struct DeviceParams: Codable {
    var id: String
    var nickname: String?
    var location: String?
}
