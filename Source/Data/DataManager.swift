// DataManager.swift
// find.a.BLE

import Foundation
import MVVMD

/// Data Manager
class DataManager: MVVMD.DataManager {
    required init?() {
        super.init(dataSources: [BLEDataSource.self])
    }
}

/// Mock Data Manager
class MockDataManager: MVVMD.DataManager {
    required init?() {
        super.init(dataSources: [BLEDataSource.self])
    }
}

