import SwiftUI

extension Color {
    /// The raised "to-do" key — a matte graphite. Same in light or dark, like real hardware.
    static let keyFace = Color(red: 0.133, green: 0.141, blue: 0.165)
    /// The 3D side wall / bottom lip under the raised key.
    static let keyEdge = Color(red: 0.055, green: 0.060, blue: 0.075)
}

/// A big physical push-button with real height. Raised + graphite when it's a
/// to-do (invites the tap); pushes flush to its base while pressed; sits flat,
/// light and muted once done (a crossed-off checklist item).
///
/// Geometry (base + face lift) lives here; the row content is supplied as the
/// button's label via `HardwareFace`.
struct PushButtonStyle: ButtonStyle {
    /// Whether this represents a *done* item (rests pushed-in) vs a to-do (rests raised).
    let isOn: Bool
    var depth: CGFloat = 7
    var height: CGFloat = 66

    @Environment(\.colorScheme) private var scheme

    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: 16, style: .continuous) }

    func makeBody(configuration: Configuration) -> some View {
        // Pushed-in when done OR while the finger is down; raised otherwise.
        let down = isOn || configuration.isPressed
        let faceOffset: CGFloat = down ? depth : 0

        return ZStack(alignment: .top) {
            // Base / side wall, sitting one "depth" below the raised face.
            shape
                .fill(edgeFill)
                .frame(height: height)
                .offset(y: depth)

            // The face.
            configuration.label
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .background(shape.fill(faceFill))
                .overlay(topSheen)
                .overlay(shape.strokeBorder(faceBorder, lineWidth: 1))
                // note: face content colors (text/icons) come from HardwareFace,
                // which flips to dark ink when the key is white (dark mode).
                .clipShape(shape)
                .offset(y: faceOffset)
        }
        .frame(height: height + depth, alignment: .top)
        .shadow(color: .black.opacity(scheme == .dark ? 0.45 : 0.16), radius: 5, y: 3)
        .animation(.spring(response: 0.16, dampingFraction: 0.62), value: faceOffset)
    }

    // Colors invert with the scheme for clean black/white parity: the raised
    // "to-do" key is always the maximum-contrast surface, the "done" state always
    // recedes toward the background.
    //  Light: black graphite key on white; done = light grey (recedes to white).
    //  Dark:  near-white key on black;     done = near-black flat (recedes to black).
    private var faceFill: Color {
        switch (isOn, scheme) {
        case (true, .dark):  return Color(white: 0.11)                 // done — receded (dark)
        case (true, _):      return Color(.secondarySystemBackground)  // done — receded (light)
        case (false, .dark): return Color(white: 0.97)                 // to-do — white key on black
        case (false, _):     return Color.keyFace                      // to-do — graphite key on white
        }
    }

    private var edgeFill: Color {
        switch (isOn, scheme) {
        case (true, .dark):  return Color(white: 0.11)
        case (true, _):      return Color(.secondarySystemBackground)
        case (false, .dark): return Color(white: 0.68)                 // grey underside of the white key
        case (false, _):     return Color.keyEdge
        }
    }

    private var faceBorder: Color {
        if isOn { return Color.primary.opacity(0.10) }
        return scheme == .dark ? Color.black.opacity(0.12) : Color.white.opacity(0.08)
    }

    // A faint molded highlight along the top of the raised graphite key — subtle,
    // not a glow. Pointless on the white key, so only the dark (light-mode) key.
    private var topSheen: some View {
        let show = !isOn && scheme != .dark
        return shape
            .fill(
                LinearGradient(
                    colors: [Color.white.opacity(show ? 0.10 : 0), .clear],
                    startPoint: .top,
                    endPoint: .center
                )
            )
            .allowsHitTesting(false)
    }
}

/// The content row that sits on the button face: title, plus a check when done,
/// an optional dot (groups with a done child) and chevron (groups).
struct HardwareFace: View {
    let title: String
    let isOn: Bool
    var showChevron: Bool = false
    /// Rotate the chevron to point down (group expanded).
    var chevronDown: Bool = false
    var indicatorLit: Bool = false

    @Environment(\.colorScheme) private var scheme

    /// Ink that sits on the raised to-do key — dark on the white (dark-mode) key,
    /// white on the graphite (light-mode) key.
    private var onKey: Color { scheme == .dark ? .black : .white }

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(isOn ? Color.secondary : onKey)
                .tracking(0.2)
            Spacer(minLength: 8)
            if indicatorLit && !isOn {
                Circle()
                    .fill(onKey)
                    .frame(width: 8, height: 8)
            }
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isOn ? AnyShapeStyle(.tertiary) : AnyShapeStyle(onKey.opacity(0.6)))
                    .rotationEffect(.degrees(chevronDown ? 90 : 0))
            }
        }
        .padding(.horizontal, 22)
    }
}
