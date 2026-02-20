//
//  ToolsSplitView.swift
//  WoodBox
//
//  Created by Alexander Hyde on 8/2/2026.
//

import SwiftData
import SwiftUI

struct ToolsSplitView: View {
  // MARK: - Properties

  @Environment(ModelData.self) private var modelData

  private var selection: Binding<NavigationOption?> {
    Binding(
      get: { modelData.selectedOption },
      set: { modelData.selectedOption = $0 }
    )
  }

  private var resolvedSelection: NavigationOption? {
    #if os(macOS)
      modelData.selectedOption ?? .repairIntake
    #else
      modelData.selectedOption
    #endif
  }

  // MARK: - Body

  var body: some View {
    @Bindable var modelData = modelData

    NavigationSplitView(preferredCompactColumn: $modelData.preferredColumn) {
      SidebarList(selection: selection)
    } detail: {
      if let option = resolvedSelection {
        DetailPane(option: option, modelData: modelData, isInspectorPresented: $modelData.isInspectorPresented)
      }
    }
    .modifier(HistoryInspectorToggle(selectedOption: resolvedSelection, isInspectorPresented: $modelData.isInspectorPresented))
  }
}

private struct DetailPane: View {
  let option: NavigationOption
  let modelData: ModelData
  @Binding var isInspectorPresented: Bool

  var body: some View {
    NavigationStack {
      option.view(modelData: modelData)
        .toolbar {
          if option != .settings {
            ToolbarItem(placement: .primaryAction) {
              Button {
                isInspectorPresented.toggle()
              } label: {
                Label("History", systemImage: "clock.arrow.circlepath")
              }
            }
          }
        }
    }
    .id(option)
  }
}

private struct SidebarList: View {
  var selection: Binding<NavigationOption?>

  var body: some View {
    List(selection: selection) {
      Section("Tools") {
        ForEach(NavigationOption.mainPages) { option in
          Label(option.name, systemImage: option.symbolName)
            .tag(option)
        }
      }
      #if os(iOS)
        Section("Preferences") {
          Label(NavigationOption.settings.name, systemImage: NavigationOption.settings.symbolName)
            .tag(NavigationOption.settings)
        }
      #endif
    }
    .listStyle(.sidebar)
    .navigationTitle("WoodBox")
    .toolbar {
      ToolbarItem(placement: .automatic) {
        CacheRefreshButton()
      }
    }
    #if os(macOS)
    .frame(minWidth: 180)
    #endif
  }
}

// MARK: - Modifiers

private struct HistoryInspectorToggle: ViewModifier {
  let selectedOption: NavigationOption?
  @Binding var isInspectorPresented: Bool

  func body(content: Content) -> some View {
    content
      .inspector(isPresented: $isInspectorPresented) {
        if let option = selectedOption {
          HistoryInspectorView(option: option)
          #if os(macOS)
            .inspectorColumnWidth(min: 250, ideal: 250, max: 250)
          #endif
        }
      }
  }
}
