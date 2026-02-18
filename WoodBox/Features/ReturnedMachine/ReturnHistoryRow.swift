//
//  ReturnHistoryRow.swift
//  WoodBox
//
//  Created by Alexander Hyde on 9/2/2026.
//

import SwiftUI

struct ReturnHistoryRow: View {
  // MARK: - Properties

  let entry: ReturnHistory

  // MARK: - Body

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack(alignment: .firstTextBaseline) {
        Label(entry.assignedUser ?? "Unknown User", systemImage: "person.fill")
          .font(.subheadline.weight(.medium))
          .lineLimit(1)

        Text(entry.timestamp, format: .dateTime.day().month().hour().minute())
          .font(.caption2)
          .foregroundStyle(.secondary)
      }

      HStack(spacing: 12) {
        Label(entry.deviceSerial, systemImage: "number")
          .foregroundStyle(.secondary)

        HStack(spacing: 8) {
          Image(systemName: entry.goodCondition ? "checkmark.circle.fill" : "xmark.circle.fill")
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(entry.goodCondition ? .green : .red)

          Image(systemName: entry.hasCharger ? "battery.100.circle.fill" : "battery.0.circle.fill")
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(entry.hasCharger ? .green : .red)
        }
      }
      .font(.caption)
    }
    .padding(.vertical, 4)
  }
}
