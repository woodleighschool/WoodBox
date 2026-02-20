//
//  HistoryInspectorView.swift
//  WoodBox
//
//  Created by Alexander Hyde on 11/2/2026.
//

import SwiftData
import SwiftUI

struct HistoryInspectorView: View {
  // MARK: - Properties

  let option: NavigationOption

  // MARK: - Body

  var body: some View {
    content
      .navigationTitle("History")
  }

  // MARK: - Private Helpers

  @ViewBuilder
  private var content: some View {
    switch option {
    case .repairIntake:
      InspectorList(
        sort: \RepairHistory.timestamp,
        order: .reverse
      ) { (item: RepairHistory) in
        RepairIntakeHistoryView(entry: item)
      }

    case .returnCheckIn:
      InspectorList(
        sort: \ReturnCheckInHistory.timestamp,
        order: .reverse
      ) { (item: ReturnCheckInHistory) in
        ReturnCheckInHistoryView(entry: item)
      }

    case .salePreparation:
      InspectorList(
        sort: \SalePreparationHistory.deviceSerial
      ) { (item: SalePreparationHistory) in
        SalePreparationHistoryView(item: item)
      }

    case .deviceDeduplication:
      InspectorList(
        sort: \DeviceDeduplicationHistory.timestamp,
        order: .reverse
      ) { (item: DeviceDeduplicationHistory) in
        DeviceDeduplicationHistoryView(entry: item)
      }
    }
  }
}

// MARK: - Internal Component

private struct InspectorList<T: PersistentModel, RowContent: View>: View {
  @Environment(\.modelContext) private var modelContext
  @Query private var items: [T]
  let rowContent: (T) -> RowContent

  init(
    sort: KeyPath<T, some Comparable>,
    order: SortOrder = .forward,
    @ViewBuilder rowContent: @escaping (T) -> RowContent
  ) {
    _items = Query(sort: sort, order: order)
    self.rowContent = rowContent
  }

  var body: some View {
    Group {
      if items.isEmpty {
        ContentUnavailableView(
          "No History",
          systemImage: "clock.arrow.circlepath",
          description: Text("No history items found.")
        )
      } else {
        List {
          ForEach(items) { item in
            rowContent(item)
              .contextMenu {
                Button(role: .destructive) {
                  deleteItem(item)
                } label: {
                  Label("Delete", systemImage: "trash")
                }
              }
          }
          .onDelete(perform: deleteItems)
        }
      }
    }
  }

  private func deleteItem(_ item: T) {
    modelContext.delete(item)
  }

  private func deleteItems(at offsets: IndexSet) {
    for index in offsets {
      deleteItem(items[index])
    }
  }
}
