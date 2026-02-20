//
//  AlertItem.swift
//  WoodBox
//
//  Created by Alexander Hyde on 8/2/2026.
//

import Foundation

struct AlertItem: Identifiable, Sendable {
  // MARK: - Properties

  let id = UUID()
  let title: String
  let message: String
}
