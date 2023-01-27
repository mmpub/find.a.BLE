import Combine
import MVVM_D
import SingleInstance

class ViewModelManager: SingleInstance, ObservableObject {
    let modelManager: ModelManager
    let appViewModel: AppViewModel

    required init?() {
        return nil
    }

    required init?(dataManager: DataManager.Type = DataManager.self) {
        guard let modelManager = ModelManager.init(dataManager: dataManager) else { return nil }
        guard let appViewModel = AppViewModel(modelManager: modelManager) else { return nil }
        self.modelManager = modelManager
        self.appViewModel = appViewModel
    }

}
