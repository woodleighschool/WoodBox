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

  @State private var endUserName = ""
  @State private var endUserEmail = ""
  @State private var problem = ""
  @State private var notes = ""
  @State private var createCompnowTicket = true
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

        SparePicker(
          spareStatusId: modelData.settings.snipeItSpareStatusId, selection: $selectedSpare
        )
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
        Toggle(isOn: compnowToggle) {
          Label {
            Text("Create Compnow Ticket")
          } icon: {
            Image("compnow")
              .resizable()
              .scaledToFit()
          }
        }
        .disabled(!modelData.settings.compnowIsEnabled)

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
    .onChange(of: modelData.settings.compnowIsEnabled) { _, isEnabled in
      if !isEnabled { createCompnowTicket = false }
    }
    .onChange(of: modelData.settings.freshserviceIsEnabled) { _, isEnabled in
      if !isEnabled { createFreshserviceTicket = false }
    }
    .task {
      if !modelData.settings.compnowIsEnabled { createCompnowTicket = false }
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
      var compnowTicketId: String?

      if createCompnowTicket, let compnowClient = modelData.settings.compnowClient {
        // Create Compnow ticket
        let ticket = CompnowTicketCreateRequest(
          endUser: endUserName,
          product: device.model,
          serial: device.serial,
          firstName: modelData.settings.compnowFirstName,
          lastName: modelData.settings.compnowLastName,
          address1: modelData.settings.compnowAddress,
          suburb: modelData.settings.compnowSuburb,
          state: modelData.settings.compnowState,
          postcode: modelData.settings.compnowPostcode,
          email: modelData.settings.compnowEmail,
          phone: modelData.settings.compnowPhone,
          stockCode: nil,
          extras: nil,
          fault: problem,
          condition: nil,
          reference: nil
        )

        compnowTicketId = try await compnowClient.createCompnowTicket(ticket)
      }

      if createFreshserviceTicket, let freshserviceClient = modelData.settings.freshserviceClient {
        // Create Freshservice ticket
        var customFields: [String: JSONValue] = ["print_label": .bool(true)] // Hardcoded specific
        if let spare = selectedSpare, !modelData.settings.freshserviceSpareField.isEmpty {
          customFields[modelData.settings.freshserviceSpareField] =
            spare.name.map(JSONValue.string) ?? .null
        }
        if let cnTicket = compnowTicketId, !modelData.settings.freshserviceCompnowField.isEmpty {
          customFields[modelData.settings.freshserviceCompnowField] = .string(cnTicket)
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
          responderId: 120_001_544_231, // Hardcoded specific
          tags: ["repair"], // Hardcoded specific
          customFields: customFields,
          workspaceId: modelData.settings.freshserviceWorkspaceId
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
    createCompnowTicket = modelData.settings.compnowIsEnabled
    createFreshserviceTicket = modelData.settings.freshserviceIsEnabled
    alertItem = nil
  }

  // MARK: - Toggle Bindings

  private var compnowToggle: Binding<Bool> {
    Binding(
      get: { modelData.settings.compnowIsEnabled && createCompnowTicket },
      set: { createCompnowTicket = $0 }
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

  init(spareStatusId: Int, selection: Binding<Device?>) {
    _selection = selection
    _spareDevices = Query(
      filter: #Predicate<Device> { $0.statusId == spareStatusId },
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
