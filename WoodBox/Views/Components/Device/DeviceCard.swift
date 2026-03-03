//
//  DeviceCard.swift
//  WoodBox
//
//  Created by Alexander Hyde on 9/2/2026.
//

import Foundation
import SwiftData
import SwiftUI

struct DeviceCard: View {
  // MARK: - Properties

  let device: Device?
  var onClear: (() -> Void)?

  @State private var isExpanded = false

  // MARK: - Body

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      headerRow

      if let device {
        if isExpanded {
          expandedDetails(for: device)
            .transition(.opacity.combined(with: .move(edge: .top)))
        } else {
          compactDetails(for: device)
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
      }
    }
    .animation(.snappy(duration: 0.2), value: isExpanded)
    .animation(.snappy(duration: 0.2), value: device?.assetTag)
    .onChange(of: device?.assetTag, initial: true) { _, newValue in
      if newValue == nil {
        isExpanded = false
      }
    }
  }

  // MARK: - Private Views

  private var headerRow: some View {
    HStack(spacing: 12) {
      iconBadge

      VStack(alignment: .leading, spacing: 2) {
        if let device {
          DeviceNameText(name: device.name)
            .font(.headline)
            .lineLimit(1)

          Text(device.model)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .lineLimit(2)
        } else {
          Text("No Device Selected")
            .font(.headline)
            .foregroundStyle(.secondary)

          Text("Search for a device to begin.")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
      }

      Spacer(minLength: 0)

      if device != nil {
        Button {
          isExpanded.toggle()
        } label: {
          Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
            .font(.title3)
            .symbolRenderingMode(.hierarchical)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .accessibilityLabel(
          isExpanded ? "Show compact device details" : "Show detailed device list"
        )
      }

      if let onClear, device != nil {
        Button(action: onClear) {
          Image(systemName: "xmark.circle.fill")
            .font(.title3)
            .symbolRenderingMode(.hierarchical)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .accessibilityLabel("Clear selected device")
      }
    }
  }

  private var iconBadge: some View {
    let isPopulated = device != nil

    return Image(systemName: device?.symbolName ?? "macbook.and.iphone")
      .font(.title3.weight(.semibold))
      .foregroundStyle(isPopulated ? .white : .secondary)
      .frame(width: 40, height: 40)
      .background(
        isPopulated ? Color.accentColor : Color.secondary.opacity(0.15),
        in: .rect(cornerRadius: 12)
      )
      .symbolRenderingMode(.hierarchical)
      .symbolEffect(.bounce, value: device?.serial)
  }

  private func compactDetails(for device: Device) -> some View {
    ScrollView(.horizontal) {
      HStack(spacing: 6) {
        compactChip(systemImage: "barcode", text: device.assetTag, copyValue: device.assetTag)
        compactChip(systemImage: "number", text: device.serial, copyValue: device.serial)

        if let storage = device.storage.nilIfEmpty {
          compactChip(systemImage: "internaldrive", text: storage, copyValue: storage)
        }
        if let ram = device.ram.nilIfEmpty {
          compactChip(systemImage: "memorychip", text: ram, copyValue: ram)
        }

        if let expires = device.warrantyExpires {
          warrantyChip(expires)
        }
      }
    }
    .scrollIndicators(.never)
    .scrollBounceBehavior(.basedOnSize)
  }

  private func expandedDetails(for device: Device) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      copyRow(title: "Asset Tag", systemImage: "barcode", value: device.assetTag)
      copyRow(title: "Serial Number", systemImage: "number", value: device.serial)

      if let storage = device.storage.nilIfEmpty {
        detailRow(title: "Storage", systemImage: "internaldrive", value: storage)
      }
      if let ram = device.ram.nilIfEmpty {
        detailRow(title: "RAM", systemImage: "memorychip", value: ram)
      }
      if let expires = device.warrantyExpires {
        detailRow(
          title: "Warranty",
          systemImage: "shield",
          value: expires.formatted(.dateTime.day(.twoDigits).month(.twoDigits).year(.twoDigits)),
          tint: warrantyTint(for: expires)
        )
      }
    }
    .padding(.top, 2)
  }

  @ViewBuilder
  private func compactChip(systemImage: String, text: String, copyValue: String? = nil) -> some View {
    if !text.isEmpty {
      if let copyValue, !copyValue.isEmpty {
        compactChipLabel(systemImage: systemImage, text: text)
          .copyable([copyValue])
      } else {
        compactChipLabel(systemImage: systemImage, text: text)
      }
    }
  }

  private func copyRow(title: String, systemImage: String, value: String) -> some View {
    HStack(spacing: 8) {
      Label(title, systemImage: systemImage)
        .foregroundStyle(.secondary)

      Spacer(minLength: 8)

      Text(value)
        .font(.callout.monospaced())
        .lineLimit(1)
        .textSelection(.enabled)
    }
    .copyable([value])
    .accessibilityHint("Copy \(title) using the Copy command.")
  }

  private func compactChipLabel(systemImage: String, text: String) -> some View {
    HStack(spacing: 4) {
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

  private func detailRow(title: String, systemImage: String, value: String, tint: Color = .primary)
    -> some View
  {
    HStack(spacing: 8) {
      Label(title, systemImage: systemImage)
        .foregroundStyle(.secondary)

      Spacer(minLength: 8)

      Text(value)
        .foregroundStyle(tint)
        .lineLimit(1)
        .textSelection(.enabled)
    }
  }

  private func warrantyChip(_ date: Date) -> some View {
    HStack(spacing: 3) {
      Image(systemName: "shield")
      Text(date.formatted(.dateTime.day(.twoDigits).month(.twoDigits).year(.twoDigits)))
    }
    .font(.caption.monospacedDigit())
    .lineLimit(1)
    .foregroundStyle(warrantyTint(for: date))
    .padding(.vertical, 4)
    .padding(.horizontal, 8)
    .background(.secondary.opacity(0.12), in: .capsule)
  }

  // MARK: - Private Helpers

  private func warrantyTint(for date: Date) -> Color {
    let oneMonth: TimeInterval = 60 * 60 * 24 * 30
    let interval = date.timeIntervalSince(Date())

    if interval > oneMonth {
      return .green
    }
    if interval < -oneMonth {
      return .red
    }
    return .secondary
  }
}

#Preview {
  let device = Device(
    serial: "C02ABC123XYZ",
    assetTag: "WB-0001",
    model: "MacBook Pro 14-inch"
  )
  device.name = "Alex's MacBook Pro"
  device.ram = "18GB"
  device.storage = "512GB"
  device.warrantyExpires = Calendar.current.date(byAdding: .day, value: 180, to: .now)

  return DeviceCard(device: device)
    .padding()
}
