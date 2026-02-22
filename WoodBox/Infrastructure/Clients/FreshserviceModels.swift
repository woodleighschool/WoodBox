//
//  FreshserviceModels.swift
//  WoodBox
//
//  Created by Alexander Hyde on 8/2/2026.
//

import Foundation
import SwiftyJSON

// MARK: - Ticket Request/Response

struct FreshserviceTicketRequest: Encodable, Sendable {
  let email: String
  let subject: String
  let description: String
  let status: FreshserviceTicketStatus
  let priority: FreshserviceTicketPriority
  let urgency: Int
  let impact: Int
  let category: String?
  let subCategory: String?
  let itemCategory: String?
  let responderID: Int?
  let tags: [String]?
  let customFields: JSON?
  let workspaceID: Int?

  enum CodingKeys: String, CodingKey {
    case email, subject, description, status, priority, urgency, impact, category, tags
    case subCategory = "sub_category"
    case itemCategory = "item_category"
    case responderID = "responder_id"
    case customFields = "custom_fields"
    case workspaceID = "workspace_id"
  }
}

// MARK: - Ticket Response

struct FreshserviceTicketResponse: Decodable, Sendable {
  let ticket: FreshserviceTicket
}

struct FreshserviceTicket: Decodable, Sendable {
  let id: Int
}

// MARK: - Ticket enums

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

// MARK: - Service Request / Response

struct FreshserviceServiceRequest: Encodable, Sendable {
  let serviceItemDisplayID: Int // used for URL path, not encoded
  let email: String
  let quantity: Int = 1
  let customFields: [String: String]?
  let workspaceID: Int?

  enum CodingKeys: String, CodingKey {
    case email
    case quantity
    case customFields = "custom_fields"
    case workspaceID = "workspace_id"
    // serviceItemDisplayID intentionally omitted — used for URL path only
  }
}

struct FreshserviceServiceRequestResponse: Decodable, Sendable {
  let serviceRequest: FreshserviceServiceRequestResult

  enum CodingKeys: String, CodingKey {
    case serviceRequest = "service_request"
  }
}

struct FreshserviceServiceRequestResult: Decodable, Sendable {
  let id: Int
}
