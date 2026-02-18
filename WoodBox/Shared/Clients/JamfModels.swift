//
//  JamfModels.swift
//  WoodBox
//
//  Created by Alexander Hyde on 8/2/2026.
//

import Foundation

// MARK: - Computer Models

struct JamfComputersResponse: Decodable {
  let results: [JamfComputer]
}

struct JamfComputer: Decodable {
  let id: String
  let general: JamfComputerGeneral?
  let hardware: JamfComputerHardware
}

struct JamfComputerGeneral: Decodable {
  let name: String?
  let lastContactTime: String?
}

struct JamfComputerHardware: Decodable {
  let serialNumber: String
}

// MARK: - Mobile Device Models

struct JamfMobileDevicesResponse: Decodable {
  let results: [JamfMobileDevice]
}

struct JamfMobileDevice: Decodable {
  let mobileDeviceId: String
  let displayName: String?
  let general: JamfMobileDeviceGeneral?
  let hardware: JamfMobileDeviceHardware
}

struct JamfMobileDeviceGeneral: Decodable {
  let lastInventoryUpdateDate: String?
}

struct JamfMobileDeviceHardware: Decodable {
  let serialNumber: String
}
