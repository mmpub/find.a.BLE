// AdvertisedDevices.swift
// find.a.BLE

import Foundation

actor AdvertisedDevices {
    private var activeList = [String: AdvertisedDevice]()
    private var prevActiveList = [String: AdvertisedDevice]()
    private var pendingList = [String: AdvertisedDevice]()
    private var interrogationResults = [String: BLEInterrogationResult]()
    private var hiddenList = [String: AdvertisedDevice]()
    private var prevHiddenList = [String: AdvertisedDevice]()
    let scannerResultDispatcher = ValueDispatcher<([String:AdvertisedDevice], [String:AdvertisedDevice])>()
    private let dataManager: DataManager
    private var timeHorizon = 1_000_000.0
    private var isScanning = false
    private var scanStopTime = 0.0
    private var pruneTask: Task<(), Never>? = nil

    init(dataManager: DataManager) {
        self.dataManager = dataManager
        Task {
            await self.setupPruneTask()
        }
    }

    deinit {
        pruneTask?.cancel()
    }

    private func setupPruneTask() {
        self.pruneTask = Task.detached {
            do {
                while true {
                    try await Task.sleep(nanoseconds: 1 * 1_000_000_000)
                    await self.pruneActiveList()
                }
            } catch {
            }
        }
    }

    private func pruneActiveList() {
        guard isScanning else { return }
        let now = NSDate().timeIntervalSince1970
        activeList = activeList.filter { (now - $0.value.lastPing) < timeHorizon }
        update()
    }

    func clearActiveList() {
        activeList = [:]
        interrogationResults = interrogationResults.filter { if case .success(_, _) = $0.value { return true } else { return false } }
        update()
    }

    func hidePeripheral(id: String) {
        if let peripheral = activeList[id] {
            hiddenList[id] = peripheral
            activeList[id]?.isHidden = true
            pendingList[id]?.isHidden = true
            update()
        }
    }

    func unhidePeripheral(id: String) {
        hiddenList[id] = nil
        activeList[id]?.isHidden = false
        pendingList[id]?.isHidden = false
        update()
    }

    private func update() {
        if activeList != prevActiveList || hiddenList != prevHiddenList {
            prevActiveList = activeList
            prevHiddenList = hiddenList
            scannerResultDispatcher.next(value: (prevActiveList, prevHiddenList))
        }
    }

    func setInterrogationResult(id: String, result: BLEInterrogationResult) {
        interrogationResults[id] = result
    }

    func ping(scanResult: BLEScannerResult) {
        let id = scanResult.uuid
        var peripheral = AdvertisedDevice(id: id, deviceName: scanResult.name, manufacturer: "", model: "", isHidden: hiddenList[scanResult.uuid] != nil, rssi: Int(scanResult.signal)!, lastPing: NSDate().timeIntervalSince1970)
        func updatePeripheral() {
            if case let .success(manufacturer, model) = interrogationResults[id] {
                peripheral.manufacturer = manufacturer.isEmpty ? peripheral.manufacturer : manufacturer
                peripheral.model = model.isEmpty ? peripheral.model : model
            }
        }

        if activeList[id] != nil {
            activeList[id]!.rssi = peripheral.rssi
            activeList[id]!.lastPing = peripheral.lastPing
        } else if pendingList[id] != nil {
            pendingList[id]!.rssi = peripheral.rssi
            pendingList[id]!.lastPing = peripheral.lastPing
        } else if !scanResult.isConnectable || interrogationResults[id] != nil || !peripheral.deviceName.isEmpty {
            updatePeripheral()
            activeList[id] = peripheral
        } else {
            // add to pending list and start interrogation
            pendingList[peripheral.id] = peripheral
            Task {
                guard let dao = dataManager.createDataAccessObject(id: "BLE.peripheral", params:["id": peripheral.id]) else { return }
                for await result:BLEInterrogationResult in dao.getObjStream() {
                    self.setInterrogationResult(id: id, result: result)
                    break
                }
                updatePeripheral()
                activeList[id] = peripheral
                pendingList[id] = nil
            }
        }
        update()
    }

    func set(timeHorizon: Double) {
        self.timeHorizon = timeHorizon
    }

    func notifyScanStart() {
        if scanStopTime != 0 {
            let now = NSDate().timeIntervalSince1970
            let deltaT = now - scanStopTime
            if deltaT > 0 {
                for id in activeList.keys {
                    activeList[id]!.lastPing += deltaT
                }
                for id in prevActiveList.keys {
                    prevActiveList[id]!.lastPing += deltaT
                }
                for id in pendingList.keys {
                    pendingList[id]!.lastPing += deltaT
                }
            }
        }
        isScanning = true
    }

    func notifyScanStop() {
        scanStopTime = NSDate().timeIntervalSince1970
        isScanning = false
    }
}
