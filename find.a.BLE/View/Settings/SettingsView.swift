import Foundation
import SwiftUI
import Combine


struct SignalDisplayFormatView: View {
    @Binding var signalDisplayFormat: SignalDisplayFormat
    var body: some View {
        NavigationStack {
            List {
                Picker("Signal Display Format", selection: $signalDisplayFormat) {
                    ForEach (SignalDisplayFormat.allCases, id: \.self) { item in
                        Text(item.rawValue)
                        .tag(item)
                    }
                }
                .pickerStyle(.inline)
            }
        }
    }
}

struct TimeHorizonView: View {
    @Binding var timeHorizon: TimeHorizon
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Time Horizon"), footer: Text("Devices that haven't pinged within the time horizon are removed from results.")) {
                    Picker(selection: $timeHorizon, label: Text("")) {
                        ForEach (TimeHorizon.allCases, id: \.self) { item in
                            Text(item.label)
                            .tag(item)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
            }
        }
    }
}

struct TipsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("TIPS") {
                    VStack {
                        Text("Before a Bluetooth device needs to be located, do a practice scan. Use **find.a.BLE** to find the device and note how far away it can be detected, using the Clear List button each step.")
                    }
                    VStack {
                        Text("Some Apple peripherals do not appear in any Bluetooth device scan. In this case, use the **Find My** app instead.")
                    }
                    VStack {
                        Text("To protect privacy, all device ID numbers presented are temporary proxies for actual IDs. These temporary proxy IDs are subject to change at any time. Don't correlate any device ID with its device outside of find.a.BLE")
                    }
                }
                Section("KNOWN ISSUES") {
                    VStack {
                        Text("1) When using the Share button to export a file to an AirDrop shortcut, the transmitted filename is .TXT instead of .CSV.\n\nWorkaround: Use basic AirDrop option (no shortcut) instead, where you select the destination computer/device manually.")
                    }
                }
            }
            .navigationTitle("")
        }
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        NavigationStack {
            List {
                VStack {
                    Text("**Privacy Policy - find.a.BLE v1.0.0**\n\nfind.a.BLE is a freeware tool and a rare app that does not transmit any data to a server. There are no ads or analytics packages incorporated.")
                }
            }
            .navigationTitle("Privacy Policy")
        }
    }
}

struct LegalNoticesView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("COPYRIGHT NOTICE") {
                    VStack {
                        Text("Copyright © 2022, Michael McMahon (github.com/mmpub)")
                    }
                }
                Section("LEGAL DISCLAIMERS") {
                    VStack {
                        Text("THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS “AS IS” AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.\n\nIN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.")
                    }
                }
            }
            .navigationTitle("Legal Notices")
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        NavigationStack {
            List {
                Section("OPTIONS") {
                    NavigationLink(destination: SignalDisplayFormatView(signalDisplayFormat: $viewModel.signalDisplayFormat)) {
                        HStack {
                            Text("Signal Display Format")
                            Spacer()
                            Text(viewModel.signalDisplayFormat.rawValue)
                            .foregroundColor(.gray)
                            .font(.subheadline)
                        }
                    }
                    NavigationLink(destination: TimeHorizonView(timeHorizon: $viewModel.timeHorizon)) {
                        HStack {
                            Text("Time Horizon")
                            Spacer()
                            Text(viewModel.timeHorizon.label)
                            .foregroundColor(.gray)
                            .font(.subheadline)
                        }
                    }
                }
                Section {
                    NavigationLink(destination: TipsView()) {
                        Text("Tips")
                    }
                    NavigationLink(destination: PrivacyPolicyView()) {
                        Text("Privacy Policy")
                    }
                    NavigationLink(destination: LegalNoticesView()) {
                        Text("Legal Notices")
                    }
                    VStack(alignment: .leading) {
                        Text("find.a.BLE Source Code")
                        Text("https://github.com/mmpub/find.a.BLE")
                            .font(.system(size: 14.0))
                    }
                }
                header: {
                    Image(systemName: "info.circle")
                }
                footer: {
                    Text("v1.0.0")
                        .font(.system(size: 10.0))
                        .opacity(0.6)
                        .padding(.top, -3.0)
                        .padding(.leading, -4.0)
                }

            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(viewModel: ViewModelManager(dataManager: DataManager.self)!.appViewModel.settingsViewModel)
    }
}
