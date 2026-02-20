//
//  FreshserviceModels.swift
//  WoodBox
//
//  Created by Alexander Hyde on 8/2/2026.
//

import Foundation

// MARK: - JSON Value for Freshservice payloads

enum FreshserviceJSONValue: Codable, Sendable {
  case string(String)
  case int(Int)
  case double(Double)
  case bool(Bool)
  case array([FreshserviceJSONValue])
  case object([String: FreshserviceJSONValue])
  case null

  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if container.decodeNil() {
      self = .null
    } else if let b = try? container.decode(Bool.self) {
      self = .bool(b)
    } else if let i = try? container.decode(Int.self) {
      self = .int(i)
    } else if let d = try? container.decode(Double.self) {
      self = .double(d)
    } else if let s = try? container.decode(String.self) {
      self = .string(s)
    } else if let array = try? container.decode([FreshserviceJSONValue].self) {
      self = .array(array)
    } else if let object = try? container.decode([String: FreshserviceJSONValue].self) {
      self = .object(object)
    } else {
      throw DecodingError.dataCorruptedError(
        in: container,
        debugDescription: "Unsupported JSON value"
      )
    }
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case let .string(s): try container.encode(s)
    case let .int(i): try container.encode(i)
    case let .double(d): try container.encode(d)
    case let .bool(b): try container.encode(b)
    case let .array(arr): try container.encode(arr)
    case let .object(obj): try container.encode(obj)
    case .null: try container.encodeNil()
    }
  }
}

typealias FreshserviceCustomFields = [String: FreshserviceJSONValue]

// MARK: - Ticket Request/Response

struct FreshserviceTicketRequest: Encodable, Sendable {
  let email: String
  let subject: String
  let description: String
  let status: FreshserviceTicketStatus
  let priority: FreshserviceTicketPriority
  let customFields: FreshserviceCustomFields?
  let workspaceID: Int?

  enum CodingKeys: String, CodingKey {
    case email
    case subject
    case description
    case status
    case priority
    case customFields = "custom_fields"
    case workspaceID = "workspace_id"
  }
}

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
  let email: String
  let quantity: Int
  let customFields: FreshserviceCustomFields?
  let workspaceID: Int?

  enum CodingKeys: String, CodingKey {
    case email
    case quantity
    case customFields = "custom_fields"
    case workspaceID = "workspace_id"
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
