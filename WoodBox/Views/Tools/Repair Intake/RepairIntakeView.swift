//
//  RepairIntakeView.swift
//  WoodBox
//
//  Created by Alexander Hyde on 17/2/2026.
//

import SwiftData
import SwiftUI

struct RepairIntakeView: View {
  // MARK: - Properties

  @Environment(ModelData.self) private var modelData

  @Bindable var deviceSelection: DeviceSelectionState
  @State private var selectedSpare: Device?

  @State private var endUserName: String = ""
  @State private var endUserEmail: String = ""
  @State private var problem: String = ""
  @State private var notes: String = ""
  @State private var createCompNowTicket: Bool = true
  @State private var createFreshserviceTicket: Bool = true
  @State private var isSubmitting: Bool = false
  @State private var alertItem: AlertItem?

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
        TextField("Problem", text: $problem, prompt: Text("e.g. Broken Screen"))

        SparePicker(spareStatusID: modelData.settings.snipeSpareStatusID, selection: $selectedSpare)
        TextField(
          "Notes", text: $notes,
          prompt: Text(
            "Customer states device won't turn on, observed liquid pouring out of the device. Suspected liquid damage."
          ),
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
        Toggle(isOn: compNowToggle) {
          Label {
            Text("Create CompNow Ticket")
          } icon: {
            Image("compnow")
              .resizable()
              .scaledToFit()
          }
        }
        .disabled(!modelData.settings.compNowIsEnabled)

        Toggle(isOn: freshserviceToggle) {
          Label {
            Text("Create Freshservice Ticket")
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
    .deviceSearch(selection: deviceSelection)
    .formStyle(.grouped)
    .toolbar {
      ToolbarItem(placement: .confirmationAction) {
        if isSubmitting {
          ProgressView().controlSize(.small)
        } else {
          Button("Submit") {
            Task { await submit() }
          }
          .disabled(deviceSelection.selectedDevice == nil || problem.isEmpty)
          .buttonStyle(.borderedProminent)
        }
      }
    }
    .onChange(of: deviceSelection.selectedDevice) { _, newDevice in
      if let newDevice {
        endUserName = newDevice.assignedUserName ?? ""
        endUserEmail = newDevice.assignedUserEmail ?? ""
      }
    }
    .onChange(of: modelData.settings.compNowIsEnabled) { _, isEnabled in
      if !isEnabled { createCompNowTicket = false }
    }
    .onChange(of: modelData.settings.freshserviceIsEnabled) { _, isEnabled in
      if !isEnabled { createFreshserviceTicket = false }
    }
    .task {
      if !modelData.settings.compNowIsEnabled { createCompNowTicket = false }
      if !modelData.settings.freshserviceIsEnabled { createFreshserviceTicket = false }
    }
    .alert(item: $alertItem) { item in
      Alert(
        title: Text(item.title),
        message: Text(item.message),
        dismissButton: .default(Text("OK"))
      )
    }
  }

  // MARK: - Private Helpers

  @MainActor
  private func submit() async {
    guard let device = deviceSelection.selectedDevice else { return }
    isSubmitting = true
    alertItem = nil

    do {
      var compNowTicketID: String?

      if createCompNowTicket, let client = modelData.settings.compNowClient {
        let ticket = CompNowTicket(
          endUser: endUserName,
          product: device.model,
          serial: device.serial,
          firstName: modelData.settings.compNowFirstName,
          lastName: modelData.settings.compNowLastName,
          address1: modelData.settings.compNowAddress,
          suburb: modelData.settings.compNowSuburb,
          state: modelData.settings.compNowState,
          postcode: modelData.settings.compNowPostcode,
          email: modelData.settings.compNowEmail,
          phone: modelData.settings.compNowPhone,
          stockCode: nil,
          extras: nil,
          fault: problem,
          condition: nil,
          reference: nil
        )

        compNowTicketID = try await client.createCompNowTicket(ticket)
      }

      if createFreshserviceTicket, let client = modelData.settings.freshserviceClient {
        var customFields: FreshserviceCustomFields = ["print_label": .bool(true)]
        if let spare = selectedSpare {
          customFields["student_spare"] = .string(spare.assetTag)
        }
        if let cnTicket = compNowTicketID {
          customFields["compnow_ticket_no"] = .string(cnTicket)
        }

        _ = try await client.createFreshserviceTicket(
          email: endUserEmail,
          subject: "REPAIR - \(problem)",
          description: notes,
          customFields: customFields,
          workspaceID: modelData.settings.freshserviceWorkspaceID
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
    problem = ""
    notes = ""
    selectedSpare = nil
    createCompNowTicket = modelData.settings.compNowIsEnabled
    createFreshserviceTicket = modelData.settings.freshserviceIsEnabled
    alertItem = nil
  }

  // MARK: - Toggle Bindings

  private var compNowToggle: Binding<Bool> {
    Binding(
      get: { modelData.settings.compNowIsEnabled && createCompNowTicket },
      set: { newValue in
        guard modelData.settings.compNowIsEnabled else {
          createCompNowTicket = false
          return
        }
        createCompNowTicket = newValue
      }
    )
  }

  private var freshserviceToggle: Binding<Bool> {
    Binding(
      get: { modelData.settings.freshserviceIsEnabled && createFreshserviceTicket },
      set: { newValue in
        guard modelData.settings.freshserviceIsEnabled else {
          createFreshserviceTicket = false
          return
        }
        createFreshserviceTicket = newValue
      }
    )
  }
}

// MARK: - Subviews

private struct SparePicker: View {
  @Query private var spareDevices: [Device]
  @Binding var selection: Device?

  init(spareStatusID: Int, selection: Binding<Device?>) {
    _selection = selection
    _spareDevices = Query(
      filter: #Predicate<Device> { $0.statusID == spareStatusID },
      sort: \Device.name
    )
  }

  var body: some View {
    Picker("Spare Device", selection: $selection) {
      Text("None").tag(nil as Device?)
      ForEach(spareDevices) { spare in
        Text(spare.name ?? spare.assetTag).tag(spare as Device?)
      }
    }
  }
}
