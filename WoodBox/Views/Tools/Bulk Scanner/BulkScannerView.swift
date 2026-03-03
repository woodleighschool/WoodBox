//
//  BulkScannerView.swift
//  WoodBox
//
//  Created by Alexander Hyde on 27/2/2026.
//

import SwiftData
import SwiftUI

#if os(iOS)

  struct BulkScannerView: View {
    // MARK: - Properties

    @Environment(\.modelContext) private var modelContext
    @Environment(ModelData.self) private var modelData

    @Query(sort: [SortDescriptor(\BulkScanHistoryItem.scannedAt, order: .reverse)])
    private var scanHistory: [BulkScanHistoryItem]

    @State private var alertItem: AlertItem?
    @State private var isBusy = false
    @State private var isScanningPresented = false
    @State private var showClearConfirmation = false
    @State private var showDeleteMDMConfirmation = false
    @State private var scanFeedback = false

    private static let csvFormatter = ISO8601DateFormatter()

    // MARK: - Computed Properties

    private var settings: AppSettings {
      modelData.settings
    }

    private var scannedDevices: [Device] {
      scanHistory.map(\.device)
    }

    private var hasMDMRecords: Bool {
      scannedDevices.contains { !$0.mdmRecords.isEmpty }
    }

    private var snipeStatusActions: [SnipeStatusAction] {
      [
        ("Stock", settings.snipeItStockStatusId),
        ("For Sale", settings.snipeItForSaleStatusId),
        ("Ready to Deploy", settings.snipeItReadyToDeployStatusId),
        ("Spare", settings.snipeItSpareStatusId),
      ]
      .filter { $0.1 > 0 }
      .map { SnipeStatusAction(title: $0.0, statusId: $0.1) }
    }

    private var exportCSV: String {
      var rows = ["Serial,Asset Tag,Model,Warranty Expires"]

      for device in scannedDevices {
        let warranty = device.warrantyExpires.map(Self.csvFormatter.string(from:)) ?? ""
        let fields = [device.serial, device.assetTag, device.model, warranty]
        rows.append(fields.map(csvEscape).joined(separator: ","))
      }

      return rows.joined(separator: "\n")
    }

    private var actionMenuDisabled: Bool {
      scanHistory.isEmpty || isBusy
    }

    // MARK: - Body

    var body: some View {
      reviewContent
        .navigationTitle("Bulk Scanner")
        .toolbar { toolbarContent }
        .confirmationDialog("Clear all scanned devices?", isPresented: $showClearConfirmation) {
          Button("Clear All", role: .destructive, action: clearHistory)
          Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog(
          "Delete scanned devices from MDM?", isPresented: $showDeleteMDMConfirmation
        ) {
          Button("Delete from MDM", role: .destructive) { Task { await deleteMDM() } }
          Button("Cancel", role: .cancel) {}
        }
        .alert(item: $alertItem) { item in
          Alert(
            title: Text(item.title),
            message: Text(item.message),
            dismissButton: .default(Text("OK"))
          )
        }
        .animation(.snappy(duration: 0.22, extraBounce: 0.06), value: scannedDevices.count)
        .sheet(isPresented: $isScanningPresented) {
          scannerSheet
            .presentationDetents([.medium])
        }
    }

    // MARK: - View Builders

    @ViewBuilder
    private var reviewContent: some View {
      if scanHistory.isEmpty {
        ContentUnavailableView {
          Label("No Devices Scanned", systemImage: "barcode.viewfinder")
        } description: {
          Text("Scan an asset tag barcode or serial number.")
        } actions: {
          Button {
            isScanningPresented = true
          } label: {
            Label("Start Scanning", systemImage: "camera.viewfinder")
          }
          .buttonStyle(.borderedProminent)
        }
      } else {
        List(scanHistory) { entry in
          BulkScannedDeviceRow(device: entry.device)
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
              Button("Remove", systemImage: "trash", role: .destructive) {
                removeHistory(entry)
              }
            }
        }
      }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
      ToolbarItem(placement: .topBarTrailing) {
        Button {
          isScanningPresented = true
        } label: {
          Image(systemName: "camera.viewfinder")
        }
        .disabled(isBusy)
      }

      ToolbarItem(placement: .topBarTrailing) {
        Menu {
          Button("Clear", systemImage: "trash", role: .destructive) {
            showClearConfirmation = true
          }

          ShareLink(item: exportCSV, subject: Text("Scanned Devices")) {
            Label("Export", systemImage: "square.and.arrow.up")
          }

          if settings.snipeItIsEnabled,
             settings.snipeItClient != nil,
             !snipeStatusActions.isEmpty
          {
            Section("Update Snipe-IT Status") {
              ForEach(snipeStatusActions) { action in
                Button(action.title) { Task { await updateSnipeStatus(action.statusId) } }
              }
            }
          }

          if hasMDMRecords {
            Divider()
            Button("Delete from MDM", systemImage: "iphone.slash", role: .destructive) {
              showDeleteMDMConfirmation = true
            }
          }
        } label: {
          Image(systemName: "ellipsis.circle")
        }
        .disabled(actionMenuDisabled)
      }
    }

    // MARK: - Private Helpers

    private var scannerSheet: some View {
      ScannerSheetView(
        title: "Scan asset tag or serial",
        subtitle: "Keep device centered in the frame",
        trigger: scanFeedback,
        onClose: { isScanningPresented = false },
        onCandidate: handleCandidate
      )
    }

    @MainActor
    private func handleCandidate(_ value: String, type scanType: ScanType) {
      guard !isBusy, !value.isEmpty else { return }

      guard let device = modelContext.fetchDevice(matching: value, scanType: scanType) else {
        alertItem = AlertItem(
          title: "Device Not Found",
          message: "No device with \(scanType.label) “\(value)” was found."
        )
        return
      }

      upsertHistory(device)
      scanFeedback.toggle()
    }

    @MainActor
    private func upsertHistory(_ device: Device) {
      if let existing = scanHistory.first(where: { $0.device == device }) {
        existing.scannedAt = Date()
      } else {
        modelContext.insert(BulkScanHistoryItem(device: device))
      }

      try? modelContext.save()
    }

    @MainActor
    private func removeHistory(_ entry: BulkScanHistoryItem) {
      modelContext.delete(entry)
      try? modelContext.save()
    }

    @MainActor
    private func clearHistory() {
      scanHistory.forEach(modelContext.delete)
      try? modelContext.save()
    }

    @MainActor
    private func updateSnipeStatus(_ statusId: Int) async {
      guard let client = settings.snipeItClient else { return }

      await withBusyState {
        guard !scannedDevices.isEmpty else { return }

        var updatedCount = 0
        var skippedCount = 0
        var failedCount = 0

        for device in scannedDevices {
          guard let assetId = device.snipeItId else {
            skippedCount += 1
            continue
          }

          do {
            try await client.checkinSnipeItAsset(
              assetId: assetId,
              request: SnipeItCheckinRequest(
                statusId: statusId,
                name: nil,
                note: nil,
                locationId: nil
              )
            )
            updatedCount += 1
          } catch {
            failedCount += 1
          }
        }

        if failedCount > 0 {
          alertItem = AlertItem(
            title: "Snipe-IT Update Completed with Errors",
            message: "Updated \(updatedCount), failed \(failedCount), skipped \(skippedCount)."
          )
        } else if updatedCount == 0 {
          alertItem = AlertItem(
            title: "No Snipe-IT Assets Updated",
            message: "No scanned devices had a Snipe-IT asset ID."
          )
        }
      }
    }

    @MainActor
    private func deleteMDM() async {
      await withBusyState {
        guard hasMDMRecords else { return }

        var deletedCount = 0
        var failedCount = 0

        for device in scannedDevices where !device.mdmRecords.isEmpty {
          for record in device.mdmRecords {
            do {
              try await MDMDeletionService.deleteAndRemove(
                record: record,
                from: device,
                modelContext: modelContext
              )
              deletedCount += 1
            } catch {
              failedCount += 1
            }
          }
        }

        if failedCount > 0 {
          alertItem = AlertItem(
            title: "MDM Deletion Completed with Errors",
            message: "Deleted \(deletedCount), failed \(failedCount)."
          )
        } else if deletedCount == 0 {
          alertItem = AlertItem(
            title: "No MDM Records Deleted",
            message: "None of the scanned devices have MDM records to delete."
          )
        }
      }
    }

    @MainActor
    private func withBusyState(_ operation: () async -> Void) async {
      guard !isBusy else { return }
      isBusy = true
      defer { isBusy = false }
      await operation()
    }

    private func csvEscape(_ value: String) -> String {
      "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
    }
  }

  // MARK: - Subviews

  private struct BulkScannedDeviceRow: View {
    let device: Device

    var body: some View {
      VStack(alignment: .leading, spacing: 6) {
        Text(device.model)
          .font(.headline)
          .lineLimit(1)

        HStack(spacing: 10) {
          if !device.assetTag.isEmpty {
            Label(device.assetTag, systemImage: "barcode")
          }

          Label(device.serial, systemImage: "number")

          if let expires = device.warrantyExpires {
            Label(
              expires.formatted(.dateTime.day(.twoDigits).month(.twoDigits).year(.twoDigits)),
              systemImage: "shield"
            )
          }
        }
        .font(.caption.monospacedDigit())
        .foregroundStyle(.secondary)
        .labelStyle(.titleAndIcon)
        .lineLimit(1)
      }
      .padding(.vertical, 4)
    }
  }

  // MARK: - Supporting Types

  private struct SnipeStatusAction: Identifiable {
    let title: String
    let statusId: Int

    var id: Int {
      statusId
    }
  }

#endif
