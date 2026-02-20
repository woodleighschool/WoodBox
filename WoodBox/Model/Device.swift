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
  var model: String?
  var category: String?

  var status: String?
  var statusID: Int?
  var snipeID: Int?

  var assignedUserName: String?
  var assignedUserEmail: String?
  var notes: String?

  var mdmRecords: [MDMRecord] = []

  // MARK: - Init

  init(serial: String, assetTag: String) {
    self.serial = serial
    self.assetTag = assetTag
  }
}

struct MDMRecord: Codable, Identifiable, Hashable, Sendable {
  var provider: MDMProvider
  var deviceID: String
  var deviceName: String?
  var lastCheckIn: Date?
  var jamfDeviceType: JamfDeviceType?

  var id: String {
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
