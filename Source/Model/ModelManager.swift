// ModelManager.swift
// find.a.BLE

import os.log
import Foundation
import MVVMD
import SingleInstance

/// Application's Model Manager
final class ModelManager: SingleInstance {
    let dataManager: DataManager
    let peripherals: AdvertisedDevices
    let centralStateDispatcher = ValueDispatcher<BLECentralState>()
    private var bleStateMonitor:Task<Void, Never>!
    private var scanTask:Task<Void, Never>? = nil
    private unowned var bleDataSource: BLEDataSource


    @available(*, obsoleted:0.0, message: "Use init(dataManager:) instead")
    required init?() {
        return nil
    }

    required init?(dataManager: DataManager.Type) {
        guard let dataManager = dataManager.init() else { return nil }
        self.dataManager = dataManager
        peripherals = AdvertisedDevices(dataManager: dataManager)
        do {
            bleDataSource = try dataManager.injectDataSource(BLEDataSource.self)
        } catch {
            fatalError("Inject Data Source exception: \(error)")
        }
        super.init()

        bleStateMonitor = Task {
            guard let dao = dataManager.createDataAccessObject(id: "BLE.centralState") else { return }
            for await centralState:BLECentralState in dao.getObjStream() {
                centralStateDispatcher.next(value: centralState)
            }
        }
    }

    deinit {
        bleStateMonitor?.cancel()
    }

    func initializeBLE() {
        _ = dataManager.createDataAccessObject(id: "BLE.initialize")
    }

    func getStateStream() -> AsyncStream<BLECentralState> {
        centralStateDispatcher.getValueStream()
    }

    func getScannerResultsStream() -> AsyncStream<([String:AdvertisedDevice], [String:AdvertisedDevice])> {
        peripherals.scannerResultDispatcher.getValueStream(hotSignal: true)
    }

    func hidePeripheral(id: String) async {
        await peripherals.hidePeripheral(id: id)
    }

    func unhidePeripheral(id: String) async {
        await peripherals.unhidePeripheral(id: id)
    }

    func clearActiveList() async {
        await peripherals.clearActiveList()
    }

    func startScanning() {
        scanTask = Task {
            await peripherals.notifyScanStart()
            guard let dao = dataManager.createDataAccessObject(id: "BLE.scanner") else { return }
            for await scannerResult:BLEScannerResult in dao.getObjStream() {
                await peripherals.ping(scanResult: scannerResult)
            }
        }
    }

    func stopScanning() {
        scanTask?.cancel()
        Task {
            await peripherals.notifyScanStop()
        }
    }

    func set(timeHorizon: Double) {
        Task {
            await peripherals.set(timeHorizon: timeHorizon)
        }
    }
}
