//
//  CheckinBatchView.swift
//  WoodBox
//
//  Created by Alexander Hyde on 23/2/2026.
//

import SwiftData
import SwiftUI

#if os(iOS)

  // MARK: - Entry Model

  @Observable
  @MainActor
  final class BatchCheckInEntry: Identifiable {
    var id: PersistentIdentifier {
      device.id
    }

    let device: Device

    var snipeItStatus: OpStatus = .idle
    var mdmStatus: OpStatus = .idle

    enum OpStatus: Equatable, Sendable {
      case idle, inProgress, success, failure
    }

    init(device: Device) {
      self.device = device
    }
  }

  // MARK: - Sheet

  struct BatchCheckInSheet: View {
    // MARK: - Properties

    @Environment(ModelData.self) private var modelData
    @Environment(\.modelContext) private var modelContext

    @State private var entries: [BatchCheckInEntry]
    @State private var isRunning = false

    init(devices: [Device]) {
      _entries = State(initialValue: devices.map(BatchCheckInEntry.init))
    }

    // MARK: - Body

    var body: some View {
      NavigationStack {
        List(entries) { entry in
          BatchCheckInItemRow(entry: entry)
        }
        .navigationTitle("Batch Check-In (\(entries.count))")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
      }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
      ToolbarItem(placement: .topBarTrailing) {
        ShareLink(item: csv, subject: Text("Batch Check-In")) {
          Label("Export", systemImage: "square.and.arrow.up")
        }
        .disabled(isRunning)
      }
      ToolbarItem(placement: .topBarTrailing) {
        Button {
          Task { await runUpdateStatus() }
        } label: {
          Label("Update Status", systemImage: "arrow.clockwise.circle")
        }
        .disabled(isRunning)
      }
      ToolbarItem(placement: .topBarTrailing) {
        Button(role: .destructive) {
          Task { await runDeleteMDM() }
        } label: {
          Label("Delete in MDM", systemImage: "trash")
        }
        .disabled(isRunning)
      }
    }

    // MARK: - CSV

    private var csv: String {
      var rows = ["Serial,Asset Tag,Model,Warranty Expires"]
      let formatter = ISO8601DateFormatter()
      for entry in entries {
        let warranty = entry.device.warrantyExpires.map { formatter.string(from: $0) } ?? ""
        let fields = [entry.device.serial, entry.device.assetTag, entry.device.model, warranty]
        rows.append(
          fields.map { "\"\($0.replacingOccurrences(of: "\"", with: "\"\""))\"" }
            .joined(separator: ",")
        )
      }
      return rows.joined(separator: "\n")
    }

    // MARK: - Actions

    @MainActor
    private func runUpdateStatus() async {
      guard !isRunning else { return }
      isRunning = true

      for entry in entries {
        if let assetId = entry.device.snipeItId,
           let snipeItClient = modelData.settings.snipeItClient
        {
          entry.snipeItStatus = .inProgress
          do {
            try await snipeItClient.checkinSnipeItAsset(
              assetId: assetId,
              request: SnipeItCheckinRequest(
                statusId: modelData.settings.snipeItDeployableStatusId,
                name: nil,
                note: "Returned via WoodBox Batch Check-In",
                locationId: nil
              )
            )
            entry.snipeItStatus = .success
          } catch {
            entry.snipeItStatus = .failure
          }
        }
      }

      isRunning = false
    }

    @MainActor
    private func runDeleteMDM() async {
      guard !isRunning else { return }
      isRunning = true

      for entry in entries {
        if !entry.device.mdmRecords.isEmpty {
          entry.mdmStatus = .inProgress
          do {
            for record in entry.device.mdmRecords {
              try await MDMDeletionService.deleteAndRemove(
                record: record,
                from: entry.device,
                jamfClient: modelData.settings.jamfClient,
                intuneClient: modelData.settings.intuneClient,
                modelContext: modelContext
              )
            }
            entry.mdmStatus = .success
          } catch {
            entry.mdmStatus = .failure
          }
        }
      }

      isRunning = false
    }
  }

  // MARK: - Row

  private struct BatchCheckInItemRow: View {
    let entry: BatchCheckInEntry

    // MARK: - Body

    var body: some View {
      HStack(spacing: 12) {
        Image(systemName: entry.device.symbolName)
          .font(.title3.weight(.semibold))
          .foregroundStyle(.white)
          .frame(width: 40, height: 40)
          .background(Color.accentColor, in: .rect(cornerRadius: 12))
          .symbolRenderingMode(.hierarchical)

        VStack(alignment: .leading, spacing: 3) {
          Text(entry.device.model)
            .font(.headline)
            .lineLimit(1)
          HStack(spacing: 8) {
            HStack(spacing: 3) {
              Image(systemName: "barcode")
              Text(entry.device.assetTag)
            }
            HStack(spacing: 3) {
              Image(systemName: "number")
              Text(entry.device.serial)
            }
            if let expires = entry.device.warrantyExpires {
              HStack(spacing: 3) {
                Image(systemName: "shield")
                Text(
                  expires.formatted(.dateTime.day(.twoDigits).month(.twoDigits).year(.twoDigits))
                )
              }
            }
          }
          .font(.caption.monospacedDigit())
          .foregroundStyle(.secondary)
          .lineLimit(1)
        }

        Spacer(minLength: 0)
        statusIndicators
      }
      .padding(.vertical, 2)
    }

    // MARK: - Status Indicators

    private var statusIndicators: some View {
      HStack(spacing: 6) {
        opIcon(entry.snipeItStatus)
        opIcon(entry.mdmStatus)
      }
      .animation(.smooth(duration: 0.2), value: entry.snipeItStatus)
      .animation(.smooth(duration: 0.2), value: entry.mdmStatus)
    }

    @ViewBuilder
    private func opIcon(_ status: BatchCheckInEntry.OpStatus) -> some View {
      switch status {
      case .idle:
        EmptyView()
      case .inProgress:
        ProgressView()
          .controlSize(.small)
          .transition(.scale.combined(with: .opacity))
      case .success:
        Image(systemName: "checkmark.circle.fill")
          .foregroundStyle(.green)
          .symbolRenderingMode(.hierarchical)
          .transition(.scale.combined(with: .opacity))
      case .failure:
        Image(systemName: "xmark.circle.fill")
          .foregroundStyle(.red)
          .symbolRenderingMode(.hierarchical)
          .transition(.scale.combined(with: .opacity))
      }
    }
  }
#endif
