//
//  SnipeITModels.swift
//  WoodBox
//
//  Created by Alexander Hyde on 8/2/2026.
//

import Foundation

// MARK: - Request Models

struct SnipeCheckinRequest: Encodable, Sendable {
  let assetID: Int // used for URL path, not encoded
  let statusID: Int?
  let note: String?

  private enum CodingKeys: String, CodingKey {
    case statusID = "status_id"
    case note
    // assetID intentionally omitted — used for URL path only
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encodeIfPresent(statusID, forKey: .statusID)
    if let note, !note.isEmpty {
      try container.encode(note, forKey: .note)
    }
  }
}

struct SnipeUpdateRequest: Encodable, Sendable {
  let assetID: Int // used for URL path, not encoded
  let statusID: Int?
  let note: String?
  let customFields: [String: String]?

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
    if let statusID {
      try container.encode(statusID, forKey: .init(stringValue: "status_id"))
    }
    if let note, !note.isEmpty {
      try container.encode(note, forKey: .init(stringValue: "notes"))
    }
    if let customFields {
      for (key, value) in customFields {
        try container.encode(value, forKey: .init(stringValue: key))
      }
    }
  }
}

// MARK: - Response Models

struct SnipeAssetsPage: Decodable {
  let rows: [SnipeAsset]
}

struct SnipeAsset: Decodable {
  let id: Int
  let name: String?
  let assetTag: String
  let serial: String
  let model: SnipeAssetModel
  let category: SnipeAssetCategory?
  let statusLabel: SnipeAssetStatus?
  let assignedTo: SnipeAssetUser?
  let notes: String?
  let warrantyExpires: SnipeDateValue?

  enum CodingKeys: String, CodingKey {
    case id, name, serial, model, category, notes
    case assetTag = "asset_tag"
    case statusLabel = "status_label"
    case assignedTo = "assigned_to"
    case warrantyExpires = "warranty_expires"
  }
}

struct SnipeDateValue: Decodable {
  let date: Date?

  private static let formatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd"
    f.locale = Locale(identifier: "en_US_POSIX")
    return f
  }()

  init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let raw = try container.decodeIfPresent(String.self, forKey: .date)
    date = raw.flatMap { Self.formatter.date(from: $0) }
  }

  private enum CodingKeys: String, CodingKey { case date }
}

struct SnipeAssetModel: Decodable {
  let name: String
}

struct SnipeAssetCategory: Decodable {
  let name: String
}

struct SnipeAssetStatus: Decodable {
  let id: Int
  let name: String
}

struct SnipeAssetUser: Decodable {
  let name: String
  let email: String?
}
