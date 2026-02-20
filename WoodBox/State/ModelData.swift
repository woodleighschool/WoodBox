//
//  ModelData.swift
//  WoodBox
//
//  Created by Alexander Hyde on 18/2/2026.
//

import SwiftData
import SwiftUI

@Observable
@MainActor
final class ModelData {
  // MARK: - Scene + navigation

  var preferredColumn: NavigationSplitViewColumn = .detail
  var selectedOption: NavigationOption = .repairIntake
  var isInspectorPresented: Bool = false

  // MARK: - Domain state

  let settings: AppSettings
  let cacheManager: CacheManager
  let deviceSelection = DeviceSelectionState()

  // MARK: - Init

  init(modelContext: ModelContext, settings: AppSettings = .shared) {
    self.settings = settings
    cacheManager = CacheManager(modelContext: modelContext)
  }
}

// MARK: - Support types

@Observable
@MainActor
final class DeviceSelectionState {
  var query: String = ""
  var selectedDevice: Device?

  func select(_ device: Device) {
    selectedDevice = device
    query = ""
  }

  func clear() {
    selectedDevice = nil
    query = ""
  }
}
