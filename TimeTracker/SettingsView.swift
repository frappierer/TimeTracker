import SwiftUI

struct SettingsView: View {
    @AppStorage("openai_api_key") private var apiKey: String = ""
    @AppStorage("keepScreenshots") private var keepScreenshots: Bool = false
    @AppStorage("interval") private var interval: Double = 60.0  // Store interval in AppStorage

    @State private var showKeepScreenshotsPopover = false
    @State private var showIntervalPopover = false

    var body: some View {
        Form {
            TextField("OpenAI API Key", text: $apiKey)
            
            HStack {
                Toggle("Keep Screenshots", isOn: $keepScreenshots)
                Button(action: {
                    showKeepScreenshotsPopover.toggle()
                }) {
                    Image(systemName: "info.circle")
                }
                .popover(isPresented: $showKeepScreenshotsPopover) {
                    Text("If enabled, screenshots will be kept on disk. Otherwise, they will be deleted after processing.")
                        .padding()
                }
            }
            
            HStack {
                Stepper(value: $interval, in: 10...3600, step: 10) {
                    Text("Interval: \(Int(interval)) seconds")
                }
                Button(action: {
                    showIntervalPopover.toggle()
                }) {
                    Image(systemName: "info.circle")
                }
                .popover(isPresented: $showIntervalPopover) {
                    Text("Set the interval in seconds for taking screenshots.")
                        .padding()
                }
            }
        }
        .padding()
    }
}
