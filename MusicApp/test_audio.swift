// Test script to verify audio URL accessibility
import Foundation
import AVFoundation

// Test URL from the logs
let testURL = "https://composition-lambda.s3-accelerate.amazonaws.com/14b49532-f8bd-4903-8bd6-ca8ff4783415_1nvsp/full_track.wav"

if let url = URL(string: testURL) {
    let task = URLSession.shared.dataTask(with: url) { data, response, error in
        if let error = error {
            print("Error downloading: \(error)")
        } else if let httpResponse = response as? HTTPURLResponse {
            print("HTTP Status: \(httpResponse.statusCode)")
            print("Headers: \(httpResponse.allHeaderFields)")
            if let data = data {
                print("Data size: \(data.count) bytes")
            }
        }
    }
    task.resume()
    RunLoop.main.run(until: Date(timeIntervalSinceNow: 5))
}
