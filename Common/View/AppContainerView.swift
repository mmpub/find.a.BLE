// AppContainerView.swift
// find.a.BLE

import SwiftUI

struct AppContainerView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var isShowingAuthAlert = false

    var body: some View {
        if viewModel.bleState != .available {
            VStack {
                // App Brand
                Text("find.a.BLE")
                    .font(.system(.headline))
                    .padding(.bottom)

                if viewModel.bleState == .uninitialized {
                    // Case: App has never initialized.
                    // Since this is the first launch of the app, it would be jarring for
                    // the user to have the first thing presented be the permissions overlay.
                    // Instead, the user is welcomed with the app brand and is given a button
                    // to authorize. The button leads to a message to inform and galvanize the
                    // user to authorize permissions.

                    let galvanizeUserCopy = """
                        BLUETOOTH IS NOT YET AUTHORIZED

                        You have the opportunity to authorize find.a.BLE to use the Bluetooth radio.

                        find.a.BLE cannot operate without authorization.

                        If you don't authorize at this point, you can later give permissions in the Settings app.
                        """

                    Button("Authorize Bluetooth Permissions") {
                        isShowingAuthAlert = true
                    }
                    .alert(galvanizeUserCopy, isPresented: $isShowingAuthAlert) {
                        Button("Got it", role: .cancel) {
                            viewModel.initializeBLE()
                        }
                    }
                } else if viewModel.bleState == .unauthorized {
                    // Case: User denied permission at first launch or subsequently in Settings.
                    // Present a button to launch the Settings app pointed to find.a.BLE settings, which include
                    // a toggle to enable bluetooth permissions.
                    #if os(watchOS)
                        Text("Enable Permission On iPhone:\nSettings > Privacy & Security > Bluetooth > find.a.BLE-watchOS")
                    #else
                        Button("Enable Bluetooth Permissions") {
                            if let url = URL.init(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                            }
                        }
                    #endif
                } else if viewModel.bleState == .poweredOff {
                    // Case: User has turned off Bluetooth services in Control Center or Settings.
                    // Inform the user of the issue and its remedy.
                    #if os(watchOS)
                        let appUnavailableTextCopy = "Please Enable Bluetooth Connections in\nSettings > Bluetooth"
                    #else
                        let appUnavailableTextCopy = "Please Enable Bluetooth Connections in Settings or Control Center."
                    #endif
                    VStack(alignment: .center) {
                        Text("App Unavailable while Bluetooth is OFF.")
                            .fontWeight(.bold)
                        Text(appUnavailableTextCopy)
                            .font(.system(size: 12.0))
                            .fontWeight(.bold)
                            .foregroundColor(.gray)
                        ProgressView()
                    }
                } else {
                    // Case: App is starting up.
                    ProgressView()
                }
            }
        } else {
            // Case: App is initialized and Bluetooth service is available.
            AppView(viewModel: viewModel)
        } 
    }
}

struct AppContainerView_Previews: PreviewProvider {
    static var previews: some View {
        AppContainerView()
            .environmentObject(ViewModelManager(dataManager: DataManager.self)!)
    }
}
