//
//  DeviceScannerShared.swift
//  WoodBox
//
//  Shared scanning primitives used across device selection and bulk scanning.
//

import SwiftData
import SwiftUI

#if os(iOS)
  import Vision
  import VisionKit

  // MARK: - ScanType

  enum ScanType {
    case assetTag
    case serial

    var label: String {
      switch self {
      case .assetTag: "asset tag"
      case .serial: "serial number"
      }
    }

    var badgeSymbol: String {
      switch self {
      case .assetTag: "barcode"
      case .serial: "text.viewfinder"
      }
    }
  }

  // MARK: - ModelContext helper

  extension ModelContext {
    func fetchDevice(matching value: String, scanType: ScanType) -> Device? {
      let predicate: Predicate<Device> =
        scanType == .assetTag
          ? #Predicate { $0.assetTag == value }
        : #Predicate { $0.serial == value }

      var descriptor = FetchDescriptor<Device>(predicate: predicate)
      descriptor.fetchLimit = 1
      return try? fetch(descriptor).first
    }
  }

  // MARK: - Camera view

  struct DeviceScannerCameraView: UIViewControllerRepresentable {
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

    func updateUIViewController(_: DataScannerViewController, context _: Context) {}

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

      // MARK: - Private helpers

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
