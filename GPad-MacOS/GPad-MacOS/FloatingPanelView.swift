import SwiftUI

struct FloatingPanelView: View {
    var manager: MultipeerManager
    @State private var isCollapsed = false
    @State private var hoveredIndex: Int? = nil

    var body: some View {
        Group {
            if isCollapsed {
                collapsedView
            } else {
                expandedView
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.78)) {
                isCollapsed.toggle()
            }
        }
    }

    // MARK: - Expanded

    private var expandedView: some View {
        VStack(spacing: 12) {
            ForEach(Array(manager.currentMapping.buttons.enumerated()), id: \.offset) { index, action in
                Text(action.label)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(hoveredIndex == index ? 1.0 : 0.9))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .frame(height: 34)
                .background(
                    Capsule()
                        .fill(.thickMaterial)
                        .environment(\.colorScheme, .dark)
                )
                .overlay(
                    Capsule()
                        .strokeBorder(.white.opacity(0.08), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.2), radius: hoveredIndex == index ? 8 : 4, y: 2)
                .scaleEffect(hoveredIndex == index ? 1.03 : 1.0)
                .padding(.horizontal, 4)
                .onHover { over in
                    withAnimation(.easeOut(duration: 0.15)) {
                        hoveredIndex = over ? index : nil
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .frame(width: 185)
        .fixedSize(horizontal: true, vertical: true)
        .animation(.easeInOut(duration: 0.25), value: manager.currentAppName)
        .transition(.asymmetric(
            insertion: .scale(scale: 0.9, anchor: .leading).combined(with: .opacity),
            removal: .scale(scale: 0.9, anchor: .leading).combined(with: .opacity)
        ))
    }

    // MARK: - Collapsed (dots)

    private var collapsedView: some View {
        VStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { _ in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.45),
                                Color.white.opacity(0.15)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.white.opacity(0.6),
                                        Color.clear
                                    ],
                                    center: .topLeading,
                                    startRadius: 0,
                                    endRadius: 10
                                )
                            )
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(.white.opacity(0.35), lineWidth: 0.5)
                    )
                    .shadow(color: .white.opacity(0.15), radius: 3, y: 0)
                    .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                    .frame(width: 34, height: 34)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 4)
        .transition(.asymmetric(
            insertion: .scale(scale: 0.5, anchor: .leading).combined(with: .opacity),
            removal: .scale(scale: 0.5, anchor: .leading).combined(with: .opacity)
        ))
    }
}
