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

  var body: some View {
    Button {
      Task { await cacheManager.sync() }
    } label: {
      Group {
        if cacheManager.isSyncing {
          ProgressView()
            .controlSize(.small)
        } else if let error = lastError {
          Image(systemName: "exclamationmark.triangle.fill")
            .foregroundStyle(.orange)
            .help(error)
        } else {
          Image(systemName: "arrow.clockwise")
            .foregroundStyle(.primary)
            .help(helpText)
        }
      }
    }
    .disabled(isDisabled)
    .help(isDisabled ? "Enable Snipe-IT to refresh" : helpText)
    .onChange(of: cacheManager.status) { _, newStatus in
      handleStatusChange(newStatus)
    }
  }

  private var isDisabled: Bool {
    cacheManager.isSyncing || settings.snipeIsEnabled == false
  }

  private var helpText: String {
    switch cacheManager.status {
    case let .syncing(message):
      return message
    case let .failed(message, _):
      return message
    case let .synced(date):
      if let date { return "Last refreshed \(date.formatted(date: .abbreviated, time: .shortened))" }
      return "Refresh cache"
    }
  }

  private func handleStatusChange(_ status: CacheManager.Status) {
    switch status {
    case let .failed(message, _):
      lastError = message
      Task { @MainActor in
        try? await Task.sleep(for: .seconds(3))
        lastError = nil
      }
    default:
      lastError = nil
    }
  }
}
