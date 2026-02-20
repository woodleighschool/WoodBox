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

    guard settings.snipeIsEnabled else {
      try? clearDeviceCache()
      markAsSynced()
      return
    }

    do {
      async let snipeAssets = fetchSnipeAssets()
      async let jamfComputers = fetchJamfComputers()
      async let jamfMobiles = fetchJamfMobileDevices()
      async let intuneDevices = fetchIntuneDevices()

      let (snipe, jamfComps, jamfMobs, intune) = try await (
        snipeAssets, jamfComputers, jamfMobiles, intuneDevices
      )

      try await process(
        snipeAssets: snipe,
        jamfComputers: jamfComps,
        jamfMobiles: jamfMobs,
        intuneDevices: intune
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
    guard !isSyncing, settings.snipeIsEnabled else { return }
    status = .syncing(message: "Updating Records...")

    do {
      let devices = try modelContext.fetch(FetchDescriptor<Device>())
      for device in devices {
        device.mdmRecords.removeAll { providers.contains($0.provider) }
      }
      try modelContext.save()
      markAsSynced()
    } catch {
      status = .failed(message: error.localizedDescription, date: Date())
    }
  }

  // MARK: - Fetchers

  private var snipeClient: SnipeITClient? {
    guard settings.snipeIsEnabled, let url = URL(string: settings.snipeBaseURL) else { return nil }
    return SnipeITClient(baseURL: url, apiToken: settings.snipeAPIKey)
  }

  private var jamfClient: JamfClient? {
    guard settings.snipeIsEnabled, settings.jamfIsEnabled, let url = URL(string: settings.jamfBaseURL) else { return nil }
    return JamfClient(baseURL: url, clientID: settings.jamfClientID, clientSecret: settings.jamfClientSecret)
  }

  private var intuneClient: IntuneClient? {
    guard settings.snipeIsEnabled, settings.intuneIsEnabled else { return nil }
    return IntuneClient(tenantID: settings.intuneTenantID, clientID: settings.intuneClientID, clientSecret: settings.intuneClientSecret)
  }

  private func fetchSnipeAssets() async throws -> [SnipeAsset] {
    try await snipeClient?.fetchSnipeAssets() ?? []
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
    snipeAssets: [SnipeAsset],
    jamfComputers: [JamfComputer],
    jamfMobiles: [JamfMobileDevice],
    intuneDevices: [IntuneDevice]
  ) async throws {
    let jamfComputerMap = Dictionary(grouping: jamfComputers, by: \.hardware.serialNumber)
    let jamfMobileMap = Dictionary(grouping: jamfMobiles, by: \.hardware.serialNumber)
    let intuneMap = Dictionary(grouping: intuneDevices, by: \.serialNumber)

    let existingDevices = try modelContext.fetch(FetchDescriptor<Device>())
    var deviceMap = Dictionary(uniqueKeysWithValues: existingDevices.map { ($0.serial, $0) })

    for asset in snipeAssets {
      let serial = asset.serial

      let device: Device
      if let existing = deviceMap[serial] {
        device = existing
      } else {
        device = Device(serial: serial, assetTag: asset.assetTag)
        modelContext.insert(device)
        deviceMap[serial] = device
      }

      device.assetTag = asset.assetTag
      device.name = asset.name
      device.model = asset.model?.name
      device.category = asset.category?.name
      device.status = asset.statusLabel?.name
      device.statusID = asset.statusLabel?.id
      device.snipeID = asset.id
      device.notes = asset.notes
      device.assignedUserName = asset.assignedTo?.name
      device.assignedUserEmail = asset.assignedTo?.email

      device.mdmRecords = (jamfComputerMap[serial] ?? []).map {
        MDMRecord(
          provider: .jamf,
          deviceID: $0.id,
          deviceName: $0.general?.name,
          lastCheckIn: $0.general?.lastContactTime.flatMap { try? Date($0, strategy: .iso8601) },
          jamfDeviceType: .computer
        )
      } + (jamfMobileMap[serial] ?? []).map {
        MDMRecord(
          provider: .jamf,
          deviceID: $0.mobileDeviceId,
          deviceName: $0.displayName,
          lastCheckIn: $0.general?.lastInventoryUpdateDate.flatMap { try? Date($0, strategy: .iso8601) },
          jamfDeviceType: .mobile
        )
      } + (intuneMap[serial] ?? []).map {
        MDMRecord(
          provider: .intune,
          deviceID: $0.id,
          deviceName: $0.deviceName,
          lastCheckIn: $0.lastSyncDateTime.flatMap { try? Date($0, strategy: .iso8601) },
          jamfDeviceType: nil
        )
      }
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
    try modelContext.delete(model: Device.self) // Much faster than fetching and looping
    try modelContext.save()
  }
}
