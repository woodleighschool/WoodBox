//
//  CompNowClient.swift
//  WoodBox
//
//  Created by Alexander Hyde on 8/2/2026.
//

import Foundation

struct CompNowClient: Sendable {
  // MARK: - Types

  private static let defaultBaseURL = URL(string: "https://test-api.compnow.com.au/request")!

  // MARK: - Properties

  private let baseURL: URL
  private let apiKey: String
  private let username: String
  private let password: String
  private let http = HTTPClient.shared

  // MARK: - Init

  init(
    baseURL: URL = Self.defaultBaseURL,
    apiKey: String,
    username: String,
    password: String
  ) {
    self.baseURL = baseURL
    self.apiKey = apiKey
    self.username = username
    self.password = password
  }

  // MARK: - Public Methods

  func testCompNowConnection() async throws {
    let request = try authorizedRequest(path: "repair/ticket/all", method: "GET")
    _ = try await http.data(for: request, action: "test connection", integration: "CompNow")
  }

  func createCompNowTicket(_ ticket: CompNowTicket) async throws -> String {
    var request = try authorizedRequest(path: "repair/ticket", method: "POST")
    request.httpBody = try JSONEncoder().encode(ticket)

    let response = try await http.decode(
      CompNowTicketCreateResponse.self,
      from: request,
      action: "create ticket",
      integration: "CompNow"
    )
    let ticketID = response.ticket.ticketId

    guard !ticketID.isEmpty else { throw URLError(.badServerResponse) }
    return ticketID
  }

  // MARK: - Private Helpers

  private func authorizedRequest(path: String, method: String) throws -> URLRequest {
    let url = baseURL.appending(path: path)

    var request = URLRequest(url: url)
    request.httpMethod = method
    request.setBasicAuth(username: username, password: password)
    request.setValue(apiKey, forHTTPHeaderField: "Cn-Api-Key")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    return request
  }
}
