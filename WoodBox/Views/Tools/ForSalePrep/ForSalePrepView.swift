//
//  ForSalePrepView.swift
//  WoodBox
//
//  Created by Alexander Hyde on 17/2/2026.
//

import SwiftData
import SwiftUI

struct ForSalePrepView: View {
  // MARK: - Properties

  @Environment(\.modelContext) private var modelContext
  @Environment(ModelData.self) private var modelData

  @Bindable var deviceSelection: DeviceSelectionState

  @State private var condition: DeviceCondition = .a
  @State private var notes: String = ""
  @State private var updateSnipeStatus: Bool = true
  @State private var deleteInMDM: Bool = false
  @State private var isSubmitting: Bool = false
  @State private var alertItem: AlertItem?
  @State private var showDeleteConfirmation: Bool = false
  @State private var showGradeHelp: Bool = false

  // MARK: - Computed Properties

  private var activeProviders: [String] {
    guard let device = deviceSelection.selectedDevice else { return [] }
    var providers: [String] = []

    if device.mdmRecords.contains(where: { $0.provider == .jamf }) {
      providers.append("Jamf")
    }
    if device.mdmRecords.contains(where: { $0.provider == .intune }) {
      providers.append("Intune")
    }

    return providers
  }

  // MARK: - Body

  var body: some View {
    Form {
      Section("Device") {
        DeviceSummaryCard(device: deviceSelection.selectedDevice, onClear: deviceSelection.clear)
      }

      Section("Condition") {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
          Picker("Condition Grade", selection: $condition) {
            ForEach(DeviceCondition.allCases, id: \.self) { condition in
              Text(condition.rawValue)
                .tag(condition)
            }
          }
          .pickerStyle(.segmented)

          Button {
            showGradeHelp = true
          } label: {
            Image(systemName: "info.circle")
              .foregroundStyle(.secondary)
          }
          .buttonStyle(.plain)
          .popover(isPresented: $showGradeHelp) {
            VStack(alignment: .leading, spacing: 8) {
              Text("Grade Guide")
                .font(.headline)
              gradeRow(label: "A", detail: "Like new, no visible wear, fully functional")
              gradeRow(label: "B", detail: "Minor cosmetic marks, fully functional")
              gradeRow(label: "C", detail: "Noticeable wear or scratches, fully functional")
              gradeRow(label: "D", detail: "Significant damage or defects, may have issues")
            }
            .padding()
            .frame(minWidth: 260)
          }
        }

        TextField("Notes", text: $notes, prompt: Text("Broken chinbar, missing some keys."), axis: .vertical)
          .lineLimit(3 ... 6)
      }

      Section("Automation") {
        Toggle(isOn: snipeToggle) {
          Label {
            Text("Update Snipe-IT Status")
          } icon: {
            Image("snipeit")
              .resizable()
              .scaledToFit()
              .padding(4)
              .background(.white, in: .rect(cornerRadius: 6))
          }
        }
        .disabled(!modelData.settings.snipeIsEnabled)

        if !activeProviders.isEmpty {
          Toggle(isOn: $deleteInMDM) {
            Label {
              Text("Delete device from \(activeProviders.joined(separator: " and "))")
            } icon: {
              Image(systemName: "trash")
                .foregroundStyle(.red)
            }
          }
        }
      }

      Button {
        if deleteInMDM, !activeProviders.isEmpty {
          showDeleteConfirmation = true
        } else {
          Task { await submit() }
        }
      } label: {
        Text("Process for Sale")
          .frame(maxWidth: .infinity)
      }
      .disabled(deviceSelection.selectedDevice == nil || isSubmitting)
      .buttonStyle(.borderedProminent)
    }
    .formStyle(.grouped)
    .deviceSearch(selection: deviceSelection)
    .alert("Confirm MDM Deletion", isPresented: $showDeleteConfirmation) {
      Button("Delete", role: .destructive) {
        Task { await submit() }
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("This will delete the device from \(activeProviders.joined(separator: " and ")).")
    }
    .alert(item: $alertItem) { item in
      Alert(
        title: Text(item.title),
        message: Text(item.message),
        dismissButton: .default(Text("OK"))
      )
    }
    .navigationTitle("For Sale Prep")
    .navigationSubtitle("Prepare devices for sale")
    .onChange(of: modelData.settings.snipeIsEnabled) { _, isEnabled in
      if !isEnabled { updateSnipeStatus = false }
    }
    .task {
      if !modelData.settings.snipeIsEnabled { updateSnipeStatus = false }
    }
  }

  // MARK: - Private Helpers

  @MainActor
  private func submit() async {
    guard let device = deviceSelection.selectedDevice else { return }
    isSubmitting = true
    alertItem = nil

    do {
      if deleteInMDM {
        if let record = device.mdmRecords.first {
          try await MDMDeletionService.deleteAndRemove(
            record: record,
            from: device,
            jamfClient: modelData.settings.jamfClient,
            intuneClient: modelData.settings.intuneClient
          )
        }
      }

      if updateSnipeStatus, let assetID = device.snipeID, let snipeClient = modelData.settings.snipeClient {
        try await snipeClient.checkinSnipeAsset(
          assetID: assetID,
          statusID: modelData.settings.snipeForSaleStatusID,
          note: "Marked for Sale via WoodBox"
        )
      }

      let history = SaleHistory(
        deviceSerial: device.serial,
        assetTag: device.assetTag,
        model: device.model ?? "Unknown",
        condition: condition,
        notes: notes
      )

      modelContext.insert(history)
      resetForm()

    } catch {
      alertItem = AlertItem(title: "Error", message: error.localizedDescription)
    }

    isSubmitting = false
  }

  private func resetForm() {
    deviceSelection.clear()
    condition = .a
    notes = ""
    deleteInMDM = false
    updateSnipeStatus = modelData.settings.snipeIsEnabled
    alertItem = nil
  }

  // MARK: - Toggle Bindings

  private var snipeToggle: Binding<Bool> {
    Binding(
      get: { modelData.settings.snipeIsEnabled && updateSnipeStatus },
      set: { newValue in
        guard modelData.settings.snipeIsEnabled else {
          updateSnipeStatus = false
          return
        }
        updateSnipeStatus = newValue
      }
    )
  }

  private func gradeRow(label: String, detail: String) -> some View {
    HStack(alignment: .top, spacing: 8) {
      Text(label)
        .font(.headline)
        .frame(width: 18, alignment: .leading)
      Text(detail)
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
  }
}
