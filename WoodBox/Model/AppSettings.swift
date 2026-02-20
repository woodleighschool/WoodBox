//
//  AppSettings.swift
//  WoodBox
//
//  Created by Alexander Hyde on 16/2/2026.
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class AppSettings {
  // MARK: - Properties

  static let shared = AppSettings()

  // MARK: - Snipe-IT

  var snipeIsEnabled: Bool {
    didSet {
      UserDefaults.standard.set(snipeIsEnabled, forKey: "snipeIsEnabled")
    }
  }

  var snipeBaseURL: String {
    didSet {
      UserDefaults.standard.set(snipeBaseURL, forKey: "snipeBaseURL")
    }
  }

  var snipeAPIKey: String {
    didSet {
      KeychainHelper.shared.save(snipeAPIKey, key: "snipeAPIKey")
    }
  }

  var snipeForSaleStatusID: Int {
    didSet {
      UserDefaults.standard.set(snipeForSaleStatusID, forKey: "snipeForSaleStatusID")
    }
  }

  var snipeDeployableStatusID: Int {
    didSet {
      UserDefaults.standard.set(snipeDeployableStatusID, forKey: "snipeDeployableStatusID")
    }
  }

  var snipeSpareStatusID: Int {
    didSet {
      UserDefaults.standard.set(snipeSpareStatusID, forKey: "snipeSpareStatusID")
    }
  }

  // MARK: - Jamf

  var jamfIsEnabled: Bool {
    didSet {
      UserDefaults.standard.set(jamfIsEnabled, forKey: "jamfIsEnabled")
    }
  }

  var jamfBaseURL: String {
    didSet {
      UserDefaults.standard.set(jamfBaseURL, forKey: "jamfBaseURL")
    }
  }

  var jamfClientID: String {
    didSet {
      UserDefaults.standard.set(jamfClientID, forKey: "jamfClientID")
    }
  }

  var jamfClientSecret: String {
    didSet {
      KeychainHelper.shared.save(jamfClientSecret, key: "jamfClientSecret")
    }
  }

  // MARK: - Intune

  var intuneIsEnabled: Bool {
    didSet {
      UserDefaults.standard.set(intuneIsEnabled, forKey: "intuneIsEnabled")
    }
  }

  var intuneTenantID: String {
    didSet {
      UserDefaults.standard.set(intuneTenantID, forKey: "intuneTenantID")
    }
  }

  var intuneClientID: String {
    didSet {
      UserDefaults.standard.set(intuneClientID, forKey: "intuneClientID")
    }
  }

  var intuneClientSecret: String {
    didSet {
      KeychainHelper.shared.save(intuneClientSecret, key: "intuneClientSecret")
    }
  }

  // MARK: - Freshservice

  var freshserviceIsEnabled: Bool {
    didSet {
      UserDefaults.standard.set(freshserviceIsEnabled, forKey: "freshserviceIsEnabled")
    }
  }

  var freshserviceBaseURL: String {
    didSet {
      UserDefaults.standard.set(freshserviceBaseURL, forKey: "freshserviceBaseURL")
    }
  }

  var freshserviceAPIKey: String {
    didSet {
      KeychainHelper.shared.save(freshserviceAPIKey, key: "freshserviceAPIKey")
    }
  }

  var freshserviceWorkspaceID: Int {
    didSet {
      UserDefaults.standard.set(freshserviceWorkspaceID, forKey: "freshserviceWorkspaceID")
    }
  }

  var freshserviceReturnedMachineServiceItemID: Int {
    didSet {
      UserDefaults.standard.set(
        freshserviceReturnedMachineServiceItemID, forKey: "freshserviceReturnedMachineServiceItemID"
      )
    }
  }

  // MARK: - CompNow

  var compNowIsEnabled: Bool {
    didSet {
      UserDefaults.standard.set(compNowIsEnabled, forKey: "compNowIsEnabled")
    }
  }

  var compNowUsername: String {
    didSet {
      UserDefaults.standard.set(compNowUsername, forKey: "compNowUsername")
    }
  }

  var compNowPassword: String {
    didSet {
      KeychainHelper.shared.save(compNowPassword, key: "compNowPassword")
    }
  }

  var compNowAPIKey: String {
    didSet {
      KeychainHelper.shared.save(compNowAPIKey, key: "compNowAPIKey")
    }
  }

  // MARK: - CompNow Defaults

  var compNowFirstName: String {
    didSet {
      UserDefaults.standard.set(compNowFirstName, forKey: "compNowFirstName")
    }
  }

  var compNowLastName: String {
    didSet {
      UserDefaults.standard.set(compNowLastName, forKey: "compNowLastName")
    }
  }

  var compNowAddress: String {
    didSet {
      UserDefaults.standard.set(compNowAddress, forKey: "compNowAddress")
    }
  }

  var compNowSuburb: String {
    didSet {
      UserDefaults.standard.set(compNowSuburb, forKey: "compNowSuburb")
    }
  }

  var compNowState: String {
    didSet {
      UserDefaults.standard.set(compNowState, forKey: "compNowState")
    }
  }

  var compNowPostcode: String {
    didSet {
      UserDefaults.standard.set(compNowPostcode, forKey: "compNowPostcode")
    }
  }

  var compNowEmail: String {
    didSet {
      UserDefaults.standard.set(compNowEmail, forKey: "compNowEmail")
    }
  }

  var compNowPhone: String {
    didSet {
      UserDefaults.standard.set(compNowPhone, forKey: "compNowPhone")
    }
  }

  // MARK: - Init

  private init() {
    if let url = Bundle.main.url(forResource: "Defaults", withExtension: "plist"),
       let defaults = NSDictionary(contentsOf: url) as? [String: Any]
    {
      UserDefaults.standard.register(defaults: defaults)
    }

    let keychain = KeychainHelper.shared

    snipeIsEnabled = UserDefaults.standard.bool(forKey: "snipeIsEnabled")
    snipeBaseURL = UserDefaults.standard.string(forKey: "snipeBaseURL") ?? ""
    snipeAPIKey = keychain.read(key: "snipeAPIKey") ?? ""
    snipeForSaleStatusID = UserDefaults.standard.integer(forKey: "snipeForSaleStatusID")
    snipeDeployableStatusID = UserDefaults.standard.integer(forKey: "snipeDeployableStatusID")
    snipeSpareStatusID = UserDefaults.standard.integer(forKey: "snipeSpareStatusID")

    jamfIsEnabled = UserDefaults.standard.bool(forKey: "jamfIsEnabled")
    jamfBaseURL = UserDefaults.standard.string(forKey: "jamfBaseURL") ?? ""
    jamfClientID = UserDefaults.standard.string(forKey: "jamfClientID") ?? ""
    jamfClientSecret = keychain.read(key: "jamfClientSecret") ?? ""

    intuneIsEnabled = UserDefaults.standard.bool(forKey: "intuneIsEnabled")
    intuneTenantID = UserDefaults.standard.string(forKey: "intuneTenantID") ?? ""
    intuneClientID = UserDefaults.standard.string(forKey: "intuneClientID") ?? ""
    intuneClientSecret = keychain.read(key: "intuneClientSecret") ?? ""

    freshserviceIsEnabled = UserDefaults.standard.bool(forKey: "freshserviceIsEnabled")
    freshserviceBaseURL = UserDefaults.standard.string(forKey: "freshserviceBaseURL") ?? ""
    freshserviceAPIKey = keychain.read(key: "freshserviceAPIKey") ?? ""
    freshserviceWorkspaceID = UserDefaults.standard.integer(forKey: "freshserviceWorkspaceID")
    freshserviceReturnedMachineServiceItemID = UserDefaults.standard.integer(
      forKey: "freshserviceReturnedMachineServiceItemID"
    )

    compNowIsEnabled = UserDefaults.standard.bool(forKey: "compNowIsEnabled")
    compNowUsername = UserDefaults.standard.string(forKey: "compNowUsername") ?? ""
    compNowPassword = keychain.read(key: "compNowPassword") ?? ""
    compNowAPIKey = keychain.read(key: "compNowAPIKey") ?? ""

    compNowFirstName = UserDefaults.standard.string(forKey: "compNowFirstName") ?? ""
    compNowLastName = UserDefaults.standard.string(forKey: "compNowLastName") ?? ""
    compNowAddress = UserDefaults.standard.string(forKey: "compNowAddress") ?? ""
    compNowSuburb = UserDefaults.standard.string(forKey: "compNowSuburb") ?? ""
    compNowState = UserDefaults.standard.string(forKey: "compNowState") ?? ""
    compNowPostcode = UserDefaults.standard.string(forKey: "compNowPostcode") ?? ""
    compNowEmail = UserDefaults.standard.string(forKey: "compNowEmail") ?? ""
    compNowPhone = UserDefaults.standard.string(forKey: "compNowPhone") ?? ""
  }
}

// MARK: - Client Helpers

extension AppSettings {
  var compNowClient: CompNowClient? {
    guard compNowIsEnabled else { return nil }
    return CompNowClient(
      apiKey: compNowAPIKey,
      username: compNowUsername,
      password: compNowPassword
    )
  }

  var freshserviceClient: FreshserviceClient? {
    guard freshserviceIsEnabled, let url = URL(string: freshserviceBaseURL) else { return nil }
    return FreshserviceClient(baseURL: url, apiKey: freshserviceAPIKey)
  }

  var snipeClient: SnipeITClient? {
    guard snipeIsEnabled, let url = URL(string: snipeBaseURL) else { return nil }
    return SnipeITClient(baseURL: url, apiToken: snipeAPIKey)
  }

  var jamfClient: JamfClient? {
    guard jamfIsEnabled, let url = URL(string: jamfBaseURL) else { return nil }
    return JamfClient(baseURL: url, clientID: jamfClientID, clientSecret: jamfClientSecret)
  }

  var intuneClient: IntuneClient? {
    guard intuneIsEnabled else { return nil }
    return IntuneClient(
      tenantID: intuneTenantID,
      clientID: intuneClientID,
      clientSecret: intuneClientSecret
    )
  }
}
