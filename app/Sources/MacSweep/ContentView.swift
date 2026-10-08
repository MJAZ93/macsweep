import AppKit
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        let t = model.t
        VStack(spacing: 0) {
            if let scan = model.scan {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 22) {
                            DiskHeader(scan: scan)
                            if scan.dryRun {
                                Label(t.dryRunBanner, systemImage: "testtube.2")
                                    .font(.callout.weight(.medium))
                                    .foregroundStyle(.orange)
                                    .padding(.horizontal, 14).padding(.vertical, 10)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                            }
                            HStack(spacing: 12) {
                                ForEach(Tier.allCases) { tier in
                                    TierCard(tier: tier) { withAnimation { proxy.scrollTo(tier, anchor: .top) } }
                                }
                            }
                            ForEach(Tier.allCases) { tier in
                                TierSection(tier: tier).id(tier)
                            }
                        }
                        .padding(24)
                        .frame(maxWidth: 980)
                        .frame(maxWidth: .infinity)
                    }
                }
                if !model.selection.isEmpty { SelectionBar() }
            } else if case .failed(let msg) = model.phase {
                ErrorView(message: msg)
            } else {
                Spacer()
            }
        }
        .overlay {
            if model.phase == .scanning { ScanningOverlay() }
        }
        .animation(.easeInOut(duration: 0.18), value: model.selection.isEmpty)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { Task { await model.rescan() } } label: {
                    Label(t.rescan, systemImage: "arrow.clockwise")
                }
                .help(t.rescan)
                .disabled(model.phase == .scanning || model.run != nil)
            }
        }
        .sheet(isPresented: $model.showConfirm) { ConfirmSheet().environmentObject(model) }
        .sheet(item: $model.run) { _ in ProgressSheet().environmentObject(model) }
        .task { await model.start() }
    }
}

// MARK: - disk

struct DiskHeader: View {
    @EnvironmentObject var model: AppModel
    let scan: ScanResult

    var body: some View {
        let t = model.t
        let total = max(scan.totalK, 1)
        let used = max(scan.totalK - scan.freeK, 0)
        let picked = min(model.selectedSize, used)
        let pct = Double(used) * 100 / Double(total)
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("\(humanSize(scan.freeK)) \(t.free)")
                    .font(.system(size: 30, weight: .bold)).monospacedDigit()
                Text("\(t.of) \(humanSize(scan.totalK)) · \(Int(pct.rounded()))% \(t.used)")
                    .foregroundStyle(.secondary).monospacedDigit()
                Spacer()
                if picked > 0 {
                    Text(t.freeAfter(humanSize(scan.freeK + picked)))
                        .font(.headline).foregroundStyle(.green).monospacedDigit()
                }
            }
            GeometryReader { g in
                let w = g.size.width
                HStack(spacing: 0) {
                    Rectangle().fill(pct > 90 ? Color.red : pct > 75 ? Color.orange : Color.secondary)
                        .opacity(0.75)
                        .frame(width: w * CGFloat(used - picked) / CGFloat(total))
                    Rectangle().fill(Color.green)
                        .frame(width: w * CGFloat(picked) / CGFloat(total))
                    Spacer(minLength: 0)
                }
                .background(Color.secondary.opacity(0.15))
                .clipShape(Capsule())
                .animation(.easeOut(duration: 0.3), value: picked)
            }
            .frame(height: 12)
            HStack(spacing: 14) {
                if !scan.projects.isEmpty { Text("\(t.projects): \(scan.projects)") }
                Text(t.hiding(scan.minMB))
            }
            .font(.caption).foregroundStyle(.tertiary)
        }
    }
}

// MARK: - tiers

struct TierBadge: View {
    @EnvironmentObject var model: AppModel
    let tier: Tier
    var body: some View {
        HStack(spacing: 5) {
            Circle().fill(tier.color).frame(width: 7, height: 7)
            Text(model.t.tier(tier)).font(.system(size: 11, weight: .bold)).tracking(0.6)
        }
        .foregroundStyle(tier.color)
        .padding(.horizontal, 8).padding(.vertical, 3)
        .background(tier.color.opacity(0.13), in: RoundedRectangle(cornerRadius: 6))
    }
}

struct TierCard: View {
    @EnvironmentObject var model: AppModel
    let tier: Tier
    let action: () -> Void

    var body: some View {
        let t = model.t
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                TierBadge(tier: tier)
                Text(humanSize(model.total(of: tier))).font(.system(size: 22, weight: .bold)).monospacedDigit()
                Text("\(t.items(model.items(in: tier).count)) · \(t.tierDescription(tier))")
                    .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(nsColor: .controlBackgroundColor)))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.primary.opacity(0.08)))
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

struct TierSection: View {
    @EnvironmentObject var model: AppModel
    let tier: Tier

    var body: some View {
        let t = model.t
        let items = model.items(in: tier)
        let maxSize = max(model.items.map(\.sizeK).max() ?? 1, 1)
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                TierBadge(tier: tier)
                Text(humanSize(model.total(of: tier))).fontWeight(.bold).monospacedDigit()
                Text(t.tierDescription(tier)).foregroundStyle(.secondary)
                Spacer()
                if tier == .safe && items.contains(where: { !$0.blocked }) {
                    Button(t.selectAllSafe) { model.selectAllSafe() }.controlSize(.small)
                }
            }
            .padding(.horizontal, 4)
            VStack(spacing: 0) {
                if items.isEmpty {
                    Text(t.nothingAbove(model.scan?.minMB ?? 50))
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                }
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    if index > 0 { Divider() }
                    ItemRow(item: item, fraction: Double(item.sizeK) / Double(maxSize))
                }
            }
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(nsColor: .controlBackgroundColor)))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.primary.opacity(0.08)))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct ItemRow: View {
    @EnvironmentObject var model: AppModel
    let item: Item
    let fraction: Double
    @State private var showPaths = false

    var body: some View {
        let t = model.t
        let on = Binding(get: { model.isSelected(item) }, set: { model.setSelected(item, $0) })
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Toggle(isOn: on) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.label).fontWeight(.semibold)
                        if !item.note.isEmpty {
                            Text(item.note).font(.callout).foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.leading, 4)
                }
                .toggleStyle(.checkbox)
                .disabled(item.blocked)
                if !item.block.isEmpty {
                    Label(item.blockIsMessage ? item.block : t.inUse(item.block), systemImage: "exclamationmark.triangle.fill")
                        .font(.callout.weight(.medium)).foregroundStyle(.orange)
                        .padding(.leading, 24)
                }
                if !item.paths.isEmpty {
                    DisclosureGroup(t.paths(item.paths.count), isExpanded: $showPaths) {
                        VStack(alignment: .leading, spacing: 3) {
                            ForEach(item.paths, id: \.self) { p in
                                HStack(spacing: 6) {
                                    Text(p).font(.caption.monospaced()).foregroundStyle(.secondary)
                                        .textSelection(.enabled).lineLimit(2).truncationMode(.middle)
                                    Button { model.revealInFinder(p) } label: { Image(systemName: "arrow.right.circle") }
                                        .buttonStyle(.borderless).help(t.showInFinder)
                                }
                            }
                        }
                        .padding(.top, 2)
                    }
                    .font(.caption).foregroundStyle(.tertiary)
                    .padding(.leading, 24)
                }
            }
            Spacer(minLength: 8)
            Text(item.sizeK > 0 ? humanSize(item.sizeK) : t.notApplicable)
                .font(.body.weight(item.sizeK > 0 ? .bold : .regular)).monospacedDigit()
                .foregroundStyle(item.sizeK > 0 ? Color.primary : Color.secondary)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(model.isSelected(item) ? Color.accentColor.opacity(0.07) : Color.clear)
        .overlay(alignment: .bottomLeading) {
            GeometryReader { g in
                Rectangle().fill(Color.accentColor.opacity(0.35))
                    .frame(width: g.size.width * fraction, height: 2)
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
        }
        .contextMenu {
            ForEach(item.paths, id: \.self) { p in
                Button("\(t.showInFinder): \((p as NSString).lastPathComponent)") { model.revealInFinder(p) }
            }
        }
    }
}

// MARK: - bars and overlays

struct SelectionBar: View {
    @EnvironmentObject var model: AppModel
    var body: some View {
        let t = model.t
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 14) {
                Text(humanSize(model.selectedSize)).font(.title3.weight(.bold)).monospacedDigit()
                Text(t.selected(model.selection.count)).foregroundStyle(.secondary)
                Spacer()
                Button(t.deselectAll) { model.selection.removeAll() }
                Button(t.reviewAndDelete) { model.showConfirm = true }
                    .buttonStyle(.borderedProminent).tint(.red)
                    .keyboardShortcut(.delete, modifiers: .command)
            }
            .padding(.horizontal, 24).padding(.vertical, 14)
        }
        .background(.bar)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

struct ScanningOverlay: View {
    @EnvironmentObject var model: AppModel
    var body: some View {
        ZStack {
            Rectangle().fill(.regularMaterial)
            VStack(spacing: 14) {
                ProgressView().controlSize(.large)
                Text(model.t.measuring).font(.title3.weight(.semibold))
                Text(model.t.measuringSub).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
            .padding(40)
        }
        .transition(.opacity)
    }
}

struct ErrorView: View {
    @EnvironmentObject var model: AppModel
    let message: String
    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "exclamationmark.triangle").font(.system(size: 36)).foregroundStyle(.orange)
            Text(model.t.errorTitle).font(.title3.weight(.semibold))
            Text(message).foregroundStyle(.secondary).multilineTextAlignment(.center).textSelection(.enabled)
            Button(model.t.tryAgain) { Task { await model.rescan() } }
            Spacer()
        }
        .padding(40)
        .frame(maxWidth: .infinity)
    }
}
