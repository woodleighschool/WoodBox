//
//  Device.swift
//  WoodBox
//
//  Created by Alexander Hyde on 16/2/2026.
//

import Foundation
import SwiftData

@Model
final class Device {
  // MARK: - Properties

  @Attribute(.unique) var serial: String
  var assetTag: String

  var name: String?
  var model: String
  var category: String?

  var status: String?
  var statusID: Int?
  var snipeID: Int?

  var assignedUserName: String?
  var assignedUserEmail: String?
  var notes: String?
  var warrantyExpires: Date?

  @Relationship(deleteRule: .cascade) var mdmRecords: [MDMRecord]

  // MARK: - Init

  init(serial: String, assetTag: String, model: String) {
    self.serial = serial
    self.assetTag = assetTag
    self.model = model
    mdmRecords = []
  }
}

@Model
final class MDMRecord {
  @Attribute(.unique) var id: String
  var provider: MDMProvider
  var deviceID: String
  var deviceName: String?
  var lastCheckIn: Date?
  var jamfDeviceType: JamfDeviceType?

  @Relationship(inverse: \Device.mdmRecords) var device: Device?

  init(
    provider: MDMProvider,
    deviceID: String,
    deviceName: String?,
    lastCheckIn: Date?,
    jamfDeviceType: JamfDeviceType?,
    device: Device? = nil
  ) {
    id = Self.makeID(provider: provider, jamfDeviceType: jamfDeviceType, deviceID: deviceID)
    self.provider = provider
    self.deviceID = deviceID
    self.deviceName = deviceName
    self.lastCheckIn = lastCheckIn
    self.jamfDeviceType = jamfDeviceType
    self.device = device
  }

  /// Jamf IDs can sometimes overlap between mobile and computer records.
  private static func makeID(
    provider: MDMProvider, jamfDeviceType: JamfDeviceType?, deviceID: String
  ) -> String {
    "\(provider.rawValue)-\(jamfDeviceType?.rawValue ?? "na")-\(deviceID)"
  }
}

enum MDMProvider: String, Codable, CaseIterable, Identifiable, Sendable {
  case jamf = "Jamf"
  case intune = "Intune"

  var id: String {
    rawValue
  }
}

enum JamfDeviceType: String, Codable, Sendable {
  case computer = "Computer"
  case mobile = "Mobile"
}

// MARK: - Extensions

extension Device {
  var symbolName: String {
    let rules: [(String, String)] = [
      ("MacBook", "laptopcomputer"),
      ("iMac", "desktopcomputer"),
      ("Mac mini", "macmini"),
      ("Mac Pro", "macpro.gen3"),
      ("Mac Studio", "macstudio"),
      ("iPad", "ipad"),
      ("iPhone", "iphone"),
      ("iPod", "ipodtouch"),
      ("Apple TV", "appletv"),
    ]
    return rules.first(where: { model.contains($0.0) })?.1 ?? "questionmark"
  }
}
