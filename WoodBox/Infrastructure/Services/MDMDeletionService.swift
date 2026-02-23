//
//  MDMDeletionService.swift
//  WoodBox
//
//  Created by Alexander Hyde on 10/2/2026.
//

import Foundation
import SwiftData

enum MDMDeletionService {
  static func delete(
    record: MDMRecord,
    jamfClient: JamfClient?,
    intuneClient: IntuneClient?
  ) async throws {
    switch record.provider {
    case .jamf:
      guard let jamfClient else {
        throw IntegrationError(action: "delete", integration: "Jamf", statusCode: -1)
      }
      if let type = record.jamfDeviceType {
        if type == .mobile {
          throw IntegrationError(action: "delete", integration: "Jamf", statusCode: -1) /// No DELETE for mobile devices...?
        } else {
          try await jamfClient.deleteJamfComputer(id: record.deviceID)
        }
      }

    case .intune:
      guard let intuneClient else {
        throw IntegrationError(action: "delete", integration: "Intune", statusCode: -1)
      }
      try await intuneClient.deleteIntuneDevice(id: record.deviceID)
    }
  }

  static func deleteAndRemove(
    record: MDMRecord,
    from device: Device,
    jamfClient: JamfClient?,
    intuneClient: IntuneClient?,
    modelContext: ModelContext?
  ) async throws {
    try await delete(record: record, jamfClient: jamfClient, intuneClient: intuneClient)

    // Remove from local model and delete the record entity
    let updated = device.mdmRecords.filter { $0.id != record.id }
    device.mdmRecords = updated
    modelContext?.delete(record)
  }
}
