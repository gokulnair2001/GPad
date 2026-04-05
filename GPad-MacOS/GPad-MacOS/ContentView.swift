import SwiftUI

struct ContentView: View {
    var manager: MultipeerManager

    var body: some View {
        VStack(spacing: 0) {
            // Connection status + current app context
            HStack {
                Circle()
                    .fill(manager.isConnected ? .green : .orange)
                    .frame(width: 10, height: 10)
                Text(manager.isConnected
                     ? "Connected — \(manager.connectedDeviceName ?? "iPhone")"
                     : "Waiting for iPhone…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 4)

            HStack {
                Text(manager.currentAppName)
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                Spacer()
                Text(manager.currentMapping.appName == "Default" ? "Default mapping" : "App-specific")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(manager.currentMapping.appName == "Default"
                                ? Color.gray.opacity(0.2)
                                : Color.accentColor.opacity(0.15),
                                in: Capsule())
            }
            .padding(.horizontal)
            .padding(.bottom, 8)

            Divider()

            // 3 button labels with shortcuts
            VStack(spacing: 8) {
                ForEach(Array(manager.currentMapping.buttons.enumerated()), id: \.offset) { index, action in
                    HStack {
                        Text("\(index + 1)")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .foregroundStyle(.secondary)
                            .frame(width: 32)

                        Text(action.label)
                            .font(.system(.body, design: .rounded, weight: .medium))

                        Spacer()

                        Text(action.shortcut)
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(12)
                    .background(.fill.quaternary, in: RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding()
            .animation(.easeInOut(duration: 0.2), value: manager.currentAppName)

            Divider()

            // Activity log
            VStack(alignment: .leading, spacing: 4) {
                Text("Activity")
                    .font(.caption.bold())
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal)
                    .padding(.top, 8)

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(manager.actionLog.enumerated()), id: \.offset) { _, entry in
                            Text(entry)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .frame(maxHeight: .infinity)
        }
        .frame(width: 320, height: 500)
    }
}
