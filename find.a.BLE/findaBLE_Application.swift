// find.a.BLE

import SwiftUI
import MVVM_D

@main
struct find_a_BLE_Application: App {
    let viewModelManager: ViewModelManager!

    var body: some Scene {
        WindowGroup {
            AppContainerView()
                .environmentObject(viewModelManager.appViewModel)
        }
    }

    init() {
        viewModelManager = ViewModelManager(dataManager: DataManager.self)
    }
}
