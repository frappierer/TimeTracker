# AI Vision TimeTracker / MacOS AI Screen Capture Boilerplate

## Overview
You can think of this as a template for coding native MacOS applications that capture your screen at intervals and ask open AI to do something with it and stores it response into a csv. As a demo, I created the AI Vision TimeTracker:

TimeTracker is a native MacOS application designed to help users track the time they spend on various activities. It takes screenshots at regular intervals, compares them to detect changes, and logs the activity using OpenAI's API. The application also provides a menu bar interface for easy access and configuration.
At the end of the day I use GPT to summarise the .csv to tell me what I have done during the day so I can log my time in Jira.

## AI Vision TimeTracker Features

- **Time Tracking**: Start and stop time tracking with a simple menu bar interface.
- **Screenshot Capture**: Automatically captures screenshots at specified intervals.
- **Save time-log to .csv**: Compares screenshots to detect changes and logs activities into a .csv file to your Downloads folder.
- **Screen delta check to save used tokens**: It leverages the MacOS Vision framework to detect Screenshot changes. By this, only the Screens are sent over where a delta is detected. Eg. you have 3 Screens. But only in screen 1 and 2, you have a delta. It will only send Screen 1 and 2 to open AI to save tokens.
- **OpenAI Integration**: Uses OpenAI's API to analyze screenshots and determine user activities.
- **Settings Configuration**: Configure API key, screenshot retention, and capture interval through a settings view.

## Installation

1. **Clone the Repository**:
    ```sh
    git clone https://github.com/yourusername/TimeTracker.git
    cd TimeTracker
    ```

2. **Open in Xcode**:
    - Open `TimeTracker.xcodeproj` in Xcode.

3. **Build and Run**:
    - Build and run the project using Xcode.

## Usage

### Menu Bar Interface
![image](https://github.com/user-attachments/assets/41d17169-487a-41fa-a93d-62f4c8f231a2)

- **Start/Stop Tracking**: Use the menu bar to start or stop time tracking.
- **Configure Settings**: Open the settings view to configure the API key, screenshot retention, and capture interval.
- ![image](https://github.com/user-attachments/assets/951b9243-0945-4985-b891-c30ad80e76f0)
- **Quit Application**: Quit the application from the menu bar.

### Settings

- **OpenAI API Key**: Enter your OpenAI API key to enable screenshot analysis.
- **Keep Screenshots**: Toggle whether to keep screenshots on disk after processing.
- **Interval**: Set the interval (in seconds) for capturing screenshots.

### CSV Export
Currently, it stores the structured output from open AI to a csv located in /Users/$UserNmae/Downloads/TimeTracker/activity_log.csv
![image](https://github.com/user-attachments/assets/a253745a-29e5-4802-bf03-dea06c9ced6a)

## How it Works

1. **Setup**:
    - Enter your OpenAI API key and set the desired interval for capturing screenshots in the settings view.
    - On the first run, the application will request the necessary permissions to capture screenshots.

2. **Screenshot Capture**:
    - Based on the configured interval, the application captures screenshots of all connected screens.

3. **Change Detection**:
    - The application uses macOS Vision capabilities to compare the current screenshots with the previous ones.
    - Only the screenshots with detected changes (deltas) are selected for further processing, which helps in saving OpenAI API tokens.

4. **OpenAI Request**:
    - The selected screenshots are sent to OpenAI's API for analysis.
    - The request leverages structured output to ensure a valid JSON response. For more details, see [OpenAI Structured Outputs](https://platform.openai.com/docs/guides/structured-outputs/introduction).

5. **CSV Logging**:
    - The structured output from OpenAI is written to a CSV file located at `/Users/$UserName/Downloads/TimeTracker/activity_log.csv`.
    - This CSV file logs the activities detected from the screenshots, including the timestamp, client, tool, and activity.

By following these steps, the application efficiently tracks your activities and logs them for easy review and time management.

## More ideas you can deliver using the Boilerplate

* **Productivity Tracke**r: Monitor and analyze your work habits to improve productivity.
* **Parental Control App**: Keep track of children's screen time and activities.
* **Security Surveillance**: Capture and analyze screen activity for security purposes.
* **User Behavior Analysis**: Study user interactions with software for UX improvements.
* **Remote Work Monitoring**: Track remote employees' screen activities for accountability.
* **Educational Tools**: Monitor students' screen activities during online learning.
* **Content Moderation**: Automatically detect and flag inappropriate content on screens.
* **Health and Wellness App**: Track screen time to promote healthier digital habits.
* **Customer Support Tool**: Analyze customer interactions with software for better support.
* **Research and Development**: Use screen capture data for various research projects.

## Code Structure

### `TimeTrackerApp.swift`

The main entry point of the application. It initializes the `TimeTracker` object and sets up the menu bar interface.

### `CSVHandler.swift`

Handles writing data to a CSV file. It ensures the file exists and appends new rows of data.

### `SettingsView.swift`

Provides a SwiftUI view for configuring application settings, including the API key, screenshot retention, and capture interval.

### `TimeTrackerTests.swift`

Contains unit tests for the application. Use XCTest to verify the functionality of your code.

### `ScreenshotHandler.swift`

Captures screenshots, compares them to detect changes, and processes them using OpenAI's API. It also manages the retention of screenshots based on user settings.

### `APIHandler.swift`

Handles communication with OpenAI's API. It sends screenshots for analysis and processes the response to extract activity data.


## License

This project is licensed under the MIT License.

## Contact

For any questions or issues, please open an issue on GitHub or contact me at LinkedIn https://www.linkedin.com/in/martin-altmann/.
