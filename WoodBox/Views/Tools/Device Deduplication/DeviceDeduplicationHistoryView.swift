//
//  DeviceDeduplicationHistoryView.swift
//  WoodBox
//
//  Created by Alexander Hyde on 15/2/2026.
//

import SwiftUI

struct DeviceDeduplicationHistoryView: View {
  // MARK: - Properties

  let entry: DeviceDeduplicationHistory

  // MARK: - Body

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack(alignment: .firstTextBaseline) {
        Label(entry.removedProvider, systemImage: "trash.fill")
          .font(.subheadline.weight(.medium))
          .foregroundStyle(.red)

        Text(entry.timestamp, format: .dateTime.day().month().hour().minute())
          .font(.caption2)
          .foregroundStyle(.secondary)
      }

      HStack(spacing: 12) {
        Label(entry.deviceSerial, systemImage: "number")
          .foregroundStyle(.secondary)

        Label(entry.assetTag, systemImage: "tag")
          .foregroundStyle(.secondary)
      }
      .font(.caption)
    }
    .padding(.vertical, 4)
  }
}
