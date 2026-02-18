//
//  FreshserviceClient.swift
//  WoodBox
//
//  Created by Alexander Hyde on 8/2/2026.
//

import Foundation

struct FreshserviceClient: Sendable {
  // MARK: - Properties

  private let apiKey: String
  private let baseURL: URL
  private let http = HTTPClient.shared

  // MARK: - Init

  init(baseURL: URL, apiKey: String) {
    self.baseURL = baseURL
    self.apiKey = apiKey
  }

  // MARK: - Public Methods

  func testFreshserviceConnection() async throws {
    _ = try await fetchFreshserviceTickets(limit: 1)
  }

  func createFreshserviceTicket(
    email: String,
    subject: String,
    description: String,
    customFields: FreshserviceCustomFields = [:],
    workspaceID: Int? = nil
  ) async throws -> String {
    let url = baseURL.appending(path: "api/v2/tickets")
    var request = authorizedRequest(url: url, method: "POST")

    let payload = FreshserviceTicketRequest(
      email: email,
      subject: subject,
      description: description,
      status: .open,
      priority: .low,
      customFields: customFields.isEmpty ? nil : customFields,
      workspaceID: workspaceID
    )

    request.httpBody = try JSONEncoder().encode(payload)

    let response = try await http.decode(
      FreshserviceTicketResponse.self,
      from: request,
      action: "create ticket",
      integration: "Freshservice"
    )
    return String(response.ticket.id)
  }

  func createFreshserviceServiceRequest(
    serviceItemDisplayID: Int,
    email: String,
    quantity: Int = 1,
    customFields: FreshserviceCustomFields = [:],
    workspaceID: Int? = nil
  ) async throws -> String {
    let url = baseURL.appending(path: "api/v2/service_catalog/items/\(serviceItemDisplayID)/place_request")
    var request = authorizedRequest(url: url, method: "POST")

    let payload = FreshserviceServiceRequest(
      email: email,
      quantity: quantity,
      customFields: customFields.isEmpty ? nil : customFields,
      workspaceID: workspaceID
    )

    request.httpBody = try JSONEncoder().encode(payload)

    let response = try await http.decode(
      FreshserviceServiceRequestResponse.self,
      from: request,
      action: "create service request",
      integration: "Freshservice"
    )
    return String(response.serviceRequest.id)
  }

  // MARK: - Private Helpers

  private func fetchFreshserviceTickets(limit: Int) async throws {
    let url = baseURL.appending(
      path: "api/v2/tickets",
      queryItems: [URLQueryItem(name: "per_page", value: "\(limit)")]
    )

    let request = authorizedRequest(url: url)
    _ = try await http.data(for: request, action: "test connection", integration: "Freshservice")
  }

  private func authorizedRequest(url: URL, method: String = "GET") -> URLRequest {
    var request = URLRequest(url: url)
    request.httpMethod = method
    request.setBasicAuth(username: apiKey, password: "X")
    request.setValue("application/json", forHTTPHeaderField: "Accept")

    if method != "GET" {
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }

    return request
  }
}
