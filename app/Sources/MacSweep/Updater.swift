import Foundation

/// Looks up the latest GitHub release. No background agent and no auto-install:
/// the app only offers the new DMG, the person drags it over the old one.
struct Release: Equatable {
    let version: String
    let url: URL  // the .dmg asset, or the release page when there is none
}

enum Updater {
    static let latestAPI = URL(string: "https://api.github.com/repos/MJAZ93/macsweep/releases/latest")!

    static var currentVersion: String? {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }

    static func latest() async throws -> Release {
        var req = URLRequest(url: latestAPI, timeoutInterval: 15)
        req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        let (data, response) = try await URLSession.shared.data(for: req)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
        return try parse(data)
    }

    static func parse(_ data: Data) throws -> Release {
        struct Asset: Decodable { let name: String; let browser_download_url: String }
        struct Payload: Decodable { let tag_name: String; let html_url: String; let assets: [Asset] }
        let p = try JSONDecoder().decode(Payload.self, from: data)
        let version = p.tag_name.hasPrefix("v") ? String(p.tag_name.dropFirst()) : p.tag_name
        let dmg = p.assets.first { $0.name.hasSuffix(".dmg") }.flatMap { URL(string: $0.browser_download_url) }
        guard let url = dmg ?? URL(string: p.html_url) else { throw URLError(.badURL) }
        return Release(version: version, url: url)
    }

    /// Numeric, component-wise: 1.10.0 > 1.9.2, 1.2 == 1.2.0.
    static func isNewer(_ a: String, than b: String) -> Bool {
        let x = a.split(separator: ".").map { Int($0) ?? 0 }, y = b.split(separator: ".").map { Int($0) ?? 0 }
        for i in 0..<max(x.count, y.count) {
            let l = i < x.count ? x[i] : 0, r = i < y.count ? y[i] : 0
            if l != r { return l > r }
        }
        return false
    }
}
