//
//  DeviceDeduplicationView.swift
//  WoodBox
//
//  Created by Alexander Hyde on 17/2/2026.
//

import SwiftData
import SwiftUI

struct DeviceDeduplicationView: View {
  // MARK: - Properties

  @Environment(\.modelContext) private var modelContext
  @Environment(ModelData.self) private var modelData

  @Query(sort: \Device.serial) private var allDevices: [Device]

  @State private var pendingDeletionRecord: MDMRecord?
  @State private var pendingDeletionDevice: Device?
  @State private var alertItem: AlertItem?
  @State private var isProcessing: Bool = false

  // MARK: - Computed Properties

  private var duplicateGroups: [(device: Device, records: [MDMRecord])] {
    allDevices
      .filter { $0.mdmRecords.count > 1 }
      .map { (device: $0, records: $0.mdmRecords) }
  }

  // MARK: - Body

  var body: some View {
    Group {
      if duplicateGroups.isEmpty {
        ContentUnavailableView(
          "No Duplicates",
          systemImage: "checkmark.circle",
          description: Text("No devices found with multiple MDM records.")
        )
      } else {
        List {
          ForEach(duplicateGroups, id: \.device.serial) { group in
            DuplicateGroupSection(group: group, settings: modelData.settings) { record in
              pendingDeletionRecord = record
              pendingDeletionDevice = group.device
            }
          }
        }
      }
    }
    .alert(
      "Confirm Deletion",
      isPresented: Binding(
        get: { pendingDeletionRecord != nil },
        set: { if !$0 { pendingDeletionRecord = nil; pendingDeletionDevice = nil } }
      )
    ) {
      Button("Delete", role: .destructive) {
        if let record = pendingDeletionRecord, let device = pendingDeletionDevice {
          Task { await delete(record, from: device) }
        }
      }
      Button("Cancel", role: .cancel) {
        pendingDeletionRecord = nil
        pendingDeletionDevice = nil
      }
    } message: {
      if let record = pendingDeletionRecord {
        Text("Are you sure you want to delete this record from \(record.provider.rawValue)?")
      }
    }
    .overlay {
      if isProcessing {
        ProgressView()
          .padding()
          .background(.regularMaterial)
          .clipShape(RoundedRectangle(cornerRadius: 8))
      }
    }
    .alert(item: $alertItem) { item in
      Alert(
        title: Text(item.title),
        message: Text(item.message),
        dismissButton: .default(Text("OK"))
      )
    }
    .navigationTitle("Device Deduplication")
    .navigationSubtitle("Find and remove duplicate MDM records")
  }

  // MARK: - Private Methods

  private func delete(_ record: MDMRecord, from device: Device) async {
    isProcessing = true
    defer { isProcessing = false }

    do {
      try await MDMDeletionService.deleteAndRemove(
        record: record,
        from: device,
        jamfClient: modelData.settings.jamfClient,
        intuneClient: modelData.settings.intuneClient
      )

      let history = DeviceDeduplicationHistory(
        deviceSerial: device.serial,
        assetTag: device.assetTag,
        removedProvider: record.provider.rawValue
      )
      modelContext.insert(history)

    } catch {
      alertItem = AlertItem(title: "Error", message: error.localizedDescription)
    }

    pendingDeletionRecord = nil
    pendingDeletionDevice = nil
  }
}

// MARK: - Subviews

struct DuplicateGroupSection: View {
  let group: (device: Device, records: [MDMRecord])
  @Bindable var settings: AppSettings
  let onDelete: (MDMRecord) -> Void

  var body: some View {
    Section(header: Text("\(group.device.serial) • \(group.device.assetTag)")) {
      let sorted = group.records.sorted {
        ($0.lastCheckIn ?? .distantPast) > ($1.lastCheckIn ?? .distantPast)
      }
      let latestID = sorted.first?.id

      ForEach(sorted, id: \.id) { record in
        DuplicateRecordRow(
          record: record,
          isLatest: record.id == latestID,
          settings: settings
        ) {
          onDelete(record)
        }
      }
    }
  }
}

struct DuplicateRecordRow: View {
  let record: MDMRecord
  let isLatest: Bool
  let settings: AppSettings
  let onDelete: () -> Void

  @Environment(\.openURL) private var openURL

  private let relativeFormatter: RelativeDateTimeFormatter = {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .abbreviated
    return formatter
  }()

  var body: some View {
    HStack(spacing: 16) {
      ZStack(alignment: .topTrailing) {
        Image(record.provider.rawValue.lowercased())
          .resizable()
          .scaledToFit()
          .frame(width: 20, height: 20)
          .padding(4)
          .background(.white, in: RoundedRectangle(cornerRadius: 6, style: .continuous))

        if isLatest {
          Circle()
            .fill(.green)
            .frame(width: 8, height: 8)
            .offset(x: 2, y: -2)
        }
      }

      VStack(alignment: .leading, spacing: 4) {
        HStack(spacing: 6) {
          Text(record.deviceName ?? "")
            .font(.body.weight(.medium))
            .lineLimit(1)

          Text("\(record.deviceID)")
            .font(.caption.monospaced())
            .foregroundStyle(.secondary)
        }

        if let lastSeenText {
          Text(lastSeenText)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }

      Spacer()

      Button {
        if let url = mdmURL { openURL(url) }
      } label: {
        Image(systemName: "safari")
      }
      .buttonStyle(.borderless)
      .help("Open device in \(record.provider.rawValue)")
      .disabled(mdmURL == nil)

      Button(role: .destructive, action: onDelete) {
        Image(systemName: "trash")
      }
      .buttonStyle(.borderless)
      .help("Remove this MDM record")
    }
  }

  private var lastSeenText: String? {
    guard let date = record.lastCheckIn else { return nil }
    let relative = relativeFormatter.localizedString(for: date, relativeTo: Date())
    return "Last seen \(relative)"
  }

  private var mdmURL: URL? {
    switch record.provider {
    case .intune:
      return URL(
        string: "https://intune.microsoft.com/#view/Microsoft_Intune_Devices/DeviceSettingsMenuBlade/~/overview/mdmDeviceId/\(record.deviceID)"
      )
    case .jamf:
      let endpoint = record.jamfDeviceType == .mobile ? "mobileDevices.html" : "computers.html"
      let urlString = "\(settings.jamfBaseURL)/\(endpoint)?id=\(record.deviceID)"

      return URL(string: urlString)
    }
  }
}
