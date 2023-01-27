// AppView.swift
// find.a.BLE

import Foundation
import SwiftUI
import Combine


enum Icon: String {
    // top-left

    // top-right
    case sort = "arrow.up.arrow.down"
    case settingsOn = "ellipsis.circle.fill"
    case settingsOff = "ellipsis.circle"

    // bottom bar
    case share = "square.and.arrow.up"
    case snapshot = "camera.fill"
    case snapshotError = "camera.fill.badge"
    case pause = "pause.fill"
    case play = "play.fill"
    case unknowns = "person.crop.circle.badge.questionmark"
    case unknownsFilled = "person.crop.circle.badge.questionmark.fill"
    case clear = "trash"
}

struct AppView: View {
    @ObservedObject var viewModel: AppViewModel

    @State private var hideUnnamedScanResults = true
    @State private var isShowingSettingsSheet = false

    private func formatSectionHeader(title: String, count: Int) -> String {
        count > 5 ? "\(title) (\(count))" : title
    }

    var body: some View {
            NavigationStack {
                List {
                    Section(formatSectionHeader(title: "DEVICES", count: viewModel.namedScanResults.count)) {
                        ForEach (viewModel.namedScanResults) { scanResult in
                            ScanResultCell(
                                isScanning: $viewModel.isScanning,
                                hideAction: { viewModel.hide(id: scanResult.id) },
                                name: scanResult.deviceName,
                                manufacturer: scanResult.manufacturer,
                                model: scanResult.model,
                                id: scanResult.id,
                                isHidden: false,
                                signal: scanResult.rssi.format(as: viewModel.settingsViewModel.signalDisplayFormat),
                                showGraphic: viewModel.settingsViewModel.signalDisplayFormat == .bars,
                                lastPing: scanResult.lastPing
                            )
                        }
                    }
                    if !viewModel.isScanning && !viewModel.hiddenScanResults.isEmpty {
                        Section(formatSectionHeader(title: "HIDDEN", count: viewModel.hiddenScanResults.count)) {
                            ForEach (viewModel.hiddenScanResults) { scanResult in
                                ScanResultCell(
                                    isScanning: $viewModel.isScanning,
                                    hideAction: { viewModel.unhide(id: scanResult.id) },
                                    name: scanResult.deviceName,
                                    manufacturer: scanResult.manufacturer,
                                    model: scanResult.model,
                                    id: scanResult.id,
                                    isHidden: true,
                                    signal: scanResult.rssi.format(as: viewModel.settingsViewModel.signalDisplayFormat),
                                    showGraphic: false,
                                    lastPing: scanResult.lastPing
                                )
                            }
                        }
                    }
                    if !hideUnnamedScanResults {
                        Section(header: Label(formatSectionHeader(title: "ANONYMOUS DEVICES", count: viewModel.unnamedScanResults.count), systemImage: Icon.unknownsFilled.rawValue)) {
                            ForEach (viewModel.unnamedScanResults) { scanResult in
                                ScanResultCell(
                                    isScanning: $viewModel.isScanning,
                                    hideAction: { viewModel.hide(id: scanResult.id) },
                                    name: "",
                                    manufacturer: scanResult.manufacturer,
                                    model: scanResult.model,
                                    id: scanResult.id,
                                    isHidden: false,
                                    signal: scanResult.rssi.format(as: viewModel.settingsViewModel.signalDisplayFormat),
                                    showGraphic: viewModel.settingsViewModel.signalDisplayFormat == .bars,
                                    lastPing: scanResult.lastPing
                                )
                            }
                        }
                    }
                }
                .navigationTitle("find.a.BLE")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Menu {
                            Picker("Sort", selection: $viewModel.sortType) {
                                Text("Sort by Name").tag(ScanSort.name)
                                Text("Sort by Signal Strength").tag(ScanSort.rssi)
                                Text("Sort by Recent Ping").tag(ScanSort.recent)
                            }
                        }
                        label: {
                            Image(systemName: Icon.sort.rawValue)
                            .font(.system(size: 15))
                        }
                        Button {
                            isShowingSettingsSheet.toggle()
                        }
                        label: {
                            Image(systemName: isShowingSettingsSheet ? Icon.settingsOn.rawValue : Icon.settingsOff.rawValue)
                        }
                        .sheet(isPresented: $isShowingSettingsSheet) {
                            SettingsView(viewModel: viewModel.settingsViewModel)
                        }
                    }
                    ToolbarItemGroup(placement: .bottomBar) {
                        let csv = ScanResultCSVExporter(scanResults: viewModel.namedScanResults + (hideUnnamedScanResults ? [] : viewModel.unnamedScanResults))

                        ShareLink(item: csv, preview: SharePreview(csv.filename)) { Image(systemName: "square.and.arrow.up") }
                            .disabled(csv.scanResults.isEmpty)
                        Spacer()
                        Button { viewModel.isScanning ? viewModel.stopScan() : viewModel.startScan() } label: { Image(systemName: viewModel.isScanning ? Icon.pause.rawValue : Icon.play.rawValue) }
                        Spacer()
                        Button { hideUnnamedScanResults.toggle() } label: { Image(systemName: hideUnnamedScanResults ? Icon.unknowns.rawValue : Icon.unknownsFilled.rawValue) }
                        Spacer()
                        Button { viewModel.clearScan() } label: { Image(systemName: Icon.clear.rawValue) }
                    }
                }
            }
    }
}

struct AppView_Previews: PreviewProvider {
    static var previews: some View {
        AppView(viewModel: ViewModelManager()!.appViewModel)
    }
}
