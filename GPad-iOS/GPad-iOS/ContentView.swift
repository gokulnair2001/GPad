//
//  ContentView.swift
//  GPad-iOS
//
//  Created by Gokul Nair on 19/03/26.
//

import SwiftUI
import AVFoundation

// MARK: - ContentView

struct ContentView: View {

    @StateObject private var connectionManager = ConnectionManager()
    @State private var pressedKey: Int?
    @State private var clickPlayer: AVAudioPlayer?

    private let buttonCount = 3

    @State private var pulsePhase: Bool = false

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                appInfoBar
                buttonGrid
            }

            connectionSidebar
                .frame(width: 56)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            setupAudio()
            connectionManager.startSearching()
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulsePhase = true
            }
        }
    }

    // MARK: - App Info Bar

    private var appInfoBar: some View {
        HStack(spacing: 12) {
            // App icon
            Group {
                if let icon = connectionManager.currentAppIcon {
                    Image(uiImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(white: 0.18), Color(white: 0.12)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Image(systemName: connectionManager.isConnected ? "app.fill" : "macwindow")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white.opacity(0.3))
                        )
                }
            }
            .frame(width: 44, height: 44)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .shadow(color: .white.opacity(0.05), radius: 4, y: 1)

            // App name + connection status
            VStack(alignment: .leading, spacing: 3) {
                Text(connectionManager.currentAppName ?? (connectionManager.isConnected ? "Waiting for context…" : "GPad"))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(1)

                HStack(spacing: 5) {
                    Circle()
                        .fill(connectionManager.isConnected ? Color.green : Color.orange)
                        .frame(width: 6, height: 6)
                        .shadow(color: (connectionManager.isConnected ? Color.green : Color.orange).opacity(0.6), radius: 3)

                    Text("Gokul Nair")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.45))
                        .lineLimit(1)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Rectangle()
                .fill(Color.black)
//                .overlay(
//                    Rectangle()
//                        .fill(Color.white.opacity(0.06))
//                        .frame(height: 1),
//                    alignment: .bottom
//                )
        )
        .animation(.easeInOut(duration: 0.3), value: connectionManager.currentAppName)
        .animation(.easeInOut(duration: 0.3), value: connectionManager.isConnected)
    }

    private var statusText: String {
        if connectionManager.isConnected {
            if let mac = connectionManager.connectedMacName {
                return mac
            }
            return "Connected"
        }
        return "Searching…"
    }

    // MARK: - Connection sidebar

    private var connectionSidebar: some View {
        ZStack {
            GeometryReader { geo in
                let count = buttonCount
                let totalSpacing: CGFloat = 6 * (CGFloat(count) - 1) + 12
                let side = (geo.size.height - totalSpacing) / CGFloat(count)

                VStack(spacing: 6) {
                    ForEach(0..<count, id: \.self) { index in
                        connectionPin(height: side, index: index)
                    }
                }
                .padding(.vertical, 6)
                .clipped()
            }

            if !connectionManager.isConnected {
                Text("Place next to Mac")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(pulsePhase ? 0.55 : 0.25))
                    .rotationEffect(.degrees(-90))
                    .fixedSize()
                    .frame(width: 20)
                    .allowsHitTesting(false)
            }
        }
    }

    private func connectionPin(height: CGFloat, index: Int) -> some View {
        ZStack {
            if connectionManager.isConnected {
                // Connected: minimal dock pin — physical contact point
                HStack(spacing: 0) {
                    Spacer()

                    // Pin contact — small notch flush to the right edge
                    RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                        .fill(
                            Color.green.opacity(pulsePhase ? 0.7 : 0.4)
                        )
                        .frame(width: 10, height: 4)
                        .shadow(color: .green.opacity(pulsePhase ? 0.5 : 0.2), radius: 4, x: 0, y: 0)

                    // Edge nub — sits right at the bezel
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.green.opacity(pulsePhase ? 0.8 : 0.5))
                        .frame(width: 3, height: 8)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.5, anchor: .trailing)))
            } else {
                // Searching: animated dashes pointing right
                HStack(spacing: 3) {
                    ForEach(0..<4, id: \.self) { dashIndex in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.white.opacity(
                                pulsePhase
                                    ? 0.08 + Double(dashIndex) * 0.08
                                    : 0.20 - Double(dashIndex) * 0.03
                            ))
                            .frame(width: dashIndex == 3 ? 6 : 4, height: 2)
                    }

                    // Arrow tip
                    Image(systemName: "chevron.right")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white.opacity(pulsePhase ? 0.35 : 0.12))
                }
                .offset(x: pulsePhase ? 12 : -12)
            }
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .clipped()
        .animation(
            .easeInOut(duration: 1.0)
                .delay(Double(index) * 0.1)
                .repeatForever(autoreverses: true),
            value: pulsePhase
        )
        .animation(.easeInOut(duration: 0.4), value: connectionManager.isConnected)
    }

    // MARK: - Button grid

    private var buttonGrid: some View {
        GeometryReader { geo in
            let count = CGFloat(buttonCount)
            let totalSpacing: CGFloat = 6 * (count - 1) + 12
            let side = (geo.size.height - totalSpacing) / count
            VStack(spacing: 6) {
                ForEach(1...buttonCount, id: \.self) { index in
                    let label = buttonLabel(for: index)
                    MacroKeyView(
                        isPressed: pressedKey == index,
                        label: label
                    )
                    .frame(width: side, height: side)
                    .onTapGesture { handleTap(index) }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(6)
        }
    }

    private func buttonLabel(for index: Int) -> String? {
        let labels = connectionManager.buttonLabels
        guard index - 1 < labels.count else { return nil }
        let label = labels[index - 1]
        return label.isEmpty ? nil : label
    }

    // MARK: - Tap handling

    private func handleTap(_ buttonIndex: Int) {
        triggerHaptic()

        withAnimation(.easeInOut(duration: 0.08)) { pressedKey = buttonIndex }

        connectionManager.sendButtonTap(buttonIndex)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.easeOut(duration: 0.08)) { pressedKey = nil }
        }
    }

    private func setupAudio() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: .mixWithOthers)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    private func triggerHaptic() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        if let url = Bundle.main.url(forResource: "key_press_click", withExtension: "caf")
            ?? URL(string: "/System/Library/Audio/UISounds/key_press_click.caf") {
            clickPlayer = try? AVAudioPlayer(contentsOf: url)
            clickPlayer?.volume = 1.0
            clickPlayer?.play()
        }
    }
}

// MARK: - Single Key View

struct MacroKeyView: View {

    let isPressed: Bool
    var label: String? = nil

    private let cr: CGFloat = 18

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let inset: CGFloat = w * 0.05

            ZStack {
                // LAYER 1 — Base shadow (sits behind the keycap)
                RoundedRectangle(cornerRadius: cr + 2, style: .continuous)
                    .fill(Color(white: 0.08))
                    .shadow(
                        color: .black.opacity(isPressed ? 0.4 : 0.9),
                        radius: isPressed ? 2 : 6,
                        x: 0, y: isPressed ? 1 : 4
                    )

                // LAYER 2 — Keycap body (raised surface)
                RoundedRectangle(cornerRadius: cr, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(white: isPressed ? 0.16 : 0.20),
                                Color(white: isPressed ? 0.12 : 0.14),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .padding(isPressed ? inset + 1 : inset)

                // LAYER 3 — Top edge highlight (lit from above)
                RoundedRectangle(cornerRadius: cr, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isPressed ? 0.06 : 0.18),
                                Color.white.opacity(0.04),
                                Color.clear,
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
                    .padding(isPressed ? inset + 1 : inset)

                // LAYER 4 — Concave dish (circular depression)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.black.opacity(isPressed ? 0.18 : 0.12),
                                Color.black.opacity(0.04),
                                Color.clear,
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: w * 0.28
                        )
                    )
                    .frame(width: w * 0.55, height: w * 0.55)
                    .allowsHitTesting(false)

                // LAYER 5 — Dish inner ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isPressed ? 0.08 : 0.20),
                                Color.white.opacity(isPressed ? 0.03 : 0.06),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1.5
                    )
                    .frame(width: w * 0.58, height: w * 0.58)
                    .allowsHitTesting(false)

                // LAYER 6 — Specular highlight (top-left gloss)
                RoundedRectangle(cornerRadius: cr, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isPressed ? 0.02 : 0.08),
                                Color.clear,
                            ],
                            startPoint: .init(x: 0.15, y: 0),
                            endPoint: .init(x: 0.5, y: 0.4)
                        )
                    )
                    .padding(isPressed ? inset + 1 : inset)
                    .allowsHitTesting(false)
            }
        }
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .offset(y: isPressed ? 3 : 0)
        .animation(.spring(response: 0.15, dampingFraction: 0.6), value: isPressed)
    }
}

#Preview {
    ContentView()
}
