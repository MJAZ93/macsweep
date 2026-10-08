import Foundation

// The app does not reimplement the catalog. It runs the bundled `macsweep`
// script in its two internal modes and reads what it writes:
//   macsweep __scan DIR [options]   → DIR/scan.dat (NUL-separated, "macsweep-ui-1")
//   macsweep __exec DIR 3,7,12      → stdout lines S<tab>id, D<tab>id, F<tab>freed_k<tab>free_k

enum Tier: String, CaseIterable, Identifiable {
    case safe = "SAFE", rebuild = "REBUILD", review = "REVIEW"
    var id: String { rawValue }
}

struct Item: Identifiable, Hashable {
    let id: Int
    let tier: Tier
    let label: String
    let note: String
    /// Name of the app that blocks the item ("Xcode"), or a full message when `blockIsMessage`.
    let block: String
    let blockIsMessage: Bool
    let blocked: Bool
    let sizeK: Int64
    let paths: [String]
}

struct ScanResult {
    var version: String
    var lang: String
    var totalK: Int64
    var freeK: Int64
    var projects: String
    var dryRun: Bool
    var minMB: Int
    var logPath: String
    var items: [Item]

    static func parse(_ data: Data) throws -> ScanResult {
        let f = data.split(separator: 0, omittingEmptySubsequences: false).map { String(decoding: $0, as: UTF8.self) }
        guard f.count >= 10, f[0] == "macsweep-ui-1" else { throw EngineError.badScanFile }
        let n = Int(f[9]) ?? 0
        guard f.count >= 10 + n * 7 else { throw EngineError.badScanFile }
        var items: [Item] = []
        for i in 0..<n {
            let b = 10 + i * 7
            guard let tier = Tier(rawValue: f[b]) else { continue }
            let block = f[b + 3], handler = f[b + 4]
            let isMsg = block.hasPrefix("!")
            items.append(Item(
                id: i, tier: tier, label: f[b + 1], note: f[b + 2],
                block: isMsg ? String(block.dropFirst()) : block, blockIsMessage: isMsg,
                blocked: !block.isEmpty || handler == "none",
                sizeK: Int64(f[b + 5]) ?? 0,
                paths: f[b + 6].split(separator: "\n").map(String.init)))
        }
        return ScanResult(version: f[1], lang: f[2], totalK: Int64(f[3]) ?? 0, freeK: Int64(f[4]) ?? 0,
                          projects: f[5], dryRun: f[6] == "1", minMB: Int(f[7]) ?? 0, logPath: f[8], items: items)
    }
}

struct ScanOptions {
    var projects: String = ""
    var days: Int = 30
    var minMB: Int = 50
    var fast: Bool = false
    var dryRun: Bool = false
    var lang: String = "en"

    var arguments: [String] {
        var a = ["--days", String(days), "--min-mb", String(minMB), "--lang", lang]
        if !projects.isEmpty { a += ["--projects", projects] }
        if fast { a.append("--fast") }
        if dryRun { a.append("--dry-run") }
        return a
    }
}

enum ExecEvent: Equatable {
    case started(Int)
    case finished(Int)
    case done(freedK: Int64, freeK: Int64)

    static func parse(_ line: Substring) -> ExecEvent? {
        let f = line.split(separator: "\t", omittingEmptySubsequences: false)
        guard let kind = f.first else { return nil }
        switch (String(kind), f.count) {
        case ("S", 2): return Int(f[1]).map(ExecEvent.started)
        case ("D", 2): return Int(f[1]).map(ExecEvent.finished)
        case ("F", 3): return .done(freedK: Int64(f[1]) ?? 0, freeK: Int64(f[2]) ?? 0)
        default: return nil
        }
    }
}

enum EngineError: LocalizedError {
    case scriptMissing, badScanFile, failed(Int32)
    var errorDescription: String? {
        switch self {
        case .scriptMissing: return "The macsweep script is missing from the app bundle."
        case .badScanFile: return "The scan produced an unexpected result."
        case .failed(let code): return "macsweep exited with status \(code)."
        }
    }
}

final class Engine {
    let script: URL?
    let workDir: URL
    /// Set MACSWEEP_DEMO_DUMP to a scan.dat to show it instead of scanning (screenshots, UI work).
    let demoDump: URL? = ProcessInfo.processInfo.environment["MACSWEEP_DEMO_DUMP"].map { URL(fileURLWithPath: $0) }

    init() {
        let env = ProcessInfo.processInfo.environment
        if let s = env["MACSWEEP_SCRIPT"] {
            script = URL(fileURLWithPath: s)
        } else if let s = Bundle.main.url(forResource: "macsweep", withExtension: nil) {
            script = s
        } else {  // `swift run` from app/: use the script at the repo root
            let dev = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("../macsweep").standardized
            script = FileManager.default.fileExists(atPath: dev.path) ? dev : nil
        }
        workDir = FileManager.default.temporaryDirectory.appendingPathComponent("macsweep-app-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: workDir, withIntermediateDirectories: true,
                                                 attributes: [.posixPermissions: 0o700])
    }

    deinit { try? FileManager.default.removeItem(at: workDir) }

    private var dumpURL: URL { workDir.appendingPathComponent("scan.dat") }

    private func process(_ args: [String]) throws -> Process {
        guard let script else { throw EngineError.scriptMissing }
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/bin/bash")
        p.arguments = [script.path] + args
        // GUI apps start with a minimal PATH; the handlers call brew, docker, xcrun, git.
        var env = ProcessInfo.processInfo.environment
        env["PATH"] = "/opt/homebrew/bin:/usr/local/bin:" + (env["PATH"] ?? "/usr/bin:/bin:/usr/sbin:/sbin")
        p.environment = env
        p.standardInput = FileHandle.nullDevice
        p.standardError = FileHandle.nullDevice
        return p
    }

    func scan(_ options: ScanOptions) async throws -> ScanResult {
        if let demoDump {
            try await Task.sleep(nanoseconds: 600_000_000)
            try FileManager.default.copyItem(at: demoDump, to: dumpURL.appendingPathExtension("demo"))
            try? FileManager.default.removeItem(at: dumpURL)
            try FileManager.default.moveItem(at: dumpURL.appendingPathExtension("demo"), to: dumpURL)
            return try ScanResult.parse(Data(contentsOf: dumpURL))
        }
        let p = try process(["__scan", workDir.path] + options.arguments)
        p.standardOutput = FileHandle.nullDevice
        let status: Int32 = try await withCheckedThrowingContinuation { cont in
            p.terminationHandler = { cont.resume(returning: $0.terminationStatus) }
            do { try p.run() } catch { p.terminationHandler = nil; cont.resume(throwing: error) }
        }
        guard status == 0 else { throw EngineError.failed(status) }
        return try ScanResult.parse(Data(contentsOf: dumpURL))
    }

    /// Deletes the items and reports progress on the main queue. Returns when the script has exited.
    func delete(ids: [Int], options: ScanOptions, onEvent: @escaping (ExecEvent) -> Void) async throws {
        if demoDump != nil {
            for id in ids {
                await MainActor.run { onEvent(.started(id)) }
                try await Task.sleep(nanoseconds: 350_000_000)
                await MainActor.run { onEvent(.finished(id)) }
            }
            await MainActor.run { onEvent(.done(freedK: 0, freeK: 0)) }
            return
        }
        let p = try process(["__exec", workDir.path, ids.map(String.init).joined(separator: ",")] + options.arguments)
        let pipe = Pipe()
        p.standardOutput = pipe
        try p.run()
        let status: Int32 = await withCheckedContinuation { cont in
            DispatchQueue.global(qos: .userInitiated).async {
                let h = pipe.fileHandleForReading
                var buf = Data()
                while true {
                    let chunk = h.availableData  // blocks until data or EOF
                    if chunk.isEmpty { break }
                    buf.append(chunk)
                    while let nl = buf.firstIndex(of: 10) {
                        let line = String(decoding: buf[buf.startIndex..<nl], as: UTF8.self)
                        buf.removeSubrange(buf.startIndex...nl)
                        if let ev = ExecEvent.parse(Substring(line)) { DispatchQueue.main.async { onEvent(ev) } }
                    }
                }
                p.waitUntilExit()
                DispatchQueue.main.async { cont.resume(returning: p.terminationStatus) }
            }
        }
        guard status == 0 else { throw EngineError.failed(status) }
    }
}

func humanSize(_ k: Int64) -> String {
    let d = Double(k)
    if k >= 1_048_576 { return String(format: "%.1f GB", d / 1_048_576) }
    if k >= 1024 { return String(format: "%.0f MB", d / 1024) }
    return String(format: "%.0f KB", d)
}
