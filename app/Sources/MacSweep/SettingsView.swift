import AppKit
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        let t = model.t
        Form {
            Section(t.general) {
                Picker(t.language, selection: $model.langSetting) {
                    Text(t.automatic).tag("auto")
                    Text("English").tag("en")
                    Text("Português").tag("pt")
                }
                Toggle(t.dryRunToggle, isOn: $model.dryRun)
            }
            Section(t.scanSection) {
                LabeledContent(t.projectsFolder) {
                    HStack {
                        Text(model.projects.isEmpty ? t.autoDetect : (model.projects as NSString).abbreviatingWithTildeInPath)
                            .foregroundStyle(model.projects.isEmpty ? .secondary : .primary)
                            .lineLimit(1).truncationMode(.middle)
                        Button(t.choose) { chooseFolder() }
                        if !model.projects.isEmpty { Button(t.reset) { model.projects = "" } }
                    }
                }
                Stepper(value: $model.days, in: 1...365) {
                    LabeledContent(t.inactiveAfter, value: "\(model.days) \(t.days)")
                }
                Stepper(value: $model.minMB, in: 0...10_000, step: 10) {
                    LabeledContent(t.hideBelow, value: "\(model.minMB) MB")
                }
                Toggle(t.skipProjects, isOn: $model.fast)
            }
            Section {
                HStack {
                    Text(t.settingsNote).foregroundStyle(.secondary)
                    Spacer()
                    Button(t.rescanNow) { Task { await model.rescan() } }
                        .disabled(model.phase == .scanning || model.run != nil)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 520)
        .fixedSize(horizontal: false, vertical: true)
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = model.t.choose.replacingOccurrences(of: "…", with: "")
        if !model.projects.isEmpty { panel.directoryURL = URL(fileURLWithPath: model.projects) }
        if panel.runModal() == .OK, let url = panel.url { model.projects = url.path }
    }
}
