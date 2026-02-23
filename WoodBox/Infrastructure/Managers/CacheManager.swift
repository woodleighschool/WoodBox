//
//  CacheManager.swift
//  WoodBox
//
//  Created by Alexander Hyde on 9/2/2026.
//

import Foundation
import SwiftData
import SwiftUI

@Observable
@MainActor
final class CacheManager {
  // MARK: - Types

  enum Status: Equatable {
    case syncing(message: String)
    case synced(date: Date?)
    case failed(message: String, date: Date?)
  }

  // MARK: - Properties

  var status: Status = .synced(date: nil)

  var isSyncing: Bool {
    if case .syncing = status { return true }
    return false
  }

  @ObservationIgnored
  var lastSyncDate: Date? {
    get { UserDefaults.standard.object(forKey: "LastSyncDate") as? Date }
    set { UserDefaults.standard.set(newValue, forKey: "LastSyncDate") }
  }

  private let modelContext: ModelContext
  private let settings = AppSettings.shared

  // MARK: - Init

  init(modelContext: ModelContext) {
    self.modelContext = modelContext
    status = .synced(date: lastSyncDate)
  }

  // MARK: - Public Methods

  func sync() async {
    guard !isSyncing else { return }
    status = .syncing(message: "Syncing...")

    guard settings.snipeItIsEnabled else {
      try? clearDeviceCache()
      markAsSynced()
      return
    }

    do {
      async let snipeItAssets = fetchSnipeItAssets()
      async let jamfComputers = fetchJamfComputers()
      async let jamfMobiles = fetchJamfMobileDevices()
      async let intuneDevices = fetchIntuneDevices()

      try await process(
        snipeItAssets: snipeItAssets,
        jamfComputers: jamfComputers,
        jamfMobiles: jamfMobiles,
        intuneDevices: intuneDevices
      )

      markAsSynced()
    } catch {
      status = .failed(message: error.localizedDescription, date: Date())
    }
  }

  func purgeAllDeviceData() async {
    guard !isSyncing else { return }
    status = .syncing(message: "Purging...")

    try? clearDeviceCache()
    markAsSynced()
  }

  func removeMDMRecords(for providers: Set<MDMProvider>) async {
    guard !isSyncing, settings.snipeItIsEnabled else { return }
    status = .syncing(message: "Updating Records...")

    do {
      let devices = try modelContext.fetch(FetchDescriptor<Device>())
      for device in devices {
        let toRemove = device.mdmRecords.filter { providers.contains($0.provider) }
        for record in toRemove {
          modelContext.delete(record)
        }
        device.mdmRecords = device.mdmRecords.filter { !providers.contains($0.provider) }
      }
      try modelContext.save()
      markAsSynced()
    } catch {
      status = .failed(message: error.localizedDescription, date: Date())
    }
  }

  // MARK: - Fetchers

  private var snipeItClient: SnipeITClient? {
    guard settings.snipeItIsEnabled, let url = URL(string: settings.snipeItBaseURL) else {
      return nil
    }
    return SnipeITClient(baseURL: url, apiToken: settings.snipeItAPIKey)
  }

  private var jamfClient: JamfClient? {
    guard settings.snipeItIsEnabled, settings.jamfIsEnabled,
          let url = URL(string: settings.jamfBaseURL)
    else { return nil }
    return JamfClient(
      baseURL: url, clientId: settings.jamfClientId, clientSecret: settings.jamfClientSecret
    )
  }

  private var intuneClient: IntuneClient? {
    guard settings.snipeItIsEnabled, settings.intuneIsEnabled else { return nil }
    return IntuneClient(
      tenantId: settings.intuneTenantId, clientId: settings.intuneClientId,
      clientSecret: settings.intuneClientSecret
    )
  }

  private func fetchSnipeItAssets() async throws -> [SnipeItAssetResponse] {
    try await snipeItClient?.fetchSnipeItAssets() ?? []
  }

  private func fetchJamfComputers() async throws -> [JamfComputer] {
    try await jamfClient?.fetchJamfComputers() ?? []
  }

  private func fetchJamfMobileDevices() async throws -> [JamfMobileDevice] {
    try await jamfClient?.fetchJamfMobileDevices() ?? []
  }

  private func fetchIntuneDevices() async throws -> [IntuneDevice] {
    try await intuneClient?.fetchIntuneDevices() ?? []
  }

  // MARK: - Processing

  private func process(
    snipeItAssets: [SnipeItAssetResponse],
    jamfComputers: [JamfComputer],
    jamfMobiles: [JamfMobileDevice],
    intuneDevices: [IntuneDevice]
  ) async throws {
    let jamfComputerMap = Dictionary(grouping: jamfComputers, by: \.hardware.serialNumber)
    let jamfMobileMap = Dictionary(grouping: jamfMobiles, by: \.hardware.serialNumber)
    let intuneMap = Dictionary(grouping: intuneDevices, by: \.serialNumber)

    let existingDevices = try modelContext.fetch(FetchDescriptor<Device>())
    var deviceMap = Dictionary(uniqueKeysWithValues: existingDevices.map { ($0.serial, $0) })

    for asset in snipeItAssets {
      let serial = asset.serial

      let device: Device
      if let existing = deviceMap[serial] {
        device = existing
      } else {
        device = Device(serial: serial, assetTag: asset.assetTag, model: asset.model.name)
        modelContext.insert(device)
        deviceMap[serial] = device
      }

      device.assetTag = asset.assetTag
      device.name = asset.name.nilIfEmpty
      device.model = asset.model.name
      device.category = asset.category?.name.nilIfEmpty
      device.status = asset.statusLabel?.name.nilIfEmpty
      device.statusId = asset.statusLabel?.id
      device.snipeItId = asset.id
      device.notes = asset.notes.nilIfEmpty
      device.assignedUserName = asset.assignedTo?.name.nilIfEmpty
      device.assignedUserEmail = asset.assignedTo?.email.nilIfEmpty
      device.warrantyExpires = asset.warrantyExpires?.date.flatMap {
        try? Date($0, strategy: .iso8601)
      }

      // Refresh MDM records
      for record in device.mdmRecords {
        modelContext.delete(record)
      }

      let jamfComputerRecords: [MDMRecord] = (jamfComputerMap[serial] ?? []).map {
        MDMRecord(
          provider: .jamf,
          deviceId: $0.id,
          deviceName: $0.general.name.nilIfEmpty,
          lastCheckIn: $0.general.lastContactTime.flatMap { try? Date($0, strategy: .iso8601) },
          jamfDeviceType: .computer,
          device: device
        )
      }

      let jamfMobileRecords: [MDMRecord] = (jamfMobileMap[serial] ?? []).map {
        MDMRecord(
          provider: .jamf,
          deviceId: $0.mobileDeviceId,
          deviceName: $0.displayName.nilIfEmpty,
          lastCheckIn: $0.general.lastInventoryUpdateDate.flatMap {
            try? Date($0, strategy: .iso8601)
          },
          jamfDeviceType: .mobile,
          device: device
        )
      }

      let intuneRecords: [MDMRecord] = (intuneMap[serial] ?? []).map {
        MDMRecord(
          provider: .intune,
          deviceId: $0.id,
          deviceName: $0.deviceName.nilIfEmpty,
          lastCheckIn: $0.lastSyncDateTime.flatMap { try? Date($0, strategy: .iso8601) },
          jamfDeviceType: nil,
          device: device
        )
      }

      let records = jamfComputerRecords + jamfMobileRecords + intuneRecords

      for record in records {
        modelContext.insert(record)
      }
      device.mdmRecords = records
    }

    try modelContext.save()
  }

  // MARK: - Helpers

  private func markAsSynced() {
    let now = Date()
    lastSyncDate = now
    status = .synced(date: now)
  }

  private func clearDeviceCache() throws {
    try modelContext.delete(model: Device.self)
    try modelContext.save()
  }
}
