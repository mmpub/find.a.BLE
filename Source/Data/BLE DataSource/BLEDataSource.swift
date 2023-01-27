// BLEDataSource.swift
// find.a.BLE

import os.log
import CoreBluetooth
import SingleInstance
import MVVMD

public final class BLEDataSource: SingleInstance, MVVMD.DataSource {
    public var state = MVVMD.DataSourceState.active

    public var params: [String : String] { [:] }

    public var dataSourceID = "BLE"
    private var delegate = CBDelegate()
    private var centralManager: CBCentralManager!
    private static var bluetoothInitialized = false

    public required init?() {
        super.init()
        if delegate.authState != .uninitialized {
            initializeCoreBluetooth()
        }
    }

    func initializeCoreBluetooth() {
        guard !BLEDataSource.bluetoothInitialized else { return }
        centralManager = CBCentralManager(delegate: delegate, queue: delegate.queue)
        Task {
            delegate.updateStateDAOs(newState: .unauthorized, authState: .unauthorized)
        }
        BLEDataSource.bluetoothInitialized = true
    }

    public func createDataAccessObject(id: String, params: [String : String]) -> MVVMD.DataAccessObject? {
        enum DataAccessType: String {
            case initialize
            case centralState
            case scanner
            case peripheral
        }

        guard let dataAccessType = DataAccessType(rawValue: id) else { return nil }

        switch dataAccessType {
        case .initialize:
            initializeCoreBluetooth()
            return nil

        case .centralState:
            let dao = BLECentralStateDAO(prevStateCallback: {(self.delegate.prevState,  self.delegate.authState)})
            dao.onDeinit { self.delegate.remove(centralStateDAO: dao) }
            self.delegate.add(centralStateDAO: dao)
            return dao

        case .scanner:
            guard BLEDataSource.bluetoothInitialized, let dao = BLEScannerDAO() else { return nil }
            dao.setCallbacks(
                startScan: { self.centralManager.scanForPeripherals(withServices: nil, options:[CBCentralManagerScanOptionAllowDuplicatesKey:true]) },
                stopScan: { self.centralManager.stopScan() }
            )
            delegate.set(scannerDAO: dao)
            return dao

        case .peripheral:
            let dao = BLEPeripheralDAO()
            let id = params["id"]!
            dao.setCallbacks (
                startInterrogation: {
                    self.delegate.interrogationHandler[id] = dao
                    self.delegate.interrogationResult[id] = .init()
                    Task {
                        if let peripheral = await self.delegate.peripheralCatalog.lookup(id: id) {
                            self.centralManager.connect(peripheral)
                        }
                    }
                },
                cancelInterrogation: {
                    Task {
                        if let peripheral = await self.delegate.peripheralCatalog.lookup(id: id) {
                            self.centralManager.cancelPeripheralConnection(peripheral)
                        }
                    }
                }
            )
            return dao
        }
    }
}
