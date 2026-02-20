//
//  ReturnedMachineView.swift
//  WoodBox
//
//  Created by Alexander Hyde on 17/2/2026.
//

import SwiftData
import SwiftUI

struct ReturnedMachineView: View {
  // MARK: - Properties

  @Environment(\.modelContext) private var modelContext
  @Environment(ModelData.self) private var modelData

  @Bindable var deviceSelection: DeviceSelectionState

  @State private var endUserName: String = ""
  @State private var endUserEmail: String = ""
  @State private var goodCondition: Bool = true
  @State private var hasCharger: Bool = true
  @State private var deleteInMDM: Bool = false
  @State private var updateSnipeStatus: Bool = true
  @State private var createFreshserviceRequest: Bool = true
  @State private var notes: String = ""
  @State private var isSubmitting: Bool = false
  @State private var alertItem: AlertItem?
  @State private var showDeleteConfirmation: Bool = false

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

      Section("Checklist") {
        Toggle("Good Condition", isOn: $goodCondition)
        Toggle("Has Charger", isOn: $hasCharger)
        TextField("Notes", text: $notes, prompt: Text("Missing some keys, will be $149 to be fixed..."), axis: .vertical)
          .lineLimit(3 ... 6)
      }

      Section("End User") {
        TextField("Name", text: $endUserName)
        TextField("Email", text: $endUserEmail)
      }

      Section("Automation") {
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

        Toggle(isOn: freshserviceToggle) {
          Label {
            Text("Create Return Ticket")
          } icon: {
            Image("freshservice")
              .resizable()
              .scaledToFit()
              .padding(4)
              .background(.white, in: .rect(cornerRadius: 6))
          }
        }
        .disabled(!modelData.settings.freshserviceIsEnabled)
      }

      Button {
        if deleteInMDM, !activeProviders.isEmpty {
          showDeleteConfirmation = true
        } else {
          Task { await submit() }
        }
      } label: {
        Text("Process Return")
          .frame(maxWidth: .infinity)
      }
      .disabled(deviceSelection.selectedDevice == nil || isSubmitting)
      .buttonStyle(.borderedProminent)
    }
    .formStyle(.grouped)
    .deviceSearch(selection: deviceSelection)
    .onChange(of: deviceSelection.selectedDevice?.serial) { _, _ in
      if let newDevice = deviceSelection.selectedDevice {
        endUserName = newDevice.assignedUserName ?? ""
        endUserEmail = newDevice.assignedUserEmail ?? ""
      }
    }
    .onChange(of: modelData.settings.snipeIsEnabled) { _, isEnabled in
      if !isEnabled { updateSnipeStatus = false }
    }
    .onChange(of: modelData.settings.freshserviceIsEnabled) { _, isEnabled in
      if !isEnabled { createFreshserviceRequest = false }
    }
    .task {
      if !modelData.settings.snipeIsEnabled { updateSnipeStatus = false }
      if !modelData.settings.freshserviceIsEnabled { createFreshserviceRequest = false }
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
    .navigationTitle("Returned Machine")
    .navigationSubtitle("Process returned devices")
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
          statusID: modelData.settings.snipeDeployableStatusID,
          note: "Returned via WoodBox"
        )
      }

      var ticketID: String?
      if createFreshserviceRequest, let fsClient = modelData.settings.freshserviceClient {
        let customFields: FreshserviceCustomFields = [
          "computer_returned_in_good_condition": .string(goodCondition ? "Yes" : "No"),
          "returned_with_working_charger": .string(hasCharger ? "Yes" : "No"),
          "notes": .string(notes),
        ]

        ticketID = try await fsClient.createFreshserviceServiceRequest(
          serviceItemDisplayID: modelData.settings.freshserviceReturnedMachineServiceItemID,
          email: endUserEmail,
          quantity: 1,
          customFields: customFields,
          workspaceID: modelData.settings.freshserviceWorkspaceID
        )
      }

      let history = ReturnHistory(
        timestamp: Date(),
        deviceSerial: device.serial,
        assetTag: device.assetTag,
        goodCondition: goodCondition,
        hasCharger: hasCharger,
        notes: notes,
        freshserviceTicketID: ticketID,
        assignedUser: endUserName
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
    endUserName = ""
    endUserEmail = ""
    goodCondition = true
    hasCharger = true
    deleteInMDM = false
    notes = ""
    updateSnipeStatus = modelData.settings.snipeIsEnabled
    createFreshserviceRequest = modelData.settings.freshserviceIsEnabled
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

  private var freshserviceToggle: Binding<Bool> {
    Binding(
      get: { modelData.settings.freshserviceIsEnabled && createFreshserviceRequest },
      set: { newValue in
        guard modelData.settings.freshserviceIsEnabled else {
          createFreshserviceRequest = false
          return
        }
        createFreshserviceRequest = newValue
      }
    )
  }
}
