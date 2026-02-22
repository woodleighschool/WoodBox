//
//  SalePreparationView.swift
//  WoodBox
//
//  Created by Alexander Hyde on 17/2/2026.
//

import SwiftData
import SwiftUI

struct SalePreparationView: View {
  // MARK: - Properties

  @Environment(\.modelContext) private var modelContext
  @Environment(ModelData.self) private var modelData

  @Bindable var deviceSelection: DeviceSelectionState

  @State private var condition: DeviceCondition = .a
  @State private var conditionDescription = ""
  @State private var updateSnipeStatus = true
  @State private var deleteInMDM = false
  @State private var isSubmitting = false
  @State private var alertItem: AlertItem?
  @State private var showDeleteConfirmation = false
  @State private var showGradeHelp = false

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
        DeviceSummaryCard(
          device: deviceSelection.selectedDevice,
          onClear: deviceSelection.clear
        )
      }

      Section {
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
              ForEach(DeviceCondition.allCases, id: \.self) { condition in
                gradeRow(condition)
              }
            }
            .presentationCompactAdaptation(.sheet)
          }
        }

        TextField(
          "Condition Description",
          text: $conditionDescription,
          prompt: Text("Broken chinbar, missing some keys."),
          axis: .vertical
        )
        .lineLimit(3 ... 6)
      } header: {
        Label("Details", systemImage: "pencil")
      }

      Section {
        Toggle(isOn: snipeToggle) {
          Label {
            Text("Update Snipe-IT Status")
          } icon: {
            Image("snipeit")
              .resizable()
              .scaledToFit()
          }
        }
        .disabled(!modelData.settings.snipeIsEnabled)

        // Only show button if device is in a MDM provider(s)
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
      } header: {
        Label("Automation", systemImage: "point.3.filled.connected.trianglepath.dotted")
      }
    }
    .formStyle(.grouped)
    .deviceSearch(selection: deviceSelection)
    .animation(
      .snappy(duration: 0.22, extraBounce: 0.06), value: deviceSelection.selectedDevice?.serial
    )
    .scrollDismissesKeyboard(.interactively)
    .toolbar {
      ToolbarItem(placement: .confirmationAction) {
        if isSubmitting {
          ProgressView().controlSize(.small)
        } else {
          Button("Submit") {
            if deleteInMDM, !activeProviders.isEmpty {
              showDeleteConfirmation = true
            } else {
              Task { await submit() }
            }
          }
          .disabled(deviceSelection.selectedDevice == nil)
          .buttonStyle(.borderedProminent)
        }
      }
    }
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
        // Remove device from MDM provider(s)
        if let record = device.mdmRecords.first { // Assumes there is only 1 device to exterminate...
          try await MDMDeletionService.deleteAndRemove(
            record: record,
            from: device,
            jamfClient: modelData.settings.jamfClient,
            intuneClient: modelData.settings.intuneClient,
            modelContext: modelContext
          )
        }
      }

      if updateSnipeStatus, let assetID = device.snipeID,
         let snipeClient = modelData.settings.snipeClient
      {
        var customFields: [String: String] = [:]
        if !modelData.settings.snipeConditionField.isEmpty {
          customFields[modelData.settings.snipeConditionField] = condition.rawValue
        }
        if !conditionDescription.isEmpty, !modelData.settings.snipeConditionNotesField.isEmpty {
          customFields[modelData.settings.snipeConditionNotesField] = conditionDescription
        }

        // Update Snipe-IT status
        try await snipeClient.updateSnipeAsset(
          SnipeUpdateRequest(
            assetID: assetID,
            statusID: modelData.settings.snipeForSaleStatusID,
            note: nil,
            customFields: customFields.isEmpty ? nil : customFields
          )
        )
      }

      resetForm()

    } catch {
      alertItem = AlertItem(title: "Error", message: error.localizedDescription)
    }

    isSubmitting = false
  }

  private func resetForm() {
    deviceSelection.clear()
    condition = .a
    conditionDescription = ""
    deleteInMDM = false
    updateSnipeStatus = modelData.settings.snipeIsEnabled
    alertItem = nil
  }

  // MARK: - Toggle Bindings

  private var snipeToggle: Binding<Bool> {
    Binding(
      get: { modelData.settings.snipeIsEnabled && updateSnipeStatus },
      set: { updateSnipeStatus = $0 }
    )
  }

  private func gradeRow(_ condition: DeviceCondition) -> some View {
    HStack(alignment: .top, spacing: 8) {
      Text(condition.rawValue)
        .font(.headline)
        .frame(width: 18, alignment: .leading)
      Text(condition.detail)
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
  }
}
