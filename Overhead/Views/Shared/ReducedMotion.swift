import SwiftUI
import UIKit

private struct MotionReducedKey: EnvironmentKey {
    static var defaultValue: Bool { ReducedMotion.isForced || UIAccessibility.isReduceMotionEnabled }
}

extension EnvironmentValues {
    /// Reduce Motion, plus a DEBUG `-debugReduceMotion YES` override; also reaches offscreen renders.
    var motionReduced: Bool {
        get { self[MotionReducedKey.self] }
        set { self[MotionReducedKey.self] = newValue }
    }
}

enum ReducedMotion {
    static var isForced: Bool {
#if DEBUG
        UserDefaults.standard.bool(forKey: "debugReduceMotion")
#else
        false
#endif
    }
}

private struct ReducedMotionRoot: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var system

    func body(content: Content) -> some View {
        content.environment(\.motionReduced, system || ReducedMotion.isForced)
    }
}

extension View {
    func reducedMotionRoot() -> some View {
        modifier(ReducedMotionRoot())
    }
}
