import Foundation
import MVVM_D

/// Application's Data Manager
class AppDataManager: MVVMD_DataManager {
    required init?() {
        super.init(dataSources: [BLEDataSource.self])
    }
}
