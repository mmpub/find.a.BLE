// AppViewModel.swift
// find.a.BLE

import Foundation
import AsyncAlgorithms
import CoreTransferable
import Combine
import SingleInstance
import UniformTypeIdentifiers


enum BLEState {
    case uninitialized, poweredOff, unauthorized, available, notAvailable, error
}

fileprivate let unknownId = ""


enum ScanSort {
    case name, rssi, recent
}

struct ScanResultCSVExporter: Transferable {
    var filename: String { "find.a.BLE.csv" }
    let scanResults: [AdvertisedDevice]


    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .commaSeparatedText) { archive in
            Data(
                archive
                    .scanResults
                    .reduce(into: ["name,temporary_id,rssi"])  { lines, scanResult in
                        lines.append("\(scanResult.getExportName()), \(scanResult.id), \(scanResult.rssi)")
                    }
                    .joined(separator: "\n")
                    .filter {
                        $0
                        .unicodeScalars
                        .allSatisfy(\.isASCII)
                    }
                    .utf8
                )
        }
    }
}


class AppViewModel: SingleInstance, ObservableObject {
    @Published var bleState = BLEState.notAvailable
    @Published var isScanning = false
    @Published var sortType = ScanSort.name
    @Published var namedScanResults = [AdvertisedDevice]()
    @Published var hiddenScanResults = [AdvertisedDevice]()
    @Published var unnamedScanResults = [AdvertisedDevice]()
//    @ObservedObject var csvFile: ScanResultCSVExporter

    unowned let modelManager: ModelManager
    let settingsViewModel: SettingsViewModel
//    let exporter = ScanResultCSVExporter()

    var subscriptions = [AnyCancellable]()
    var hiddenList = [String: AdvertisedDevice]()
    var scanResults = [String: AdvertisedDevice]()
    private var bleStateMonitor:Task<Void, Never>!
    private var scanTask:Task<Void, Never>!

    required init?() {
        return nil
    }

    init?(modelManager: ModelManager) {
        self.modelManager = modelManager
        guard let settingsViewModel = SettingsViewModel() else { return nil }
        self.settingsViewModel = settingsViewModel
        bleState = .notAvailable
        isScanning = false
//        csvFile = 
        super.init()

        subscriptions.append($sortType.sink { _ in
            Task { @MainActor [weak self] in
                self?.updateScanResults()
            }
        })

        subscriptions.append(settingsViewModel.$timeHorizon.sink { timeHorizon in
            Task { @MainActor in
                modelManager.set(timeHorizon: timeHorizon.rawValue)
            }
        })

        bleStateMonitor = Task {
            // Note: The state transitions are a minimum of two seconds apart to avoid jarring the user with quick transistions.
            for await centralState:BLECentralState in modelManager.getStateStream().debounce(for: .seconds(2.0)) {
                Task { @MainActor in
                    switch centralState {
                    case .uninitialized:
                        bleState = .uninitialized
                    case .poweredOff:
                        bleState = .poweredOff
                    case .unauthorized:
                        bleState = .unauthorized
                    case .poweredOn:
                        bleState = .available
                        if !isScanning {
                            startScan()
                        }
                    case .resetting:
                        bleState = .notAvailable
                    default:
                        bleState = .error
                    }
                }
            }
        }

        scanTask = Task {
            for await (activePeripheralList, hiddenList) in modelManager.getScannerResultsStream() {
                Task { @MainActor in
                    scanResults = activePeripheralList
                    self.hiddenList = hiddenList
                    updateScanResults()
                }
            }
        }
    }


    @MainActor func initializeBLE() {
        bleState = .notAvailable
        modelManager.initializeBLE()
    }

    @MainActor func updateScanResults() {

        func searchResultsFilter(_ item: AdvertisedDevice) -> Bool {
            true
        }

        typealias SortPredicate = @MainActor (AdvertisedDevice, AdvertisedDevice) -> Bool

        func nameSortPredicate(_ a:AdvertisedDevice, _ b:AdvertisedDevice) -> Bool {
            let aName = a.deviceName.lowercased()
            let bName = b.deviceName.lowercased()
            return aName == bName ? a.id < b.id : aName < bName
        }

        func signalStrengthSortPredicate(_ a:AdvertisedDevice, _ b:AdvertisedDevice) -> Bool {
            a.rssi == b.rssi ? nameSortPredicate(a, b) : a.rssi > b.rssi
        }

        func recentPingSortPredicate(_ a:AdvertisedDevice, _ b:AdvertisedDevice) -> Bool {
            let aTime = Int(a.lastPing)/5, bTime = Int(b.lastPing)/5
            return a == b ? nameSortPredicate(a,b) : aTime > bTime
        }


        let sortPredicate: SortPredicate
        switch sortType {
        case .name: sortPredicate = nameSortPredicate
        case .rssi: sortPredicate = signalStrengthSortPredicate
        case .recent: sortPredicate = recentPingSortPredicate
        }
        let scanList = scanResults.keys.map { scanResults[$0]! }.filter { searchResultsFilter($0) }.sorted { sortPredicate($0, $1) }
        namedScanResults = scanList.filter { $0.deviceName != unknownId && !$0.isHidden}
        hiddenScanResults =
            hiddenList.values.filter{$0.deviceName != unknownId}.sorted{$0.deviceName.lowercased() < $1.deviceName.lowercased()} +
            hiddenList.values.filter{$0.deviceName == unknownId}.sorted{$0.id < $1.id}
        unnamedScanResults = scanList.filter { $0.deviceName == unknownId && !$0.isHidden}
    }

    @MainActor func clearScan() {
        Task {
            await modelManager.clearActiveList()
        }
    }

    func startScan() {
        modelManager.startScanning()
        isScanning = true
    }

    func stopScan() {
        isScanning = false
        modelManager.stopScanning()
    }

    @MainActor func hide(id: String) {
        Task {
            await modelManager.hidePeripheral(id: id)
        }
    }

    @MainActor func unhide(id: String) {
        Task {
            await modelManager.unhidePeripheral(id: id)
        }
    }

    func makeSnapshot() {
        print("SNAPSHOT")
    }
}
