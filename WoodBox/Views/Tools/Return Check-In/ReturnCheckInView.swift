//
//  ReturnCheckInView.swift
//  WoodBox
//
//  Created by Alexander Hyde on 17/2/2026.
//

import SwiftData
import SwiftUI

#if os(iOS)
  private struct BatchCheckInPayload: Identifiable {
    let id = UUID()
    let devices: [Device]
  }
#endif

struct ReturnCheckInView: View {
  // MARK: - Properties

  @Environment(\.modelContext) private var modelContext
  @Environment(ModelData.self) private var modelData

  @Bindable var deviceSelection: DeviceSelectionState

  @State private var endUserName = ""
  @State private var endUserEmail = ""
  @State private var goodCondition = true
  @State private var hasCharger = true
  @State private var deleteInMDM = false
  @State private var updateSnipeItStatus = true
  @State private var createFreshserviceRequest = true
  @State private var notes = ""
  @State private var isSubmitting = false
  @State private var alertItem: AlertItem?
  @State private var showDeleteConfirmation = false
  #if os(iOS)
    @State private var batchSheetPayload: BatchCheckInPayload?
  #endif

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
        Toggle("Good Condition", isOn: $goodCondition)
        Toggle("Has Charger", isOn: $hasCharger)
        TextField(
          "Notes", text: $notes, prompt: Text("Missing some keys, will be $149 to be fixed..."),
          axis: .vertical
        )
        .lineLimit(3 ... 6)
      } header: {
        Label("Details", systemImage: "pencil")
      }

      Section {
        TextField("Name", text: $endUserName)
        TextField("Email", text: $endUserEmail)
      } header: {
        Label("End User", systemImage: "person.crop.circle")
      }

      Section {
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

        Toggle(isOn: snipeItToggle) {
          Label {
            Text("Update Snipe-IT Status")
          } icon: {
            Image("snipeit")
              .resizable()
              .scaledToFit()
          }
        }
        .disabled(!modelData.settings.snipeItIsEnabled)

        Toggle(isOn: freshserviceToggle) {
          Label {
            Text("Create Service Request")
          } icon: {
            Image("freshservice")
              .resizable()
              .scaledToFit()
          }
        }
        .disabled(!modelData.settings.freshserviceIsEnabled)
      } header: {
        Label("Automation", systemImage: "point.3.filled.connected.trianglepath.dotted")
      }
    }
    .formStyle(.grouped)
    #if os(iOS)
      .deviceSearch(selection: deviceSelection) { devices in
        guard !devices.isEmpty else { return }
        batchSheetPayload = BatchCheckInPayload(devices: devices)
      }
      .sheet(item: $batchSheetPayload) { payload in
        BatchCheckInSheet(devices: payload.devices)
      }
    #else
      .deviceSearch(selection: deviceSelection)
    #endif
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
      .onChange(of: deviceSelection.selectedDevice?.serial) { _, _ in
        if let newDevice = deviceSelection.selectedDevice {
          endUserName = newDevice.assignedUserName ?? ""
          endUserEmail = newDevice.assignedUserEmail ?? ""
        }
      }
      .onChange(of: modelData.settings.snipeItIsEnabled) { _, isEnabled in
        if !isEnabled { updateSnipeItStatus = false }
      }
      .onChange(of: modelData.settings.freshserviceIsEnabled) { _, isEnabled in
        if !isEnabled { createFreshserviceRequest = false }
      }
      .task {
        if !modelData.settings.snipeItIsEnabled { updateSnipeItStatus = false }
        if !modelData.settings.freshserviceIsEnabled { createFreshserviceRequest = false }
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

      if updateSnipeItStatus, let assetId = device.snipeItId,
         let snipeItClient = modelData.settings.snipeItClient
      {
        // Update Snipe-IT status
        try await snipeItClient.checkinSnipeItAsset(
          assetId: assetId,
          request: SnipeItCheckinRequest(
            statusId: modelData.settings.snipeItDeployableStatusId,
            name: nil,
            note: "Returned via WoodBox",
            locationId: nil
          )
        )
      }

      if createFreshserviceRequest, let freshserviceClient = modelData.settings.freshserviceClient {
        // Create Freshservice service request
        var customFields: [String: JSONValue] = [:]
        if !modelData.settings.freshserviceReturnConditionField.isEmpty {
          customFields[modelData.settings.freshserviceReturnConditionField] =
            .string(goodCondition ? "Yes" : "No") // Hardcoded specific
        }
        if !modelData.settings.freshserviceReturnChargerField.isEmpty {
          customFields[modelData.settings.freshserviceReturnChargerField] =
            .string(hasCharger ? "Yes" : "No") // Hardcoded specific
        }
        if !modelData.settings.freshserviceReturnNotesField.isEmpty, !notes.isEmpty {
          customFields[modelData.settings.freshserviceReturnNotesField] = .string(notes)
        }

        _ = try await freshserviceClient.createFreshserviceServiceRequest(
          serviceItemId: modelData.settings.freshserviceReturnedMachineServiceItemId,
          request: FreshserviceServiceRequestCreateRequest(
            email: endUserEmail,
            customFields: customFields.isEmpty ? nil : customFields,
            workspaceId: modelData.settings.freshserviceWorkspaceId
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
    endUserName = ""
    endUserEmail = ""
    goodCondition = true
    hasCharger = true
    deleteInMDM = false
    notes = ""
    updateSnipeItStatus = modelData.settings.snipeItIsEnabled
    createFreshserviceRequest = modelData.settings.freshserviceIsEnabled
    alertItem = nil
  }

  // MARK: - Toggle Bindings

  private var snipeItToggle: Binding<Bool> {
    Binding(
      get: { modelData.settings.snipeItIsEnabled && updateSnipeItStatus },
      set: { updateSnipeItStatus = $0 }
    )
  }

  private var freshserviceToggle: Binding<Bool> {
    Binding(
      get: { modelData.settings.freshserviceIsEnabled && createFreshserviceRequest },
      set: { createFreshserviceRequest = $0 }
    )
  }
}
