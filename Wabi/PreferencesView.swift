import SwiftUI
import ServiceManagement

struct PreferencesView: View {
    var onBindingsChanged: () -> Void

    @State private var bindings: [HotkeyTarget: HotkeyBinding?] = [:]
    @State private var launchAtLogin = false

    var body: some View {
        Form {
            Section("General") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { newValue in
                        if newValue {
                            try? SMAppService.mainApp.register()
                        } else {
                            try? SMAppService.mainApp.unregister()
                        }
                    }
            }

            Section("Spaces") {
                ForEach(1...9, id: \.self) { n in
                    LabeledRow(label: "Space \(n)") {
                        HotkeyRecorder(
                            target: .space(n),
                            binding: bindingState(for: .space(n)),
                            onSave: onBindingsChanged
                        )
                    }
                }
            }

            Section("System") {
                LabeledRow(label: "Menu Bar") {
                    HotkeyRecorder(
                        target: .menuBar,
                        binding: bindingState(for: .menuBar),
                        onSave: onBindingsChanged
                    )
                }
                LabeledRow(label: "Dock") {
                    HotkeyRecorder(
                        target: .dock,
                        binding: bindingState(for: .dock),
                        onSave: onBindingsChanged
                    )
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 340)
        .onAppear(perform: load)
    }

    private func load() {
        let targets: [HotkeyTarget] = (1...9).map { .space($0) } + [.menuBar, .dock]
        for t in targets { bindings[t] = Config.binding(for: t) }
        launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    // Bridges the [HotkeyTarget: HotkeyBinding?] dict into a Binding<HotkeyBinding?>
    private func bindingState(for target: HotkeyTarget) -> Binding<HotkeyBinding?> {
        Binding(
            get: { self.bindings[target] ?? nil },
            set: { self.bindings[target] = $0 }
        )
    }
}

// Simple helper to keep rows consistent
private struct LabeledRow<Content: View>: View {
    let label: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack {
            Text(label).frame(width: 64, alignment: .leading)
            content()
        }
    }
}
