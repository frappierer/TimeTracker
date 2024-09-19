import SwiftUI
import AppKit

@main
struct TimeTrackerApp: App {
    @StateObject private var timeTracker = TimeTracker()  // Initialize the TimeTracker
    @AppStorage("openai_api_key") private var apiKey: String = ""  // Access the API key from AppStorage

    var body: some Scene {
        MenuBarExtra {
            Text(timeTracker.isTracking ? "Tracking is ON" : "Tracking is OFF")  // Add this line
            if apiKey.isEmpty {
                Text("Enter OpenAI API Key in Settings to enable tracking")
                    .foregroundColor(.red)
            } else {
                Button(timeTracker.isTracking ? "Stop Time Tracker" : "Start Time Tracker", action: {
                    if timeTracker.isTracking {
                        timeTracker.stop()
                    } else {
                        timeTracker.start()
                    }
                })
            }
            Divider()
            Button("Configure Settings", action: timeTracker.openSettings)
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        } label: {
            if timeTracker.isTracking {
                Image(systemName: "pause.rectangle.fill")
                    .symbolEffect(.bounce, value: timeTracker.isTracking)
                    .tint(.pink) 
            } else {
                Image(systemName: "play.rectangle")
            }
        }
    }
}
