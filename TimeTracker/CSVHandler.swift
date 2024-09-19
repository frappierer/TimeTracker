import Foundation

class CSVHandler {
    private var csvFilePath: URL

    init(csvFilePath: URL) {
        self.csvFilePath = csvFilePath
    }

    func writeToCsv(data: [String: Any]) {
        let fileExists = FileManager.default.fileExists(atPath: csvFilePath.path)
        let header = "\"Timestamp\",\"Client\",\"Tool\",\"Activity\"\n"
        let row = "\"\(data["timestamp"] ?? "")\",\"\(data["client"] ?? "")\",\"\(data["tool"] ?? "")\",\"\(data["activity"] ?? "")\"\n"

        if !fileExists {
            try? header.write(to: csvFilePath, atomically: true, encoding: .utf8)
        }

        if let fileHandle = try? FileHandle(forWritingTo: csvFilePath) {
            fileHandle.seekToEndOfFile()
            if let rowData = row.data(using: .utf8) {
                fileHandle.write(rowData)
            }
            fileHandle.closeFile()
        }
    }
}
