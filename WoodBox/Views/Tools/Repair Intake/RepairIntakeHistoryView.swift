//
//  RepairIntakeHistoryView.swift
//  WoodBox
//
//  Created by Alexander Hyde on 15/2/2026.
//

import SwiftUI

struct RepairIntakeHistoryView: View {
  // MARK: - Properties

  let entry: RepairHistory

  private var assignedUserLabel: String {
    guard let user = entry.assignedUser, !user.isEmpty else { return "Unknown User" }
    return user
  }

  // MARK: - Body

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      headerRow
      detailRow
    }
    .padding(.vertical, 4)
  }

  // MARK: - Private Helpers

  private var headerRow: some View {
    HStack(alignment: .firstTextBaseline) {
      Label(entry.problem, systemImage: "exclamationmark.triangle.fill")
        .font(.subheadline.weight(.medium))
        .lineLimit(1)

      Text(entry.timestamp, format: .dateTime.day().month().hour().minute())
        .font(.caption2)
        .foregroundStyle(.secondary)
    }
  }

  private var detailRow: some View {
    HStack(spacing: 12) {
      Label(assignedUserLabel, systemImage: "person.fill")
        .foregroundStyle(.secondary)

      Label(entry.deviceSerial, systemImage: "number")
        .foregroundStyle(.secondary)

      if entry.spareAssetTag != nil {
        Label("Spare Issued", systemImage: "arrow.triangle.2.circlepath")
          .foregroundStyle(.secondary)
      }
    }
    .font(.caption)
  }
}
