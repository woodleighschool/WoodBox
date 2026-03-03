//
//  DeviceScannerView.swift
//  WoodBox
//
//  Created by Alexander Hyde on 21/2/2026.
//

import SwiftData
import SwiftUI

#if os(iOS)

  struct DeviceScannerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Bindable var selection: DeviceSelectionState

    @State private var notFoundAlert: AlertItem?
    @State private var scanFeedback = false

    var body: some View {
      ScannerSheetView(
        title: "Scan asset tag or serial",
        subtitle: "Align the code in the frame",
        trigger: scanFeedback,
        onClose: { dismiss() },
        onCandidate: handleCandidate
      )
      .presentationDetents([.medium])
      .alert(item: $notFoundAlert) { item in
        Alert(
          title: Text(item.title),
          message: Text(item.message),
          dismissButton: .cancel(Text("Close"))
        )
      }
    }

    @MainActor
    func handleCandidate(_ value: String, type scanType: ScanType) {
      guard let device = modelContext.fetchDevice(matching: value, scanType: scanType) else {
        notFoundAlert = AlertItem(
          title: "Device Not Found",
          message: "No device with \(scanType.label) \"\(value)\" was found."
        )
        return
      }

      selection.select(device)
      scanFeedback.toggle()
      dismiss()
    }
  }

#endif
