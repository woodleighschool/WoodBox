//
//  SnipeITClient.swift
//  WoodBox
//
//  Created by Alexander Hyde on 8/2/2026.
//

import Foundation

struct SnipeITClient: Sendable {
  // MARK: - Properties

  private let baseURL: URL
  private let apiToken: String
  private let http = HTTPClient.shared

  // MARK: - Init

  init(baseURL: URL, apiToken: String) {
    self.baseURL = baseURL
    self.apiToken = apiToken
  }

  // MARK: - Public Methods

  func testSnipeConnection() async throws {
    _ = try await fetchSnipeAssetsPage(limit: 1, offset: 0)
  }

  func fetchSnipeAssets() async throws -> [SnipeAsset] {
    var allAssets: [SnipeAsset] = []
    var offset = 0
    let limit = 200

    while true {
      let page = try await fetchSnipeAssetsPage(limit: limit, offset: offset)
      allAssets.append(contentsOf: page.rows)

      if page.rows.count < limit {
        break
      }
      offset += limit
    }

    return allAssets
  }

  func checkinSnipeAsset(assetID: Int, statusID: Int?, note: String? = nil) async throws {
    let url = baseURL.appending(path: "api/v1/hardware/\(assetID)/checkin")
    var request = authorizedRequest(url: url, method: "POST")

    var payload: [String: Any] = [:]
    if let statusID {
      payload["status_id"] = statusID
    }
    if let note, !note.isEmpty {
      payload["note"] = note
    }

    if !payload.isEmpty {
      request.httpBody = try JSONSerialization.data(withJSONObject: payload)
    }

    _ = try await http.data(for: request, action: "check-in asset", integration: "Snipe-IT")
  }

  // MARK: - Private Helpers

  private func fetchSnipeAssetsPage(limit: Int, offset: Int) async throws -> SnipeAssetsPage {
    let url = baseURL.appending(
      path: "api/v1/hardware",
      queryItems: [
        URLQueryItem(name: "limit", value: "\(limit)"),
        URLQueryItem(name: "offset", value: "\(offset)"),
      ]
    )
    let request = authorizedRequest(url: url)
    return try await http.decode(
      SnipeAssetsPage.self,
      from: request,
      action: "fetch assets",
      integration: "Snipe-IT"
    )
  }

  private func authorizedRequest(url: URL, method: String = "GET") -> URLRequest {
    var request = URLRequest(url: url)
    request.httpMethod = method
    request.setBearerToken(apiToken)
    request.setValue("application/json", forHTTPHeaderField: "Accept")

    if method != "GET" {
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }

    return request
  }
}
