import Foundation

// Posts an "Add a space" submission to the backend (see backend/worker.js), which files the
// GitHub issue that the workbook Action consumes. Anyone can submit — no GitHub account.
// Until `endpoint` is set to your deployed Worker, `isConfigured` is false and AddSpaceView
// falls back to opening a prefilled GitHub issue in the browser.
enum SubmissionService {

    /// Deployed Cloudflare Worker (see backend/). Change if you rename the Worker.
    static let endpoint = "https://waqtsg-submit.xphyton.workers.dev/submit"

    /// Optional — must match the Worker's APP_KEY if you set one.
    static let appKey = ""

    static var isConfigured: Bool { !endpoint.contains("YOURNAME") }

    static func submit(building: String, floor: String, walk: String, type: String) async -> Bool {
        guard isConfigured, let url = URL(string: endpoint) else { return false }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.timeoutInterval = 15
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !appKey.isEmpty { req.setValue(appKey, forHTTPHeaderField: "X-App-Key") }
        let payload = ["building": building, "floor": floor, "walk": walk, "type": type]
        req.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        do {
            let (_, resp) = try await URLSession.shared.data(for: req)
            return (resp as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }
}
