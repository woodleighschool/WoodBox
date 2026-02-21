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
    HStack(spacing: 12) {
      iconBadge

      VStack(alignment: .leading, spacing: 4) {
        if let device {
          titleBlock(device)
          metadata(device)
        } else {
          emptyBlock
        }
      }

      Spacer(minLength: 0)

      if let onClear, device != nil {
        Button(action: onClear) {
          Image(systemName: "xmark.circle.fill")
            .symbolRenderingMode(.hierarchical)
        }
      }
    }
  }

  // MARK: - Private Helpers

  @ViewBuilder
  private var iconBadge: some View {
    let isPopulated = device != nil
    Image(systemName: device?.symbolName ?? "macbook.and.iphone")
      .font(.title3.weight(.semibold))
      .foregroundStyle(isPopulated ? .white : .secondary)
      .frame(width: 40, height: 40)
      .background(
        isPopulated ? Color.accentColor : Color.secondary.opacity(0.15),
        in: .rect(cornerRadius: 12)
      )
      .symbolRenderingMode(.hierarchical)
  }

  private func titleBlock(_ device: Device) -> some View {
    VStack(alignment: .leading, spacing: 2) {
      DeviceNameText(name: device.name)
        .font(.headline)
        .lineLimit(1)

      Text(device.model)
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }
  }

  private var emptyBlock: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text("No Device Selected")
        .font(.headline)
        .foregroundStyle(.secondary)

      Text("Search for a device to begin.")
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
  }

  private func metadata(_ device: Device) -> some View {
    ScrollView(.horizontal) {
      HStack(spacing: 6) {
        chip(systemImage: "barcode", text: device.assetTag)
        chip(systemImage: "number", text: device.serial)
        warrantyChip(device.warrantyExpires)
      }
    }
    .scrollIndicators(.never)
    .scrollBounceBehavior(.basedOnSize)
  }

  @ViewBuilder
  private func chip(systemImage: String, text: String) -> some View {
    if !text.isEmpty {
      HStack(spacing: 3) {
        Image(systemName: systemImage)
        Text(text)
      }
      .font(.caption.monospacedDigit())
      .lineLimit(1)
      .foregroundStyle(.secondary)
      .padding(.vertical, 4)
      .padding(.horizontal, 8)
      .background(.secondary.opacity(0.12), in: .capsule)
    }
  }

  private func warrantyChip(_ date: Date?) -> some View {
    let oneMonth: TimeInterval = 60 * 60 * 24 * 30
    let now = Date()

    let (label, tint): (String, Color) = {
      guard let date else { return ("Unknown", .secondary) }
      let interval = date.timeIntervalSince(now)
      let text = date.formatted(.dateTime.day(.twoDigits).month(.twoDigits).year(.twoDigits))
      if interval > oneMonth { return (text, .green) }
      if interval < -oneMonth { return (text, .red) }
      return (text, .secondary)
    }()

    return HStack(spacing: 3) {
      Image(systemName: "shield")
      Text(label)
    }
    .font(.caption.monospacedDigit())
    .lineLimit(1)
    .foregroundStyle(tint)
    .padding(.vertical, 4)
    .padding(.horizontal, 8)
    .background(.secondary.opacity(0.12), in: .capsule)
  }
}
