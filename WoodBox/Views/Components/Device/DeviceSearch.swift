//
//  DeviceSearch.swift
//  WoodBox
//
//  Created by Alexander Hyde on 9/2/2026.
//

import SwiftData
import SwiftUI

// MARK: - Public API

extension View {
  func deviceSearch(selection: DeviceSelectionState) -> some View {
    modifier(DeviceSearch(selection: selection))
  }
}

// MARK: - Private

private struct DeviceSearch: ViewModifier {
  @Bindable var selection: DeviceSelectionState

  func body(content: Content) -> some View {
    DeviceSearchBody(content: content, selection: selection)
  }
}

// MARK: - Body

private struct DeviceSearchBody<Content: View>: View {
  let content: Content
  @Bindable var selection: DeviceSelectionState
  @Query private var filteredDevices: [Device]

  @Environment(\.dismissSearch) private var dismissSearch
  @State private var isSearchPresented = false

  #if os(iOS)
    @State private var isScanningDevice = false
  #endif

  init(content: Content, selection: DeviceSelectionState) {
    self.content = content
    self.selection = selection
    let q = selection.query.trimmingCharacters(in: .whitespacesAndNewlines)
    var descriptor = FetchDescriptor<Device>(
      predicate: #Predicate { device in
        device.serial.localizedStandardContains(q)
          || device.assetTag.localizedStandardContains(q)
          || device.assignedUserEmail?.localizedStandardContains(q) == true
      },
      sortBy: [SortDescriptor(\Device.name)]
    )
    descriptor.fetchLimit = 25
    _filteredDevices = Query(descriptor)
  }

  var body: some View {
    let q = selection.query.trimmingCharacters(in: .whitespacesAndNewlines)
    content
      .searchable(
        text: $selection.query,
        isPresented: $isSearchPresented,
        prompt: "Pick a Device..."
      )
      .contentTransition(.symbolEffect(.replace))
      .animation(.smooth(duration: 0.18), value: selection.selectedDevice?.serial)
      .searchSuggestions {
        if !q.isEmpty {
          ForEach(filteredDevices) { device in
            Button {
              selection.select(device)
              isSearchPresented = false
              dismissSearch()
            } label: {
              HStack(alignment: .center, spacing: 10) {
                Image(systemName: device.symbolName)
                  .resizable()
                  .scaledToFit()
                  .frame(width: 24, height: 24)
                  .symbolEffect(.bounce, value: selection.selectedDevice?.serial == device.serial)
                VStack(alignment: .leading, spacing: 2) {
                  DeviceNameText(name: device.name)
                  HStack(spacing: 4) {
                    Image(systemName: "barcode")
                    Text(device.assetTag)
                    Image(systemName: "number")
                    Text(device.serial)
                  }
                  .font(.caption)
                  .foregroundStyle(.secondary)
                }
              }
            }
          }
        }
      }
      .onSubmit(of: .search) {
        guard !q.isEmpty, let firstMatch = filteredDevices.first else { return }
        selection.select(firstMatch)
        isSearchPresented = false
        dismissSearch()
      }
    #if os(iOS)
      .fullScreenCover(isPresented: $isScanningDevice) {
        DeviceScannerSheet(selection: selection)
      }
      .toolbar {
        // I do want this next to the search field, does not seem achievable...?
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            isScanningDevice = true
          } label: {
            Image(systemName: "camera.viewfinder")
          }
        }
      }
    #endif
  }
}
