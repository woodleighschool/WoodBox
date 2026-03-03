//
//  FreshserviceModels.swift
//  WoodBox
//
//  Created by Alexander Hyde on 8/2/2026.
//

import Foundation

// MARK: Create Ticket

/// Request
struct FreshserviceTicketRequest: Encodable, Sendable {
  let email: String
  let subject: String
  let description: String
  let status: FreshserviceTicketStatus
  let priority: FreshserviceTicketPriority
  let tags: [String]?
  let customFields: [String: String]?
  let workspaceId: Int?

  enum CodingKeys: String, CodingKey {
    case customFields = "custom_fields"
    case description
    case email
    case priority
    case status
    case tags
    case subject
    case workspaceId = "workspace_id"
  }
}

/// Response
struct FreshserviceTicketResponse: Decodable, Sendable {
  let ticket: FreshserviceTicket
}

struct FreshserviceTicket: Decodable, Sendable {
  let id: Int
}

/// Misc
enum FreshserviceTicketStatus: Int, Codable, Sendable {
  case open = 2
  case pending = 3
  case resolved = 4
  case closed = 5
}

enum FreshserviceTicketPriority: Int, Codable, Sendable {
  case low = 1
  case medium = 2
  case high = 3
  case urgent = 4
}

// MARK: Service Requests

/// Request
struct FreshserviceServiceRequestCreateRequest: Encodable, Sendable {
  let email: String
  let quantity: Int = 1
  let customFields: [String: String]?
  let workspaceId: Int?

  init(email: String, customFields: [String: String]?, workspaceId: Int?) {
    self.email = email
    self.customFields = customFields?.isEmpty == true ? nil : customFields
    self.workspaceId = workspaceId
  }

  enum CodingKeys: String, CodingKey {
    case customFields = "custom_fields"
    case email
    case quantity
    case workspaceId = "workspace_id"
  }
}

/// Response
struct FreshserviceServiceRequestCreateResponse: Decodable, Sendable {
  let serviceRequest: FreshserviceServiceRequest

  enum CodingKeys: String, CodingKey {
    case serviceRequest = "service_request"
  }
}

struct FreshserviceServiceRequest: Decodable, Sendable {
  let id: Int
}
