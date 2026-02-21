//
//  SnipeITModels.swift
//  WoodBox
//
//  Created by Alexander Hyde on 8/2/2026.
//

import Foundation

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
