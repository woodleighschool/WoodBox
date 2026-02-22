//
//  SettingsView.swift
//  WoodBox
//
//  Created by Alexander Hyde on 17/2/2026.
//

import SwiftUI

// MARK: - Types

private enum ConnectionTestResult: Equatable {
  case success
  case failure(String)
}

private enum SettingsSection: CaseIterable, Identifiable {
  case snipe
  case jamf
  case intune
  case freshservice
  case compnow

  var id: Self {
    self
  }

  var title: String {
    switch self {
    case .snipe: "Snipe-IT"
    case .jamf: "Jamf Pro"
    case .intune: "Intune"
    case .freshservice: "Freshservice"
    case .compnow: "CompNow"
    }
  }

  var systemImage: String {
    switch self {
    case .snipe: "server.rack"
    case .jamf: "laptopcomputer"
    case .intune: "window.ceiling"
    case .freshservice: "person.crop.circle.badge.questionmark"
    case .compnow: "shippingbox"
    }
  }
}

// MARK: - SettingsView

struct SettingsView: View {
  // MARK: - Properties

  @Environment(ModelData.self) private var modelData

  // MARK: - Body

  var body: some View {
    #if os(macOS)
      TabView {
        settingsDestination(.snipe)
          .tabItem {
            Label(SettingsSection.snipe.title, systemImage: SettingsSection.snipe.systemImage)
          }

        settingsDestination(.jamf)
          .tabItem {
            Label(SettingsSection.jamf.title, systemImage: SettingsSection.jamf.systemImage)
          }

        settingsDestination(.intune)
          .tabItem {
            Label(SettingsSection.intune.title, systemImage: SettingsSection.intune.systemImage)
          }

        settingsDestination(.freshservice)
          .tabItem {
            Label(
              SettingsSection.freshservice.title,
              systemImage: SettingsSection.freshservice.systemImage
            )
          }

        settingsDestination(.compnow)
          .tabItem {
            Label(SettingsSection.compnow.title, systemImage: SettingsSection.compnow.systemImage)
          }
      }
      .frame(minWidth: 500, minHeight: 400)
      .padding()
    #else
      List(SettingsSection.allCases) { section in
        NavigationLink {
          settingsDestination(section)
            .navigationTitle(section.title)
        } label: {
          Label(section.title, systemImage: section.systemImage)
        }
        .contentTransition(.symbolEffect(.replace))
      }
      .navigationTitle("Settings")
    #endif
  }

  @ViewBuilder
  private func settingsDestination(_ section: SettingsSection) -> some View {
    switch section {
    case .snipe:
      SnipeSettingsView(settings: modelData.settings, cacheManager: modelData.cacheManager)
    case .jamf:
      JamfSettingsView(settings: modelData.settings, cacheManager: modelData.cacheManager)
    case .intune:
      IntuneSettingsView(settings: modelData.settings, cacheManager: modelData.cacheManager)
    case .freshservice:
      FreshserviceSettingsView(settings: modelData.settings)
    case .compnow:
      CompNowSettingsView(settings: modelData.settings)
    }
  }
}

// MARK: - Subviews

struct SnipeSettingsView: View {
  // MARK: - Properties

  @Bindable var settings: AppSettings
  let cacheManager: CacheManager

  @State private var isTesting = false
  @State private var testResult: ConnectionTestResult?

  // MARK: - Body

  var body: some View {
    Form {
      Section("Credentials") {
        Toggle("Enabled", isOn: $settings.snipeIsEnabled)
          .onChange(of: settings.snipeIsEnabled) { _, isOn in
            Task {
              if isOn {
                await cacheManager.sync()
              } else {
                settings.jamfIsEnabled = false
                settings.intuneIsEnabled = false
                await cacheManager.purgeAllDeviceData()
              }
            }
          }

        TextField("Base URL", text: $settings.snipeBaseURL)
        SecureField("API Key", text: $settings.snipeAPIKey)

        testRow(disabled: settings.snipeBaseURL.isEmpty) {
          await testConnection()
        }
      }

      Section("Configuration") {
        TextField("Deployable Status ID", value: $settings.snipeDeployableStatusID, format: .number)
        TextField("For Sale Status ID", value: $settings.snipeForSaleStatusID, format: .number)
        TextField("Spare Status ID", value: $settings.snipeSpareStatusID, format: .number)
        TextField("Condition Custom Field", text: $settings.snipeConditionField)
        TextField("Condition Notes Custom Field", text: $settings.snipeConditionNotesField)
      }
    }
    .formStyle(.grouped)
  }

  @MainActor
  private func testConnection() async {
    isTesting = true
    testResult = nil
    defer { isTesting = false }

    guard let url = URL(string: settings.snipeBaseURL) else {
      testResult = .failure("Invalid URL")
      return
    }

    let client = SnipeITClient(baseURL: url, apiToken: settings.snipeAPIKey)
    do {
      try await client.testSnipeConnection()
      testResult = .success
    } catch {
      testResult = .failure("Failed: \(error.localizedDescription)")
    }
  }

  private func testRow(disabled: Bool = false, action: @escaping @MainActor () async -> Void)
    -> some View
  {
    HStack {
      Button("Test Connection") { Task { await action() } }
        .disabled(isTesting || disabled)

      if isTesting { ProgressView().controlSize(.small) }

      switch testResult {
      case .success:
        Image(systemName: "checkmark.circle.fill")
          .foregroundStyle(.green)
      case let .failure(message):
        Image(systemName: "xmark.circle.fill")
          .foregroundStyle(.red)
          .help(message)
      case .none:
        EmptyView()
      }
    }
  }
}

struct JamfSettingsView: View {
  // MARK: - Properties

  @Bindable var settings: AppSettings
  let cacheManager: CacheManager

  @State private var isTesting = false
  @State private var testResult: ConnectionTestResult?

  // MARK: - Body

  var body: some View {
    Form {
      Section("Credentials") {
        Toggle("Enabled", isOn: $settings.jamfIsEnabled)
          .disabled(settings.snipeIsEnabled == false)
          .onChange(of: settings.jamfIsEnabled) { _, isOn in
            Task {
              if isOn {
                await cacheManager.sync()
              } else {
                await cacheManager.removeMDMRecords(for: [.jamf])
              }
            }
          }

        TextField("Base URL", text: $settings.jamfBaseURL)
        TextField("Client ID", text: $settings.jamfClientID)
        SecureField("Client Secret", text: $settings.jamfClientSecret)

        testRow(disabled: settings.jamfBaseURL.isEmpty) {
          await testConnection()
        }

        if settings.snipeIsEnabled == false {
          Text("Enable Snipe-IT first; Jamf only augments cached Snipe devices.")
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
      }
    }
    .formStyle(.grouped)
  }

  // MARK: - Private Helpers

  @MainActor
  private func testConnection() async {
    isTesting = true
    testResult = nil
    defer { isTesting = false }

    guard let url = URL(string: settings.jamfBaseURL) else {
      testResult = .failure("Invalid URL")
      return
    }

    let client = JamfClient(
      baseURL: url,
      clientID: settings.jamfClientID,
      clientSecret: settings.jamfClientSecret
    )
    do {
      try await client.testJamfConnection()
      testResult = .success
    } catch {
      testResult = .failure("Failed: \(error.localizedDescription)")
    }
  }

  private func testRow(disabled: Bool = false, action: @escaping @MainActor () async -> Void)
    -> some View
  {
    HStack {
      Button("Test Connection") { Task { await action() } }
        .disabled(isTesting || disabled)

      if isTesting { ProgressView().controlSize(.small) }

      switch testResult {
      case .success:
        Image(systemName: "checkmark.circle.fill")
          .foregroundStyle(.green)
      case let .failure(message):
        Image(systemName: "xmark.circle.fill")
          .foregroundStyle(.red)
          .help(message)
      case .none:
        EmptyView()
      }
    }
  }
}

struct IntuneSettingsView: View {
  // MARK: - Properties

  @Bindable var settings: AppSettings
  let cacheManager: CacheManager

  @State private var isTesting = false
  @State private var testResult: ConnectionTestResult?

  // MARK: - Body

  var body: some View {
    Form {
      Section("Credentials") {
        Toggle("Enabled", isOn: $settings.intuneIsEnabled)
          .disabled(settings.snipeIsEnabled == false)
          .onChange(of: settings.intuneIsEnabled) { _, isOn in
            Task {
              if isOn {
                await cacheManager.sync()
              } else {
                await cacheManager.removeMDMRecords(for: [.intune])
              }
            }
          }

        TextField("Tenant ID", text: $settings.intuneTenantID)
        TextField("Client ID", text: $settings.intuneClientID)
        SecureField("Client Secret", text: $settings.intuneClientSecret)

        testRow {
          await testConnection()
        }

        if settings.snipeIsEnabled == false {
          Text("Enable Snipe-IT first; Intune only augments cached Snipe devices.")
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
      }
    }
    .formStyle(.grouped)
  }

  // MARK: - Private Helpers

  @MainActor
  private func testConnection() async {
    isTesting = true
    testResult = nil
    defer { isTesting = false }

    let client = IntuneClient(
      tenantID: settings.intuneTenantID,
      clientID: settings.intuneClientID,
      clientSecret: settings.intuneClientSecret
    )

    do {
      try await client.testIntuneConnection()
      testResult = .success
    } catch {
      testResult = .failure("Failed: \(error.localizedDescription)")
    }
  }

  private func testRow(disabled: Bool = false, action: @escaping @MainActor () async -> Void)
    -> some View
  {
    HStack {
      Button("Test Connection") { Task { await action() } }
        .disabled(isTesting || disabled)

      if isTesting { ProgressView().controlSize(.small) }

      switch testResult {
      case .success:
        Image(systemName: "checkmark.circle.fill")
          .foregroundStyle(.green)
      case let .failure(message):
        Image(systemName: "xmark.circle.fill")
          .foregroundStyle(.red)
          .help(message)
      case .none:
        EmptyView()
      }
    }
  }
}

struct FreshserviceSettingsView: View {
  // MARK: - Properties

  @Bindable var settings: AppSettings

  @State private var isTesting = false
  @State private var testResult: ConnectionTestResult?

  // MARK: - Body

  var body: some View {
    Form {
      Section("Credentials") {
        Toggle("Enabled", isOn: $settings.freshserviceIsEnabled)
        TextField("Base URL", text: $settings.freshserviceBaseURL)
        SecureField("API Key", text: $settings.freshserviceAPIKey)

        testRow(disabled: settings.freshserviceBaseURL.isEmpty) {
          await testConnection()
        }
      }

      Section("Configuration") {
        TextField("Workspace ID", value: $settings.freshserviceWorkspaceID, format: .number)
        TextField(
          "Return Service Item ID",
          value: $settings.freshserviceReturnedMachineServiceItemID,
          format: .number
        )
        TextField("Return Condition Field", text: $settings.freshserviceReturnConditionField)
        TextField("Return Charger Field", text: $settings.freshserviceReturnChargerField)
        TextField("Return Notes Field", text: $settings.freshserviceReturnNotesField)
        TextField("Spare Field", text: $settings.freshserviceSpareField)
        TextField("CompNow Ticket Field", text: $settings.freshserviceCompNowField)
      }
    }
    .formStyle(.grouped)
  }

  // MARK: - Private Helpers

  @MainActor
  private func testConnection() async {
    isTesting = true
    testResult = nil
    defer { isTesting = false }

    guard let url = URL(string: settings.freshserviceBaseURL) else {
      testResult = .failure("Invalid URL")
      return
    }

    let client = FreshserviceClient(baseURL: url, apiKey: settings.freshserviceAPIKey)
    do {
      try await client.testFreshserviceConnection()
      testResult = .success
    } catch {
      testResult = .failure("Failed: \(error.localizedDescription)")
    }
  }

  private func testRow(disabled: Bool = false, action: @escaping @MainActor () async -> Void)
    -> some View
  {
    HStack {
      Button("Test Connection") { Task { await action() } }
        .disabled(isTesting || disabled)

      if isTesting { ProgressView().controlSize(.small) }

      switch testResult {
      case .success:
        Image(systemName: "checkmark.circle.fill")
          .foregroundStyle(.green)
      case let .failure(message):
        Image(systemName: "xmark.circle.fill")
          .foregroundStyle(.red)
          .help(message)
      case .none:
        EmptyView()
      }
    }
  }
}

struct CompNowSettingsView: View {
  // MARK: - Properties

  @Bindable var settings: AppSettings

  @State private var isTesting = false
  @State private var testResult: ConnectionTestResult?

  // MARK: - Body

  var body: some View {
    Form {
      Section("Credentials") {
        Toggle("Enabled", isOn: $settings.compNowIsEnabled)
        TextField("Username", text: $settings.compNowUsername)
        SecureField("Password", text: $settings.compNowPassword)
        SecureField("API Key", text: $settings.compNowAPIKey)

        testRow {
          await testConnection()
        }
      }

      Section("End User Details") {
        TextField("First Name", text: $settings.compNowFirstName)
        TextField("Last Name", text: $settings.compNowLastName)
        TextField("Address", text: $settings.compNowAddress)
        TextField("Suburb", text: $settings.compNowSuburb)
        TextField("State", text: $settings.compNowState)
        TextField("Postcode", text: $settings.compNowPostcode)
        TextField("Email", text: $settings.compNowEmail)
        TextField("Phone", text: $settings.compNowPhone)
      }
    }
    .formStyle(.grouped)
  }

  // MARK: - Private Helpers

  @MainActor
  private func testConnection() async {
    isTesting = true
    testResult = nil
    defer { isTesting = false }

    let client = CompNowClient(
      apiKey: settings.compNowAPIKey,
      username: settings.compNowUsername,
      password: settings.compNowPassword
    )

    do {
      try await client.testCompNowConnection()
      testResult = .success
    } catch {
      testResult = .failure("Failed: \(error.localizedDescription)")
    }
  }

  private func testRow(disabled: Bool = false, action: @escaping @MainActor () async -> Void)
    -> some View
  {
    HStack {
      Button("Test Connection") { Task { await action() } }
        .disabled(isTesting || disabled)

      if isTesting { ProgressView().controlSize(.small) }

      switch testResult {
      case .success:
        Image(systemName: "checkmark.circle.fill")
          .foregroundStyle(.green)
      case let .failure(message):
        Image(systemName: "xmark.circle.fill")
          .foregroundStyle(.red)
          .help(message)
      case .none:
        EmptyView()
      }
    }
  }
}
