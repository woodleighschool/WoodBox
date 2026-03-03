//
//  ScannerSheetView.swift
//  WoodBox
//
//  Shared scaffold for camera-based scanning sheets.
//

import SwiftUI

#if os(iOS)

  struct ScannerSheetView<Trigger: Equatable>: View {
    let title: String
    let subtitle: String
    let trigger: Trigger
    let onClose: () -> Void
    let onCandidate: (String, ScanType) -> Void

    var body: some View {
      NavigationStack {
        GeometryReader { proxy in
          DeviceScannerCameraView(onCandidate: onCandidate)
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .ignoresSafeArea(edges: .bottom)
        .toolbar {
          ToolbarItem(placement: .principal) {
            VStack(spacing: 2) {
              Text(title).font(.headline)
              Text(subtitle).font(.footnote).foregroundStyle(.secondary)
            }
          }
          ToolbarItem(placement: .cancellationAction) {
            Button(action: onClose) {
              Image(systemName: "xmark")
            }
          }
        }
        .toolbarTitleDisplayMode(.inline)
        .sensoryFeedback(.success, trigger: trigger)
      }
    }
  }

#endif
