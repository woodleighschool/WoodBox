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
  #if os(iOS)
    func deviceSearch(selection: DeviceSelectionState) -> some View {
      modifier(DeviceSearch(selection: selection, onBatchComplete: nil))
    }

    func deviceSearch(
      selection: DeviceSelectionState,
      onBatchComplete: @escaping ([Device]) -> Void
    ) -> some View {
      modifier(DeviceSearch(selection: selection, onBatchComplete: onBatchComplete))
    }
  #else
    func deviceSearch(selection: DeviceSelectionState) -> some View {
      modifier(DeviceSearch(selection: selection))
    }
  #endif
}

// MARK: - Modifier

private struct DeviceSearch: ViewModifier {
  @Bindable var selection: DeviceSelectionState
  #if os(iOS)
    var onBatchComplete: (([Device]) -> Void)?
  #endif

  func body(content: Content) -> some View {
    #if os(iOS)
      DeviceSearchBody(content: content, selection: selection, onBatchComplete: onBatchComplete)
    #else
      DeviceSearchBody(content: content, selection: selection, onBatchComplete: nil)
    #endif
  }
}

// MARK: - Body

private struct DeviceSearchBody<Content: View>: View {
  let content: Content
  @Bindable var selection: DeviceSelectionState
  #if os(iOS)
    var onBatchComplete: (([Device]) -> Void)?
  #endif
  @Query private var filteredDevices: [Device]

  @Environment(\.dismissSearch) private var dismissSearch
  @State private var isSearchPresented = false

  #if os(iOS)
    @State private var isScanningDevice = false
  #endif

  init(
    content: Content,
    selection: DeviceSelectionState,
    onBatchComplete: (([Device]) -> Void)? = nil
  ) {
    self.content = content
    self.selection = selection
    #if os(iOS)
      self.onBatchComplete = onBatchComplete
    #endif
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
            .onTapGesture {
              selection.select(device)
            }
          }
        }
      }
      .onSubmit(of: .search) {
        guard let firstMatch = filteredDevices.first else { return }
        selection.select(firstMatch)
        isSearchPresented = false
        dismissSearch()
      }
    #if os(iOS)
      .fullScreenCover(isPresented: $isScanningDevice) {
        DeviceScannerSheet(selection: selection, onBatchComplete: onBatchComplete)
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
