import Foundation

class APIHandler {
    private var apiKey: String

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func sendScreenshotsToOpenAI(lastImages: [String], currentImages: [String], timestamp: String, completion: @escaping ([String: Any]?) -> Void) {
        guard !apiKey.isEmpty else {
            //print("API key is missing.")
            return
        }
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!

        let wrappedLastImages = lastImages.map { ["type": "image_url", "image_url": ["url": "data:image/png;base64,\($0)"]] }
        let wrappedCurrentImages = currentImages.map { ["type": "image_url", "image_url": ["url": "data:image/png;base64,\($0)"]] }

        var contentArray: [Any] = [
            [
                "type": "text",
                "text": "I have these screenshots from the last capture."
            ]
        ]

        contentArray.append(contentsOf: wrappedLastImages)

        contentArray.append([
            "type": "text",
            "text": "I have these screenshots from the current capture at \(timestamp)."
        ])

        contentArray.append(contentsOf: wrappedCurrentImages)

        contentArray.append([
            "type": "text",
            "text": """
            You are an assistant that analyzes pairs of screenshots to determine what I am doing.
            Compare the current screenshots to the last screenshots to identify any changes.
            For any screen where there is a change, analyze the current screenshot to determine
            what I am doing on that screen. Ignore any screens where there is no change.
            Output the result in JSON format with keys: timestamp, client, tool, activity.
            """
        ])

        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                [
                    "role": "user",
                    "content": contentArray
                ]
            ],
            "max_tokens": 300,
            "response_format": [
                "type": "json_schema",
                "json_schema": [
                    "name": "screenshot_analysis_schema",
                    "schema": [
                        "type": "object",
                        "properties": [
                            "timestamp": ["type": "string", "description": "Timelog in ISO Format yyyy-MM-ddTHH:mm:ss"],
                            "client": ["type": "string", "description": "Client you're working for"],
                            "tool": ["type": "string", "description": "Tool like Microsoft Teams, Google Chrome."],
                            "activity": ["type": "string", "description": "Describe what user is doing. If nothing has changed write 'Previous Client'"]
                        ],
                        "required": ["timestamp", "client", "tool", "activity"],
                        "additionalProperties": false
                    ]
                ]
            ]
        ]

        let jsonData = try! JSONSerialization.data(withJSONObject: body, options: [])

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = jsonData

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                completion(nil)
                return
            }

            if let data = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: [])
                    //print("Response from OpenAI: \(json)")
                    if let responseData = self.processApiResponse(json) {
                        completion(responseData)
                    } else {
                        completion(nil)
                    }
                } catch {
                    print("Failed to parse JSON: \(error)")
                    completion(nil)
                }
            }
        }

        task.resume()
    }

    private func processApiResponse(_ response: Any) -> [String: Any]? {
        if let responseDict = response as? [String: Any],
           let choices = responseDict["choices"] as? [[String: Any]],
           let message = choices.first?["message"] as? [String: Any],
           let content = message["content"] as? String,
           let data = try? JSONSerialization.jsonObject(with: Data(content.utf8), options: []) as? [String: Any] {
            return data
        }
        return nil
    }
}
