//
//  Histories.swift
//  WoodBox
//
//  Created by Alexander Hyde on 9/2/2026.
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - RepairHistory

@Model
final class RepairHistory {
  var timestamp: Date
  var deviceSerial: String
  var assetTag: String
  var problem: String

  var spareAssetTag: String?
  var notes: String?
  var compNowTicketID: String?
  var freshserviceTicketID: String?
  var assignedUser: String?

  init(
    timestamp: Date = Date(),
    deviceSerial: String,
    assetTag: String,
    problem: String,
    spareAssetTag: String? = nil,
    notes: String? = nil,
    compNowTicketID: String? = nil,
    freshserviceTicketID: String? = nil,
    assignedUser: String? = nil
  ) {
    self.timestamp = timestamp
    self.deviceSerial = deviceSerial
    self.assetTag = assetTag
    self.problem = problem
    self.spareAssetTag = spareAssetTag
    self.notes = notes
    self.compNowTicketID = compNowTicketID
    self.freshserviceTicketID = freshserviceTicketID
    self.assignedUser = assignedUser
  }
}

// MARK: - ReturnCheckInHistory

@Model
final class ReturnCheckInHistory {
  var timestamp: Date
  var deviceSerial: String
  var assetTag: String
  var goodCondition: Bool
  var hasCharger: Bool
  var notes: String?
  var freshserviceTicketID: String?
  var assignedUser: String?

  init(
    timestamp: Date = .now,
    deviceSerial: String,
    assetTag: String,
    goodCondition: Bool,
    hasCharger: Bool,
    notes: String? = nil,
    freshserviceTicketID: String? = nil,
    assignedUser: String? = nil
  ) {
    self.timestamp = timestamp
    self.deviceSerial = deviceSerial
    self.assetTag = assetTag
    self.goodCondition = goodCondition
    self.hasCharger = hasCharger
    self.notes = notes
    self.freshserviceTicketID = freshserviceTicketID
    self.assignedUser = assignedUser
  }
}

// MARK: - DeviceDeduplicationHistory

@Model
final class DeviceDeduplicationHistory {
  var timestamp: Date
  var deviceSerial: String
  var assetTag: String
  var removedProvider: String

  init(
    timestamp: Date = .now,
    deviceSerial: String,
    assetTag: String,
    removedProvider: String
  ) {
    self.timestamp = timestamp
    self.deviceSerial = deviceSerial
    self.assetTag = assetTag
    self.removedProvider = removedProvider
  }
}

// MARK: - SalePreparationHistory

enum DeviceCondition: String, Codable, CaseIterable {
  case a = "A"
  case b = "B"
  case c = "C"
  case d = "D"

  var color: Color {
    switch self {
    case .a: .green
    case .b: .blue
    case .c: .orange
    case .d: .red
    }
  }
}

@Model
final class SalePreparationHistory {
  var id: UUID
  var deviceSerial: String
  var assetTag: String
  var model: String
  var condition: DeviceCondition?
  var notes: String?

  init(
    deviceSerial: String,
    assetTag: String,
    model: String,
    condition: DeviceCondition? = nil,
    notes: String? = nil
  ) {
    id = UUID()
    self.deviceSerial = deviceSerial
    self.assetTag = assetTag
    self.model = model
    self.condition = condition
    self.notes = notes
  }
}
