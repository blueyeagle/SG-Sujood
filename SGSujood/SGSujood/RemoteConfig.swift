import Foundation

// MARK: - Remote-config host
//
// All of the app's live-updatable JSON (nisab, prayer spaces, terawih venues, prayer times)
// is served by a Cloudflare Worker instead of raw.githubusercontent.com. The Worker edge-caches
// each file at Cloudflare's Singapore PoP, isn't rate-limited the way GitHub's raw host is, and
// keeps working even if the source repo is made private. GitHub stays the source of truth — the
// Worker just proxies + caches it (see backend-data/worker.js).
//
// To move to a custom domain later (e.g. https://data.sgsujood.app), change `host` here only.
enum RemoteConfig {
    static let host = "https://sgsujood-data.xphyton.workers.dev"

    /// URL for a hosted config file, e.g. RemoteConfig.url("nisab.json").
    static func url(_ file: String) -> URL? { URL(string: "\(host)/\(file)") }
}
