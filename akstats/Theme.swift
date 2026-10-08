import SwiftUI

/// A dark, restrained palette: deep-slate surfaces with one emerald accent, plus
/// semantic colors reserved for content that needs to stand out.
enum Theme {
    // Core palette
    static let background = Color(hex: 0x0B0F19)      // Deep Slate
    static let surface = Color(hex: 0x1E293B)         // Dark Card
    static let textPrimary = Color(hex: 0xF8FAFC)     // Off-White
    static let textSecondary = Color(hex: 0x94A3B8)   // Cool Gray
    static let accent = Color(hex: 0x10B981)          // Emerald / Mint
    /// Text and icons drawn on top of the accent color (white on emerald is too low-contrast).
    static let onAccent = Color(hex: 0x0B0F19)
    /// A slightly raised line color for borders and tracks.
    static let hairline = Color(hex: 0x334155)

    // Semantic colors
    static let caution = Color(hex: 0xF59E0B)         // amber
    static let correct = Color(hex: 0x34D399)         // light emerald
    static let incorrect = Color(hex: 0xF87171)       // soft red
    /// Marks exercises and lessons that use the practice simulations.
    static let simulation = Color(hex: 0x22D3EE)      // cyan

    static let cornerRadius: CGFloat = 14
    static let animation = Animation.smooth(duration: 0.3)

    static func color(for level: Level) -> Color {
        switch level {
        case .beginner: Color(hex: 0x38BDF8)      // sky
        case .intermediate: Color(hex: 0xA78BFA)  // violet
        case .advanced: Color(hex: 0xFB923C)      // orange
        }
    }

    static func color(for discipline: Discipline) -> Color {
        switch discipline {
        case .psychology: .pink
        case .linguistics: .teal
        case .sociology: .orange
        case .general: .gray
        }
    }
}

extension CodeLanguage {
    /// Each language has its own color so it's obvious which one a code block shows.
    /// Python yellow and R blue echo each language's logo; text drawn on them uses `Theme.onAccent`.
    var color: Color {
        switch self {
        case .python: Color(hex: 0xFACC15)   // yellow
        case .r: Color(hex: 0x60A5FA)        // blue
        case .mplus: Color(hex: 0xC084FC)    // violet
        }
    }
}

extension Color {
    /// Creates a color from a 24-bit hex value such as 0x10B981.
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}

/// Renders inline Markdown (bold, italics, code) while preserving line breaks.
func markdown(_ string: String) -> Text {
    let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
    if let attributed = try? AttributedString(markdown: string, options: options) {
        return Text(attributed)
    }
    return Text(string)
}

// MARK: - Hover highlight

/// Softly tints the background and lifts the content when a pointer hovers over it.
struct HoverHighlight: ViewModifier {
    var tint: Color = .primary
    var cornerRadius: CGFloat = Theme.cornerRadius
    var lift: Bool = false

    @State private var isHovering = false

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(tint.opacity(isHovering ? 0.08 : 0))
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(tint.opacity(isHovering ? 0.25 : 0), lineWidth: 1)
            }
            .scaleEffect(lift && isHovering ? 1.015 : 1)
            .animation(.smooth(duration: 0.2), value: isHovering)
            .onHover { isHovering = $0 }
    }
}

extension View {
    func hoverHighlight(tint: Color = .primary, cornerRadius: CGFloat = Theme.cornerRadius, lift: Bool = false) -> some View {
        modifier(HoverHighlight(tint: tint, cornerRadius: cornerRadius, lift: lift))
    }

    /// The standard quiet surface used for cards.
    func card(padding: CGFloat = 18) -> some View {
        self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface, in: .rect(cornerRadius: Theme.cornerRadius, style: .continuous))
    }
}

/// A plain button style that dims slightly on press, for use with `hoverHighlight`.
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(.rect)
            .opacity(configuration.isPressed ? 0.7 : 1)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.smooth(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Small shared components

/// A capsule label such as "Beginner" or "Psychology".
struct Tag: View {
    let text: String
    var symbol: String?
    var color: Color

    var body: some View {
        HStack(spacing: 4) {
            if let symbol {
                Image(systemName: symbol)
            }
            Text(text)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(color.opacity(0.12), in: .capsule)
    }
}

/// A slim, animated progress bar.
struct ProgressBar: View {
    let value: Double
    var tint: Color = Theme.accent

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.hairline)
                Capsule()
                    .fill(tint)
                    .frame(width: max(0, min(1, value)) * proxy.size.width)
            }
        }
        .frame(height: 6)
        .animation(.smooth(duration: 0.5), value: value)
        .accessibilityElement()
        .accessibilityLabel("Progress")
        .accessibilityValue(Text(value, format: .percent.precision(.fractionLength(0))))
    }
}
