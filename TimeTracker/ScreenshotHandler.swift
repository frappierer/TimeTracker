import Foundation
import AppKit
import Vision

class ScreenshotHandler {
    private var outputFolder: URL
    var lastScreenshots: [URL] = []  // Change from private to internal

    init(outputFolder: URL) {
        self.outputFolder = outputFolder
    }

    func captureScreenshots() -> [URL] {
        let screenCount = NSScreen.screens.count
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())

        var currentScreenshots = [URL]()

        for i in 0..<screenCount {
            let fileName = "\(timestamp)_screen_\(i + 1).png"
            let filePath = outputFolder.appendingPathComponent(fileName)

            let result = shell("screencapture -x -D \(i + 1) \(filePath.path)")
            if result == 0 {
                currentScreenshots.append(filePath)
            }
        }

        return currentScreenshots
    }

    func compareScreenshots(_ lastScreenshots: [URL], _ currentScreenshots: [URL]) -> [Int] {
        guard lastScreenshots.count == currentScreenshots.count else { return Array(0..<currentScreenshots.count) }

        var changedIndices = [Int]()

        for (index, (lastURL, currentURL)) in zip(lastScreenshots, currentScreenshots).enumerated() {
            guard let lastImage = UIImage(contentsOfFile: lastURL.path),
                  let currentImage = UIImage(contentsOfFile: currentURL.path),
                  let lastFeaturePrint = process(lastImage),
                  let currentFeaturePrint = process(currentImage) else {
                changedIndices.append(index)
                continue
            }

            var distance: Float = .infinity
            do {
                try lastFeaturePrint.computeDistance(&distance, to: currentFeaturePrint)
            } catch {
                print("Error computing distance: \(error)")
                changedIndices.append(index)
                continue
            }

            if distance > 0.03 {
                changedIndices.append(index)
            }
        }

        return changedIndices
    }

    private func process(_ image: UIImage) -> VNFeaturePrintObservation? {
        guard let cgImage = image.cgImage else { return nil }
        let request = VNGenerateImageFeaturePrintRequest()
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage,
                                                   orientation: .up,
                                                   options: [:])
        do {
            try requestHandler.perform([request])
        } catch {
            print("Can't make the request due to \(error)")
        }
        
        guard let result = request.results?.first as? VNFeaturePrintObservation else { return nil }
        return result
    }

    private func shell(_ command: String) -> Int32 {
        let task = Process()
        let pipe = Pipe()

        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", command]
        task.launchPath = "/bin/bash"
        task.launch()
        task.waitUntilExit()

        return task.terminationStatus
    }

    func captureAndProcessScreenshots(apiHandler: APIHandler, csvHandler: CSVHandler, keepScreenshots: Bool) {
        let currentScreenshots = captureScreenshots()

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        let timestamp = dateFormatter.string(from: Date())

        if !lastScreenshots.isEmpty {
            let changedIndices = compareScreenshots(lastScreenshots, currentScreenshots)
            if changedIndices.isEmpty {
                csvHandler.writeToCsv(data: [
                    "timestamp": timestamp,
                    "client": "Previous client",
                    "tool": "Previous tool",
                    "activity": "Previous activity"
                ])
            } else {
                let lastImagesBase64 = changedIndices.compactMap { try? Data(contentsOf: lastScreenshots[$0]).base64EncodedString() }
                let currentImagesBase64 = changedIndices.compactMap { try? Data(contentsOf: currentScreenshots[$0]).base64EncodedString() }
                
                // Print statements to log the number of images being sent
                //print("Number of changed screenshots: \(changedIndices.count)")
               // print("Sending \(lastImagesBase64.count) previous screenshots and \(currentImagesBase64.count) current screenshots to OpenAI")
                
                // Log the filenames being sent
               // for index in changedIndices {
                   // print("Previous screenshot: \(lastScreenshots[index].lastPathComponent)")
                  //  print("Current screenshot: \(currentScreenshots[index].lastPathComponent)")
             //   }

                // Log the filenames being skipped
               // let unchangedIndices = Set(0..<lastScreenshots.count).subtracting(changedIndices)
               // for index in unchangedIndices {
                 //   print("Skipped previous screenshot: \(lastScreenshots[index].lastPathComponent)")
                 //   print("Skipped current screenshot: \(currentScreenshots[index].lastPathComponent)")
              //  }

                apiHandler.sendScreenshotsToOpenAI(lastImages: lastImagesBase64, currentImages: currentImagesBase64, timestamp: timestamp) { responseData in
                    if let data = responseData {
                        csvHandler.writeToCsv(data: data)
                    }
                }
            }
        } else {
            print("No previous screenshots to compare with.")
        }

        if !keepScreenshots {
            for path in lastScreenshots {
                try? FileManager.default.removeItem(at: path)
            }
        }

        lastScreenshots = currentScreenshots
    }
}
