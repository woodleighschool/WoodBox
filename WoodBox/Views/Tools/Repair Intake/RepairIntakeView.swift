//
//  RepairIntakeView.swift
//  WoodBox
//
//  Created by Alexander Hyde on 17/2/2026.
//

import SwiftData
import SwiftUI
import SwiftyJSON

struct RepairIntakeView: View {
  // MARK: - Properties

  @Environment(ModelData.self) private var modelData

  @Bindable var deviceSelection: DeviceSelectionState
  @State private var selectedSpare: Device?

  @State private var endUserName = ""
  @State private var endUserEmail = ""
  @State private var problem = ""
  @State private var notes = ""
  @State private var createCompNowTicket = true
  @State private var createFreshserviceTicket = true
  @State private var isSubmitting = false
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
            Task { await submit() }
          }
          .disabled(deviceSelection.selectedDevice == nil || problem.isEmpty)
          .buttonStyle(.borderedProminent)
        }
      }
    }
    .alert(item: $alertItem) { item in
      Alert(
        title: Text(item.title),
        message: Text(item.message),
        dismissButton: .default(Text("OK"))
      )
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
  }

  // MARK: - Private Helpers

  @MainActor
  private func submit() async {
    guard let device = deviceSelection.selectedDevice else { return }
    isSubmitting = true
    alertItem = nil

    do {
      var compNowTicketID: String?

      if createCompNowTicket, let compNowClient = modelData.settings.compNowClient {
        // Create CompNow ticket
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

        compNowTicketID = try await compNowClient.createCompNowTicket(ticket)
      }

      if createFreshserviceTicket, let freshserviceClient = modelData.settings.freshserviceClient {
        // Create Freshservice ticket
        var customFields: JSON = ["print_label": true] // Hardcoded specific
        if let spare = selectedSpare, !modelData.settings.freshserviceSpareField.isEmpty {
          customFields[modelData.settings.freshserviceSpareField] = JSON(spare.name!) // Assume spare name is always 'not nil'
        }
        if let cnTicket = compNowTicketID, !modelData.settings.freshserviceCompNowField.isEmpty {
          customFields[modelData.settings.freshserviceCompNowField] = JSON(cnTicket)
        }

        let ticket = FreshserviceTicketRequest(
          email: endUserEmail,
          subject: "REPAIR - \(problem)", // Hardcoded specific
          description: notes,
          status: .open,
          priority: .low,
          urgency: 1,
          impact: 1,
          category: "Hardware", // Hardcoded specific
          subCategory: "Computer", // Hardcoded specific
          itemCategory: "Mac", // Hardcoded specific
          responderID: 120_001_544_231, // Hardcoded specific
          tags: ["repair"], // Hardcoded specific
          customFields: customFields,
          workspaceID: modelData.settings.freshserviceWorkspaceID
        )

        _ = try await freshserviceClient.createFreshserviceTicket(ticket)
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
      set: { createCompNowTicket = $0 }
    )
  }

  private var freshserviceToggle: Binding<Bool> {
    Binding(
      get: { modelData.settings.freshserviceIsEnabled && createFreshserviceTicket },
      set: { createFreshserviceTicket = $0 }
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
        Text(spare.name ?? "").tag(spare as Device?)
      }
    }
  }
}
