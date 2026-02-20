//
//  NavigationOptions.swift
//  WoodBox
//
//  Created by Alexander Hyde on 18/2/2026.
//

import SwiftUI

enum NavigationOption: String, CaseIterable, Identifiable, Hashable {
  case repairIntake = "Repair Intake"
  case deviceDeduplication = "Device Deduplication"
  case returnCheckIn = "Return Check-In"
  case salePreparation = "Sale Preparation"

  static let mainPages: [NavigationOption] = [.repairIntake, .returnCheckIn, .salePreparation, .deviceDeduplication]

  var id: String {
    rawValue
  }

  var name: String {
    rawValue
  }

  var symbolName: String {
    switch self {
    case .repairIntake: "wrench.and.screwdriver"
    case .deviceDeduplication: "rectangle.on.rectangle.slash"
    case .returnCheckIn: "arrow.uturn.left.circle"
    case .salePreparation: "tag"
    }
  }

  @MainActor
  @ViewBuilder
  func view(modelData: ModelData) -> some View {
    switch self {
    case .repairIntake:
      RepairIntakeView(deviceSelection: modelData.deviceSelection)
    case .deviceDeduplication:
      DeviceDeduplicationView()
    case .returnCheckIn:
      ReturnCheckInView(deviceSelection: modelData.deviceSelection)
    case .salePreparation:
      SalePreparationView(deviceSelection: modelData.deviceSelection)
    }
  }
}
