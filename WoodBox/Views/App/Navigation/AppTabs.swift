//
//  AppTabs.swift
//  WoodBox
//
//  Created by Alexander Hyde on 21/2/2026.
//

import SwiftUI

enum AppTab: Hashable, Identifiable {
  case repairIntake
  case returnCheckIn
  case salePreparation
  case deviceDeduplication
  case settings

  var id: Self {
    self
  }

  var title: String {
    #if os(iOS)
      return ""
    #else
      switch self {
      case .repairIntake: return "Repair Intake"
      case .returnCheckIn: return "Return Check-In"
      case .salePreparation: return "Sale Preparation"
      case .deviceDeduplication: return "Device Deduplication"
      case .settings: return "Settings"
      }
    #endif
  }

  var symbol: String {
    switch self {
    case .repairIntake: "wrench.and.screwdriver"
    case .returnCheckIn: "arrow.uturn.left.circle"
    case .salePreparation: "tag"
    case .deviceDeduplication: "rectangle.on.rectangle.slash"
    case .settings: "gear"
    }
  }
}
