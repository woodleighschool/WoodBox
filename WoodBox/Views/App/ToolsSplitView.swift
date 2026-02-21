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

  // MARK: - Body

  var body: some View {
    @Bindable var modelData = modelData

    TabView(selection: $modelData.selectedTab) {
      // Primary tabs
      Tab(
        AppTab.repairIntake.title, systemImage: AppTab.repairIntake.symbol,
        value: AppTab.repairIntake
      ) {
        NavigationStack {
          RepairIntakeView(deviceSelection: modelData.deviceSelection)
            .navigationTitle("Repair Intake")
            .navigationSubtitle("Log repairs and generate tickets")
        }
      }

      Tab(
        AppTab.returnCheckIn.title, systemImage: AppTab.returnCheckIn.symbol,
        value: AppTab.returnCheckIn
      ) {
        NavigationStack {
          ReturnCheckInView(deviceSelection: modelData.deviceSelection)
            .navigationTitle("Return Check-In")
            .navigationSubtitle("Process returned devices")
        }
      }

      Tab(
        AppTab.salePreparation.title,
        systemImage: AppTab.salePreparation.symbol,
        value: AppTab.salePreparation
      ) {
        NavigationStack {
          SalePreparationView(deviceSelection: modelData.deviceSelection)
            .navigationTitle("Sale Preparation")
            .navigationSubtitle("Prepare devices for sale")
        }
      }

      Tab(
        AppTab.deviceDeduplication.title,
        systemImage: AppTab.deviceDeduplication.symbol,
        value: AppTab.deviceDeduplication
      ) {
        NavigationStack {
          DeviceDeduplicationView()
            .navigationTitle("Device Deduplication")
            .navigationSubtitle("Merge duplicate records")
        }
      }

      #if os(iOS)
        Tab(
          AppTab.settings.title, systemImage: AppTab.settings.symbol, value: AppTab.settings
        ) {
          NavigationStack {
            SettingsView()
              .navigationTitle("Settings")
              .toolbar {
                ToolbarItem(placement: .automatic) {
                  CacheRefreshButton()
                }
              }
          }
        }
      #endif
    }
    .tabViewStyle(.sidebarAdaptable)
    .animation(.smooth(duration: 0.2), value: modelData.selectedTab)
    #if os(macOS)
      .toolbar {
        // Want this in the sidebar, seems to be no way to do this again...?
        ToolbarItem(placement: .navigation) {
          CacheRefreshButton()
        }
      }
    #endif
  }
}
