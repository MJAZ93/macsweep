import SwiftUI

/// Same rule as the terminal: nothing is deleted until the confirmation word is typed.
struct ConfirmSheet: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var typed = ""

    var body: some View {
        let t = model.t
        let items = model.selectedItems
        let ok = typed.trimmingCharacters(in: .whitespaces) == t.confirmWord
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(t.confirmTitle(items.count)).font(.title2.weight(.bold))
                Text(t.confirmSub).foregroundStyle(.secondary)
            }
            ItemList(items: items) { item in
                Circle().fill(item.tier.color).frame(width: 8, height: 8).help(t.tier(item.tier))
            }
            HStack {
                Text(t.total).fontWeight(.bold)
                Spacer()
                Text(humanSize(model.selectedSize)).fontWeight(.bold).monospacedDigit()
            }
            .padding(.horizontal, 4)
            VStack(alignment: .leading, spacing: 6) {
                Text(t.typeToConfirm(t.confirmWord)).foregroundStyle(.secondary)
                TextField(t.confirmWord, text: $typed)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced).weight(.semibold))
                    .onSubmit { if ok { go() } }
            }
            HStack {
                Spacer()
                Button(t.cancel, role: .cancel) { dismiss() }.keyboardShortcut(.cancelAction)
                Button(t.delete, role: .destructive) { go() }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent).tint(.red)
                    .disabled(!ok)
            }
        }
        .padding(24)
        .frame(width: 520)
    }

    private func go() {
        dismiss()
        // let the confirm sheet finish closing before the progress sheet opens
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { model.confirmAndDelete() }
    }
}

struct ProgressSheet: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        let t = model.t
        if let run = model.run {
            VStack(alignment: .leading, spacing: 14) {
                Text(run.result != nil ? t.done : run.dryRun ? t.dryRun : t.deleting).font(.title2.weight(.bold))
                if let r = run.result {
                    VStack(spacing: 8) {
                        if run.dryRun {
                            Text(t.dryDone).font(.title3)
                        } else {
                            Text("\(humanSize(max(r.freedK, 0))) \(t.freed)")
                                .font(.system(size: 34, weight: .heavy)).foregroundStyle(.green).monospacedDigit()
                            if let scan = model.scan {
                                Text("\(humanSize(r.freeK)) \(t.free) \(t.of) \(humanSize(scan.totalK))")
                                    .foregroundStyle(.secondary).monospacedDigit()
                                Text("\(t.logAt) \(scan.logPath)").font(.caption).foregroundStyle(.tertiary)
                                    .textSelection(.enabled)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                } else {
                    Text(t.passwordNote).foregroundStyle(.secondary)
                    ItemList(items: run.items) { item in
                        switch run.status[item.id] ?? .pending {
                        case .pending: Image(systemName: "circle").foregroundStyle(.tertiary)
                        case .running: ProgressView().controlSize(.small)
                        case .done: Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                        }
                    }
                }
                if let err = run.error {
                    Label(err, systemImage: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                }
                HStack {
                    Spacer()
                    Button(t.close) { model.closeRun() }
                        .keyboardShortcut(.defaultAction)
                        .buttonStyle(.borderedProminent)
                        .disabled(!run.finished)
                }
            }
            .padding(24)
            .frame(width: 520)
            .interactiveDismissDisabled(!run.finished)
        }
    }
}

struct ItemList<Lead: View>: View {
    let items: [Item]
    @ViewBuilder let lead: (Item) -> Lead

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    if index > 0 { Divider() }
                    HStack(spacing: 10) {
                        lead(item).frame(width: 18)
                        Text(item.label).lineLimit(1).truncationMode(.middle)
                        Spacer()
                        if item.sizeK > 0 { Text(humanSize(item.sizeK)).fontWeight(.semibold).monospacedDigit() }
                    }
                    .padding(.horizontal, 12).padding(.vertical, 8)
                }
            }
        }
        .frame(maxHeight: 300)
        .fixedSize(horizontal: false, vertical: true)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(nsColor: .controlBackgroundColor)))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.primary.opacity(0.1)))
    }
}
