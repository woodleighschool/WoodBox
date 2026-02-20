//
//  DevicePicker.swift
//  WoodBox
//
//  Created by Alexander Hyde on 9/2/2026.
//

import SwiftData
import SwiftUI

// MARK: - Public API

extension View {
  func deviceSearch(selection: DeviceSelectionState) -> some View {
    modifier(DeviceSearchModifier(selection: selection))
  }
}

// MARK: - Private

private struct DeviceSearchModifier: ViewModifier {
  @Bindable var selection: DeviceSelectionState
  @Query(sort: \Device.name) private var devices: [Device]

  func body(content: Content) -> some View {
    content
      .searchable(
        text: $selection.query,
        placement: .automatic,
        prompt: "Pick a Device..."
      )
      .searchSuggestions {
        ForEach(filteredDevices.prefix(25)) { device in
          VStack(alignment: .leading, spacing: 2) {
            Text(device.name ?? "")
            Text("\(device.assetTag) • \(device.serial)")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          .searchCompletion(device.assetTag)
          .onTapGesture {
            selection.select(device)
          }
        }
      }
      .onSubmit(of: .search) {
        guard let firstMatch = filteredDevices.first else { return }
        selection.select(firstMatch)
      }
  }

  private var filteredDevices: [Device] {
    let query = selection.query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !query.isEmpty else { return [] }

    return devices.filter { device in
      (device.name?.localizedStandardContains(query) ?? false)
        || device.serial.localizedStandardContains(query)
        || device.assetTag.localizedStandardContains(query)
        || (device.assignedUserName?.localizedStandardContains(query) ?? false)
    }
  }
}
