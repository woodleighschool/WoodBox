//
//  MDMDeletionService.swift
//  WoodBox
//
//  Created by Alexander Hyde on 10/2/2026.
//

import Foundation

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
          try await jamfClient.deleteJamfMobileDevice(id: record.deviceID)
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
    intuneClient: IntuneClient?
  ) async throws {
    try await delete(record: record, jamfClient: jamfClient, intuneClient: intuneClient)

    // Remove from local model
    if let index = device.mdmRecords.firstIndex(where: { $0.id == record.id }) {
      device.mdmRecords.remove(at: index)
    }
  }
}
