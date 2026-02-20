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

// MARK: - SettingsView

struct SettingsView: View {
  // MARK: - Properties

  @Environment(ModelData.self) private var modelData

  // MARK: - Body

  var body: some View {
    TabView {
      SnipeSettingsView(settings: modelData.settings, cacheManager: modelData.cacheManager)
        .tabItem { Label("Snipe-IT", systemImage: "server.rack") }

      JamfSettingsView(settings: modelData.settings, cacheManager: modelData.cacheManager)
        .tabItem { Label("Jamf Pro", systemImage: "laptopcomputer") }

      IntuneSettingsView(settings: modelData.settings, cacheManager: modelData.cacheManager)
        .tabItem { Label("Intune", systemImage: "window.ceiling") }

      FreshserviceSettingsView(settings: modelData.settings)
        .tabItem { Label("Freshservice", systemImage: "person.crop.circle.badge.questionmark") }

      CompNowSettingsView(settings: modelData.settings)
        .tabItem { Label("CompNow", systemImage: "shippingbox") }
    }
    .frame(minWidth: 500, minHeight: 400)
    .padding()
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

        HStack {
          Button("Test Connection") {
            Task { await testConnection() }
          }
          .disabled(isTesting || settings.snipeBaseURL.isEmpty)

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

      Section("Configuration") {
        TextField("Deployable Status ID", value: $settings.snipeDeployableStatusID, format: .number)
        TextField("For Sale Status ID", value: $settings.snipeForSaleStatusID, format: .number)
        TextField("Spare Status ID", value: $settings.snipeSpareStatusID, format: .number)
      }
    }
    .formStyle(.grouped)
  }

  @MainActor
  private func testConnection() async {
    isTesting = true
    testResult = nil

    if let url = URL(string: settings.snipeBaseURL) {
      let client = SnipeITClient(baseURL: url, apiToken: settings.snipeAPIKey)
      do {
        try await client.testSnipeConnection()
        testResult = .success
      } catch {
        testResult = .failure("Failed: \(error.localizedDescription)")
      }
    } else {
      testResult = .failure("Invalid URL")
    }

    isTesting = false
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

        HStack {
          Button("Test Connection") {
            Task { await testConnection() }
          }
          .disabled(isTesting || settings.jamfBaseURL.isEmpty)

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

    if let url = URL(string: settings.jamfBaseURL) {
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
    } else {
      testResult = .failure("Invalid URL")
    }

    isTesting = false
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

        HStack {
          Button("Test Connection") {
            Task { await testConnection() }
          }
          .disabled(isTesting)

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

    isTesting = false
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

        HStack {
          Button("Test Connection") {
            Task { await testConnection() }
          }
          .disabled(isTesting || settings.freshserviceBaseURL.isEmpty)

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

      Section("Configuration") {
        TextField("Workspace ID", value: $settings.freshserviceWorkspaceID, format: .number)
        TextField(
          "Return Service Item ID", value: $settings.freshserviceReturnedMachineServiceItemID,
          format: .number
        )
      }
    }
    .formStyle(.grouped)
  }

  // MARK: - Private Helpers

  @MainActor
  private func testConnection() async {
    isTesting = true
    testResult = nil

    if let url = URL(string: settings.freshserviceBaseURL) {
      let client = FreshserviceClient(baseURL: url, apiKey: settings.freshserviceAPIKey)
      do {
        try await client.testFreshserviceConnection()
        testResult = .success
      } catch {
        testResult = .failure("Failed: \(error.localizedDescription)")
      }
    } else {
      testResult = .failure("Invalid URL")
    }

    isTesting = false
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

        HStack {
          Button("Test Connection") {
            Task { await testConnection() }
          }
          .disabled(isTesting)

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

    isTesting = false
  }
}
