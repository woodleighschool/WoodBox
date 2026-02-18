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
  let model: SnipeAssetModel?
  let category: SnipeAssetCategory?
  let statusLabel: SnipeAssetStatus?
  let assignedTo: SnipeAssetUser?
  let notes: String?

  enum CodingKeys: String, CodingKey {
    case id, name, serial, model, category, notes
    case assetTag = "asset_tag"
    case statusLabel = "status_label"
    case assignedTo = "assigned_to"
  }
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
