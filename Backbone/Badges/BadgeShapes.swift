import SwiftUI

// Vector art no layer description can express. Style files reference these by
// name, e.g. {"shape": "sakura"}.

// MARK: - Flat-Top Hexagon

/// Saitama New Shuttle's plate: points at the left and right edges, flat top and bottom.
public struct FlatTopHexagon: Shape {
    public init() {}
    public func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        let inset = h * 0.08          // flat edges sit just inside the top and bottom
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX + w * 0.28, y: rect.minY + inset))
        path.addLine(to: CGPoint(x: rect.maxX - w * 0.28, y: rect.minY + inset))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX - w * 0.28, y: rect.maxY - inset))
        path.addLine(to: CGPoint(x: rect.minX + w * 0.28, y: rect.maxY - inset))
        path.closeSubpath()
        return path
    }
}

/// 都電荒川線's badge is a five-petal cherry blossom.
/// 三田線's "I" has top and bottom bars; system faces draw a bare stem.
public struct SerifI: Shape {
    public init() {}
    public func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        // One stroke weight for the stem and both bars.
        let t = w * 0.34
        let barW = w * 0.74
        let barX = rect.minX + (w - barW) / 2
        var p = Path()
        p.addRect(CGRect(x: barX, y: rect.minY, width: barW, height: t))
        p.addRect(CGRect(x: rect.midX - t / 2, y: rect.minY, width: t, height: h))
        p.addRect(CGRect(x: barX, y: rect.maxY - t, width: barW, height: t))
        return p
    }
}

public struct SakuraBlossom: Shape {
    public init() {}
    public func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        var path = Path()
        // Non-zero winding unions the core and the five lobes.
        path.addEllipse(in: CGRect(x: c.x - r * 0.64, y: c.y - r * 0.64,
                                   width: r * 1.28, height: r * 1.28))
        for k in 0..<5 {
            let a = -CGFloat.pi / 2 + CGFloat(k) * 2 * .pi / 5
            let pc = CGPoint(x: c.x + cos(a) * r * 0.60, y: c.y + sin(a) * r * 0.60)
            path.addEllipse(in: CGRect(x: pc.x - r * 0.40, y: pc.y - r * 0.40,
                                       width: r * 0.80, height: r * 0.80))
        }
        return path
    }
}

/// The swoosh across みなとみらい線's plate.
public struct MinatomiraiWave: Shape {
    public init() {}
    public func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        var path = Path()
        // One sine period, tapered towards both ends.
        func wave(_ side: CGFloat) -> [CGPoint] {
            let inset: CGFloat = 0.07
            return stride(from: 0.0, through: 1.0, by: 0.025).map { t in
                let taper = 0.22 + 0.78 * sin(.pi * t)
                return CGPoint(x: rect.minX + w * (inset + t * (1 - 2 * inset)),
                               y: rect.minY + h * (0.5 + side * 0.11 * taper
                                                   + 0.21 * sin(2 * .pi * t)))
            }
        }
        let top = wave(-1), bottom = wave(1).reversed()
        path.move(to: top[0])
        top.dropFirst().forEach { path.addLine(to: $0) }
        bottom.forEach { path.addLine(to: $0) }
        path.closeSubpath()
        return path
    }
}

// MARK: - Seaside Wave

/// Seaside Line's disc, broken by the wave that names the line.
public struct SeasideWave: Shape {
    public init() {}
    public func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        let crest = rect.minY + h * 0.70
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: crest + h * 0.06))
        path.addQuadCurve(to: CGPoint(x: rect.minX + w * 0.5, y: crest + h * 0.05),
                          control: CGPoint(x: rect.minX + w * 0.75, y: crest - h * 0.06))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: crest + h * 0.06),
                          control: CGPoint(x: rect.minX + w * 0.25, y: crest + h * 0.16))
        path.closeSubpath()
        return path
    }
}

// MARK: - Seibu Train Legs

/// The two splayed legs (rails) under the Seibu train-front logo. Drawn in
/// unit space; the top ends tuck behind the train body.
public struct SeibuTrainLegs: Shape {
    public init() {}
    public func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        p.move(to: CGPoint(x: 0.40 * w, y: 0.60 * h))
        p.addLine(to: CGPoint(x: 0.53 * w, y: 0.60 * h))
        p.addLine(to: CGPoint(x: 0.27 * w, y: 1.00 * h))
        p.addLine(to: CGPoint(x: 0.10 * w, y: 1.00 * h))
        p.closeSubpath()
        p.move(to: CGPoint(x: 0.60 * w, y: 0.60 * h))
        p.addLine(to: CGPoint(x: 0.47 * w, y: 0.60 * h))
        p.addLine(to: CGPoint(x: 0.73 * w, y: 1.00 * h))
        p.addLine(to: CGPoint(x: 0.90 * w, y: 1.00 * h))
        p.closeSubpath()
        return p
    }
}
