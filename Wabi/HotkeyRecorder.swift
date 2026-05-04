import SwiftUI
import AppKit
import CoreGraphics

struct HotkeyRecorder: View {
    let target: HotkeyTarget
    @Binding var binding: HotkeyBinding?
    var onSave: () -> Void

    @State private var isRecording = false
    @State private var monitor: Any?

    // Key codes that are pure modifier keys — ignore these during recording
    private static let modifierKeyCodes: Set<UInt16> = [54, 55, 56, 57, 58, 59, 60, 61, 62, 63]

    var body: some View {
        HStack(spacing: 8) {
            Button(action: toggleRecording) {
                Text(isRecording ? "Type shortcut…" : (binding?.displayString ?? "–"))
                    .frame(width: 120, alignment: .center)
                    .foregroundColor(isRecording ? .secondary : .primary)
            }
            .buttonStyle(.bordered)

            Button("Clear") {
                stopRecording()
                binding = nil
                Config.setBinding(nil, for: target)
                onSave()
            }
            .disabled(binding == nil && !isRecording)
        }
        .onDisappear { stopRecording() }
    }

    private func toggleRecording() {
        isRecording ? stopRecording() : startRecording()
    }

    private func startRecording() {
        if let m = monitor {
            NSEvent.removeMonitor(m)
            monitor = nil
        }
        isRecording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 {  // Escape cancels
                self.stopRecording()
                return nil
            }
            if Self.modifierKeyCodes.contains(event.keyCode) { return event }

            let newBinding = HotkeyBinding(
                keyCode: event.keyCode,
                modifiers: CGEventFlags(nsModifiers: event.modifierFlags)
            )
            self.binding = newBinding
            Config.setBinding(newBinding, for: self.target)
            self.onSave()
            self.stopRecording()
            return nil  // consume the event
        }
    }

    private func stopRecording() {
        isRecording = false
        if let m = monitor {
            NSEvent.removeMonitor(m)
            monitor = nil
        }
    }
}
