//
//  MDMDeletionService.swift
//  WoodBox
//
//  Created by Alexander Hyde on 10/2/2026.
//

import Foundation
import SwiftData

enum MDMDeletionService {
  static func delete(record: MDMRecord) async throws {
    let settings = AppSettings.shared
    switch record.provider {
    case .jamf:
      if let jamfClient = settings.jamfClient {
        if let type = record.jamfDeviceType {
          if type == .mobile {
            try await jamfClient.deleteJamfMobileDevice(id: record.deviceId)
          } else {
            try await jamfClient.deleteJamfComputer(id: record.deviceId)
          }
        }
      }

    case .intune:
      if let intuneClient = settings.intuneClient {
        try await intuneClient.deleteIntuneDevice(id: record.deviceId)
      }
    }
  }

  static func deleteAndRemove(
    record: MDMRecord,
    from device: Device,
    modelContext: ModelContext?
  ) async throws {
    try await delete(record: record)

    // Remove from local model and delete the record entity
    let updated = device.mdmRecords.filter { $0.id != record.id }
    device.mdmRecords = updated
    modelContext?.delete(record)
  }
}
