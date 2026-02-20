//
//  IntuneModels.swift
//  WoodBox
//
//  Created by Alexander Hyde on 8/2/2026.
//

import Foundation

// MARK: - Device Models

struct IntuneDevicePageResponse: Decodable {
  let value: [IntuneDevice]
  let nextLink: String?

  enum CodingKeys: String, CodingKey {
    case value
    case nextLink = "@odata.nextLink"
  }
}

struct IntuneDevice: Decodable {
  let id: String
  let deviceName: String?
  let serialNumber: String
  let lastSyncDateTime: String?
}
