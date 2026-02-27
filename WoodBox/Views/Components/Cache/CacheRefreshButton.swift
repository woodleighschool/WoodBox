//
//  CacheRefreshButton.swift
//  WoodBox
//
//  Created by Alexander Hyde on 9/2/2026.
//

import SwiftUI

struct CacheRefreshButton: View {
  @Environment(ModelData.self) private var modelData

  private var cacheManager: CacheManager {
    modelData.cacheManager
  }

  private var settings: AppSettings {
    modelData.settings
  }

  @State private var lastError: String?
  @State private var showSuccess = false

  var body: some View {
    Button {
      Task { await cacheManager.sync() }
    } label: {
      if cacheManager.isSyncing {
        ProgressView().controlSize(.small)
          .transition(.opacity)
      } else {
        Image(systemName: symbol.name)
          .foregroundStyle(symbol.color)
          .contentTransition(.symbolEffect(.replace.downUp))
          .symbolEffect(.bounce, value: showSuccess)
      }
    }
    .disabled(isDisabled)
    .help(isDisabled ? "Enable Snipe-IT to refresh" : helpText)
    .onChange(of: cacheManager.status) { oldStatus, newStatus in
      handleStatusChange(from: oldStatus, to: newStatus)
    }
  }

  private enum ButtonSymbol {
    case error, success, idle

    var name: String {
      switch self {
      case .error: "xmark"
      case .success: "checkmark"
      case .idle: "arrow.clockwise"
      }
    }

    var color: Color {
      switch self {
      case .error: .orange
      case .success: .green
      case .idle: .primary
      }
    }
  }

  private var symbol: ButtonSymbol {
    if lastError != nil { return .error }
    if showSuccess { return .success }
    return .idle
  }

  private var isDisabled: Bool {
    cacheManager.isSyncing || settings.snipeItIsEnabled == false
  }

  private var helpText: String {
    switch cacheManager.status {
    case let .syncing(message):
      return message
    case let .failed(message, _):
      return message
    case let .synced(date):
      if let date {
        return "Last refreshed \(date.formatted(date: .abbreviated, time: .shortened))"
      }
      return "Refresh cache"
    }
  }

  private func handleStatusChange(
    from oldStatus: CacheManager.Status, to newStatus: CacheManager.Status
  ) {
    switch newStatus {
    case let .failed(message, _):
      lastError = message
      Task { @MainActor in
        try? await Task.sleep(for: .seconds(3))
        lastError = nil
      }
    case .synced:
      lastError = nil
      if case .syncing = oldStatus {
        showSuccess = true
        Task { @MainActor in
          try? await Task.sleep(for: .seconds(2))
          showSuccess = false
        }
      }
    default:
      lastError = nil
    }
  }
}
