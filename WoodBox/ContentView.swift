//
//  ContentView.swift
//  WoodBox
//
//  Created by Alexander Hyde on 8/2/2026.
//

import SwiftData
import SwiftUI

struct ContentView: View {
  // MARK: - Properties

  @Environment(ModelData.self) private var modelData

  // MARK: - Body

  var body: some View {
    @Bindable var modelData = modelData

    NavigationSplitView(preferredCompactColumn: $modelData.preferredColumn) {
      SidebarList(modelData: modelData)
    } detail: {
      DetailPane(modelData: modelData)
    }
    .modifier(HistoryInspectorToggle(modelData: modelData))
  }
}

// MARK: - Subviews

private struct SidebarList: View {
  @Bindable var modelData: ModelData

  var body: some View {
    List(selection: $modelData.selectedOption) {
      Section("Tools") {
        ForEach(NavigationOption.mainPages) { option in
          NavigationLink(value: option) {
            Label(option.name, systemImage: option.symbolName)
          }
        }
      }
    }
    .listStyle(.sidebar)
    .navigationTitle("WoodBox")
    .frame(minWidth: 180)
  }
}

private struct DetailPane: View {
  @Bindable var modelData: ModelData

  var body: some View {
    modelData.selectedOption.view(modelData: modelData)
  }
}

// MARK: - Modifiers

private struct HistoryInspectorToggle: ViewModifier {
  @Bindable var modelData: ModelData

  func body(content: Content) -> some View {
    content
      .inspector(isPresented: $modelData.isInspectorPresented) {
        HistoryInspectorView(option: modelData.selectedOption)
          .inspectorColumnWidth(min: 250, ideal: 250, max: 250)
      }
      .toolbar {
        ToolbarItem(placement: .primaryAction) {
          Button {
            modelData.isInspectorPresented.toggle()
          } label: {
            Label("History", systemImage: "clock.arrow.circlepath")
          }
        }

        ToolbarItem(placement: .status) {
          CacheRefreshButton()
        }
      }
  }
}
