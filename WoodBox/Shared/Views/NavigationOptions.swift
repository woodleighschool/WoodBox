//
//  NavigationOptions.swift
//  WoodBox
//
//  Created by Alexander Hyde on 18/2/2026.
//

import SwiftUI

enum NavigationOption: String, CaseIterable, Identifiable, Hashable {
  case bookRepair = "Repair"
  case returnedMachine = "Return"
  case forSalePrep = "Sale Prep"
  case deDuplicate = "De-Duplicate"

  static let mainPages: [NavigationOption] = [.bookRepair, .returnedMachine, .forSalePrep, .deDuplicate]

  var id: String {
    rawValue
  }

  var name: LocalizedStringResource {
    switch self {
    case .bookRepair: LocalizedStringResource("Repair", comment: "Navigate to repair booking")
    case .returnedMachine: LocalizedStringResource("Return", comment: "Navigate to returned machine processing")
    case .forSalePrep: LocalizedStringResource("Sale Prep", comment: "Navigate to sale preparation")
    case .deDuplicate: LocalizedStringResource("De-Duplicate", comment: "Navigate to duplicate cleanup")
    }
  }

  var symbolName: String {
    switch self {
    case .bookRepair: "wrench.and.screwdriver"
    case .returnedMachine: "arrow.uturn.left.circle"
    case .forSalePrep: "tag"
    case .deDuplicate: "rectangle.on.rectangle.slash"
    }
  }

  @MainActor
  @ViewBuilder
  func view(modelData: ModelData) -> some View {
    switch self {
    case .bookRepair:
      BookRepairView(deviceSelection: modelData.deviceSelection)
    case .returnedMachine:
      ReturnedMachineView(deviceSelection: modelData.deviceSelection)
    case .forSalePrep:
      ForSalePrepView(deviceSelection: modelData.deviceSelection)
    case .deDuplicate:
      DeDuplicateView()
    }
  }
}
