//
//  SnipeITModels.swift
//  WoodBox
//
//  Created by Alexander Hyde on 8/2/2026.
//

import Foundation

// MARK: Check In Asset

/// Request
struct SnipeItCheckinRequest: Encodable, Sendable {
  let statusId: Int
  let name: String?
  let note: String?
  let locationId: String?

  private enum CodingKeys: String, CodingKey {
    case locationId = "location_id"
    case name
    case note
    case statusId = "status_id"
  }
}

// MARK: Update Asset

/// Request
struct SnipeItUpdateRequest: Encodable, Sendable {
  let statusId: Int?
  let notes: String?
  let customFields: [String: JSONValue]?

  private struct DynamicKey: CodingKey {
    var stringValue: String
    var intValue: Int? {
      nil
    }

    init(stringValue: String) {
      self.stringValue = stringValue
    }

    init?(intValue _: Int) {
      nil
    }
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: DynamicKey.self)
    try container.encodeIfPresent(statusId, forKey: .init(stringValue: "status_id"))
    try container.encodeIfPresent(notes, forKey: .init(stringValue: "notes"))
    if let customFields {
      for (key, value) in customFields {
        try container.encode(value, forKey: .init(stringValue: key))
      }
    }
  }
}

// MARK: Assets

/// Response
struct SnipeItAssetsResponse: Decodable {
  let rows: [SnipeItAssetResponse]
}

struct SnipeItAssetResponse: Decodable {
  let id: Int
  let name: String?
  let assetTag: String
  let serial: String
  let model: SnipeItAssetModel
  let category: SnipeItAssetCategory?
  let statusLabel: SnipeItAssetStatus?
  let assignedTo: SnipeItAssetUser?
  let notes: String?
  let warrantyExpires: SnipeItWarrantyDate?

  private enum CodingKeys: String, CodingKey {
    case assetTag = "asset_tag"
    case assignedTo = "assigned_to"
    case category
    case id
    case model
    case name
    case notes
    case serial
    case statusLabel = "status_label"
    case warrantyExpires = "warranty_expires"
  }
}

struct SnipeItWarrantyDate: Decodable {
  let date: String?
}

struct SnipeItAssetModel: Decodable {
  let name: String
}

struct SnipeItAssetCategory: Decodable {
  let name: String
}

struct SnipeItAssetStatus: Decodable {
  let id: Int
  let name: String
}

struct SnipeItAssetUser: Decodable {
  let name: String
  let email: String?
}
