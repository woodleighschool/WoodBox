//
//  DeviceScannerView.swift
//  WoodBox
//
//  Created by Alexander Hyde on 21/2/2026.
//

import SwiftData
import SwiftUI

#if os(iOS)
  import Vision
  import VisionKit

  // MARK: - Scan type

  private enum ScanType {
    case assetTag
    case serial

    var label: String {
      switch self {
      case .assetTag: "asset tag"
      case .serial: "serial number"
      }
    }
  }

  // MARK: - Sheet

  struct DeviceScannerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Bindable var selection: DeviceSelectionState

    @State private var isPaused = false
    @State private var matchedValue: String?
    @State private var notFoundAlert: AlertItem?

    // MARK: - Body

    var body: some View {
      NavigationStack {
        VStack(spacing: 0) {
          ZStack {
            DeviceScannerCameraView(isPaused: $isPaused, onCandidate: handleCandidate)
            if let matchedValue {
              Text(matchedValue)
                .font(.title2.monospaced().weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.horizontal)
                .shadow(radius: 4)
            }
          }
          .containerRelativeFrame(.vertical) { height, _ in height * 0.48 }
          .clipped()

          Text("Align a barcode or serial number inside the box.")
            .font(.headline)
            .foregroundStyle(.secondary)
            .padding()
            .padding(.top, 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(.background)
        }
        .ignoresSafeArea(edges: .top)
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button(action: { dismiss() }) {
              Image(systemName: "xmark")
            }
          }
        }
        .sensoryFeedback(.success, trigger: matchedValue)
        .alert(item: $notFoundAlert) { item in
          Alert(
            title: Text(item.title),
            message: Text(item.message),
            primaryButton: .cancel(Text("Cancel")) { dismiss() },
            secondaryButton: .default(Text("Continue")) {
              matchedValue = nil
              isPaused = false
            }
          )
        }
      }
    }

    // MARK: - Private Helpers

    @MainActor
    private func handleCandidate(_ value: String, type scanType: ScanType) {
      guard !isPaused else { return }

      isPaused = true
      matchedValue = value

      let predicate: Predicate<Device>
      if scanType == .assetTag {
        predicate = #Predicate { $0.assetTag == value }
      } else {
        predicate = #Predicate { $0.serial == value }
      }
      var descriptor = FetchDescriptor<Device>(predicate: predicate)
      descriptor.fetchLimit = 1

      guard let device = try? modelContext.fetch(descriptor).first else {
        notFoundAlert = AlertItem(
          title: "Device Not Found",
          message: "No device with \(scanType.label) \"\(value)\" was found."
        )
        return
      }

      selection.select(device)

      Task {
        try? await Task.sleep(for: .milliseconds(600))
        dismiss()
      }
    }
  }

  // MARK: - Camera

  private struct DeviceScannerCameraView: UIViewControllerRepresentable {
    @Binding var isPaused: Bool
    var onCandidate: (String, ScanType) -> Void

    func makeCoordinator() -> Coordinator {
      Coordinator(onCandidate: onCandidate)
    }

    func makeUIViewController(context: Context) -> DataScannerViewController {
      let scanner = DataScannerViewController(
        recognizedDataTypes: [.barcode(symbologies: [.code39]), .text()],
        qualityLevel: .accurate,
        recognizesMultipleItems: false,
        isPinchToZoomEnabled: true,
        isGuidanceEnabled: true,
        isHighlightingEnabled: false
      )
      scanner.delegate = context.coordinator
      try? scanner.startScanning()
      return scanner
    }

    func updateUIViewController(_ scanner: DataScannerViewController, context _: Context) {
      if isPaused {
        scanner.stopScanning()
      } else if !scanner.isScanning {
        try? scanner.startScanning()
      }
    }

    static func dismantleUIViewController(
      _ scanner: DataScannerViewController, coordinator _: Coordinator
    ) {
      scanner.stopScanning()
    }

    // MARK: - Coordinator

    @MainActor
    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
      private let onCandidate: (String, ScanType) -> Void

      init(onCandidate: @escaping (String, ScanType) -> Void) {
        self.onCandidate = onCandidate
      }

      func dataScanner(
        _: DataScannerViewController, didAdd items: [RecognizedItem], allItems _: [RecognizedItem]
      ) {
        for item in items {
          switch item {
          case let .barcode(barcode):
            guard barcode.observation.symbology == .code39,
                  let value = barcode.payloadStringValue?.trimmingCharacters(
                    in: .whitespacesAndNewlines
                  ),
                  !value.isEmpty
            else { continue }
            onCandidate(value, .assetTag)
            return
          case let .text(text):
            if let serial = firstSerialCandidate(in: text.transcript) {
              onCandidate(serial, .serial)
              return
            }
          @unknown default: break
          }
        }
      }

      // MARK: - Private Helpers

      private func firstSerialCandidate(in transcript: String) -> String? {
        transcript
          .split(separator: /\W+/)
          .map(String.init)
          .first {
            ($0.count == 10 || $0.count == 12)
              && $0.allSatisfy { $0.isUppercase || $0.isNumber }
              && $0.contains(where: \.isUppercase)
              && $0.contains(where: \.isNumber)
          }
      }
    }
  }
#endif
