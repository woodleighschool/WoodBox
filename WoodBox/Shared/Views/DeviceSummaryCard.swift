//
//  DeviceSummaryCard.swift
//  WoodBox
//
//  Created by Alexander Hyde on 9/2/2026.
//

import SwiftData
import SwiftUI

struct DeviceSummaryCard: View {
  // MARK: - Properties

  let device: Device?
  var onClear: (() -> Void)?

  // MARK: - Body

  var body: some View {
    Group {
      if let device {
        deviceView(for: device)
      } else {
        emptyStateView
      }
    }
    .padding(.vertical, 4)
  }

  // MARK: - Private Helpers

  private func deviceView(for device: Device) -> some View {
    HStack(alignment: .center, spacing: 12) {
      Image(systemName: "laptopcomputer")
        .font(.title2)
        .foregroundStyle(.white)
        .frame(width: 40, height: 40)
        .background(Color.accentColor.gradient, in: .rect(cornerRadius: 8))

      VStack(alignment: .leading, spacing: 2) {
        identifiersRow(for: device)
        metadataRow(for: device)
      }

      Spacer()

      if let onClear {
        Button(action: onClear) {
          Image(systemName: "xmark.circle.fill")
            .font(.title3)
            .foregroundStyle(.tertiary)
        }
        .buttonStyle(.plain)
        .padding(.leading, 8)
      }
    }
  }

  private func identifiersRow(for device: Device) -> some View {
    HStack(spacing: 8) {
      if let name = device.name?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty {
        Text(name)
          .font(.headline)
          .foregroundStyle(.primary)
      }

      Label(device.assetTag, systemImage: "tag.fill")
      Label(device.serial, systemImage: "number")
    }
    .font(.subheadline)
    .foregroundStyle(.secondary)
    .lineLimit(1)
  }

  private func metadataRow(for device: Device) -> some View {
    HStack(spacing: 8) {
      if let model = device.model?.trimmingCharacters(in: .whitespacesAndNewlines), !model.isEmpty {
        Label(model, systemImage: "desktopcomputer")
      }
    }
    .font(.caption)
    .foregroundStyle(.secondary)
    .lineLimit(1)
  }

  private var emptyStateView: some View {
    HStack(alignment: .center, spacing: 12) {
      Image(systemName: "macbook.and.iphone")
        .font(.title2)
        .foregroundStyle(.secondary)
        .frame(width: 40, height: 40)
        .background(.tertiary.opacity(0.3), in: .rect(cornerRadius: 8))

      VStack(alignment: .leading, spacing: 2) {
        Text("No Device Selected")
          .font(.headline)
          .foregroundStyle(.secondary)

        Text("Search for a device to begin.")
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Spacer()
    }
  }
}
