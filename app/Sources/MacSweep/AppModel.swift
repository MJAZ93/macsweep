import AppKit
import Foundation
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    enum Phase: Equatable { case scanning, ready, failed(String) }

    enum ItemStatus { case pending, running, done }

    struct DeleteRun: Identifiable {
        let id = UUID()
        let items: [Item]
        var status: [Int: ItemStatus] = [:]
        var result: (freedK: Int64, freeK: Int64)?
        var error: String?
        var dryRun: Bool
        var finished: Bool { result != nil || error != nil }
    }

    @Published private(set) var phase: Phase = .scanning
    @Published private(set) var scan: ScanResult?
    @Published var selection = Set<Int>()
    @Published var showConfirm = false
    @Published var run: DeleteRun?

    // settings (persisted)
    @Published var langSetting: String { didSet { defaults.set(langSetting, forKey: "lang") } }
    @Published var projects: String { didSet { defaults.set(projects, forKey: "projects") } }
    @Published var days: Int { didSet { defaults.set(days, forKey: "days") } }
    @Published var minMB: Int { didSet { defaults.set(minMB, forKey: "minMB") } }
    @Published var fast: Bool { didSet { defaults.set(fast, forKey: "fast") } }
    @Published var dryRun: Bool { didSet { defaults.set(dryRun, forKey: "dryRun") } }

    private let defaults = UserDefaults.standard
    private let engine = Engine()
    private var started = false

    init() {
        langSetting = defaults.string(forKey: "lang") ?? "auto"
        projects = defaults.string(forKey: "projects") ?? ""
        days = defaults.object(forKey: "days") as? Int ?? 30
        minMB = defaults.object(forKey: "minMB") as? Int ?? 50
        fast = defaults.bool(forKey: "fast")
        dryRun = defaults.bool(forKey: "dryRun")
    }

    var lang: String { langSetting == "auto" ? Strings.systemLang() : langSetting }
    var t: Strings { Strings(lang: lang) }

    var options: ScanOptions {
        ScanOptions(projects: projects, days: days, minMB: minMB, fast: fast, dryRun: dryRun, lang: lang)
    }

    var items: [Item] { scan?.items ?? [] }
    func items(in tier: Tier) -> [Item] { items.filter { $0.tier == tier }.sorted { $0.sizeK > $1.sizeK } }
    func total(of tier: Tier) -> Int64 { items(in: tier).reduce(0) { $0 + $1.sizeK } }
    var selectedItems: [Item] {
        items.filter { selection.contains($0.id) }
            .sorted { ($0.tier.order, -$0.sizeK) < ($1.tier.order, -$1.sizeK) }
    }
    var selectedSize: Int64 { selectedItems.reduce(0) { $0 + $1.sizeK } }

    func isSelected(_ item: Item) -> Bool { selection.contains(item.id) }
    func setSelected(_ item: Item, _ on: Bool) {
        guard !item.blocked else { return }
        if on { selection.insert(item.id) } else { selection.remove(item.id) }
    }
    /// Like the terminal's "a": SAFE items only, never REBUILD or REVIEW.
    func selectAllSafe() {
        for i in items(in: .safe) where !i.blocked { selection.insert(i.id) }
    }

    func start() async {
        guard !started else { return }
        started = true
        await rescan()
        if ProcessInfo.processInfo.environment["MACSWEEP_DEMO_SELECT"] == "1" {
            selectAllSafe()
            if let i = items(in: .rebuild).first { selection.insert(i.id) }
        }
    }

    func rescan() async {
        guard phase != .scanning || scan == nil, run == nil else { return }
        phase = .scanning
        do {
            let r = try await engine.scan(options)
            scan = r
            selection = selection.filter { id in r.items.indices.contains(id) && !r.items[id].blocked }
            phase = .ready
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    func confirmAndDelete() {
        let picked = selectedItems.filter { !$0.blocked }
        guard !picked.isEmpty else { return }
        var r = DeleteRun(items: picked, dryRun: scan?.dryRun ?? dryRun)
        for i in picked { r.status[i.id] = .pending }
        run = r
        Task {
            do {
                try await engine.delete(ids: picked.map(\.id), options: options) { [weak self] ev in
                    self?.apply(ev)
                }
                if run?.result == nil { run?.error = EngineError.failed(-1).localizedDescription }
            } catch {
                run?.error = error.localizedDescription
            }
            selection.removeAll()
        }
    }

    private func apply(_ ev: ExecEvent) {
        switch ev {
        case .started(let id): run?.status[id] = .running
        case .finished(let id): run?.status[id] = .done
        case .done(let freed, let free):
            run?.result = (freed, free)
            if free > 0 { scan?.freeK = free }
        }
    }

    func closeRun() {
        run = nil
        Task { await rescan() }
    }

    func revealInFinder(_ path: String) {
        let url = URL(fileURLWithPath: path)
        if FileManager.default.fileExists(atPath: path) {
            NSWorkspace.shared.activateFileViewerSelecting([url])
        } else {
            NSWorkspace.shared.open(url.deletingLastPathComponent())
        }
    }
}

extension Tier {
    var order: Int { Tier.allCases.firstIndex(of: self) ?? 0 }
    var color: Color {
        switch self {
        case .safe: return .green
        case .rebuild: return .orange
        case .review: return .red
        }
    }
}
