//
//  SaleHistoryRow.swift
//  WoodBox
//
//  Created by Alexander Hyde on 9/2/2026.
//

import SwiftUI

struct SaleHistoryRow: View {
  // MARK: - Properties

  let item: SaleHistory

  // MARK: - Body

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack(alignment: .firstTextBaseline) {
        Label(item.assetTag, systemImage: "tag.fill")
          .font(.subheadline.weight(.medium))

        Label(item.deviceSerial, systemImage: "number")
          .font(.caption)
          .foregroundStyle(.secondary)

        if let condition = item.condition {
          Text(condition.rawValue)
            .font(.caption2.bold())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(condition.color.opacity(0.12))
            .clipShape(Capsule())
        }
      }

      Text(item.model)
        .font(.caption)
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }
    .padding(.vertical, 4)
  }
}
