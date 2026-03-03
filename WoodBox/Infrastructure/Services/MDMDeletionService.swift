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
      guard let jamfClient = settings.jamfClient else { return }
      if record.jamfDeviceType == .mobile {
        try await jamfClient.deleteJamfMobileDevice(id: record.deviceId)
      } else {
        try await jamfClient.deleteJamfComputer(id: record.deviceId)
      }

    case .intune:
      guard let intuneClient = settings.intuneClient else { return }
      try await intuneClient.deleteIntuneDevice(id: record.deviceId)
    }
  }

  static func deleteAndRemove(
    record: MDMRecord,
    from device: Device,
    modelContext: ModelContext
  ) async throws {
    try await delete(record: record)

    device.mdmRecords.removeAll { $0.id == record.id }
    modelContext.delete(record)
  }
}
