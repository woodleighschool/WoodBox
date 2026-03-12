//
//  AlertItem.swift
//  WoodBox
//
//  Created by Alexander Hyde on 8/2/2026.
//

import Foundation

struct AlertItem: Identifiable {
  // MARK: - Properties

  let id = UUID()
  let title: String
  let message: String
}

extension AlertItem {
  static func error(_ error: any Error) -> AlertItem {
    AlertItem(title: "Error", message: error.localizedDescription)
  }
}
