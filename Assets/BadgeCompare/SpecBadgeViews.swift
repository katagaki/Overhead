import SwiftUI

// MARK: - Layer stack shared by both faces

@ViewBuilder
private func layerStack(_ layers: [BadgeLayer]?, side: CGFloat,
                        line: Color, palette: [String: Color], opacity: Double) -> some View {
    if let layers, !layers.isEmpty {
        ZStack {
            ForEach(Array(layers.enumerated()), id: \.offset) { _, layer in
                layerView(layer, side: side, line: line, palette: palette, opacity: opacity)
            }
        }
    }
}

private func dim(_ c: Color, _ opacity: Double) -> Color {
    opacity >= 1 ? c : c.opacity(opacity)
}

@ViewBuilder
private func layerView(_ layer: BadgeLayer, side: CGFloat,
                       line: Color, palette: [String: Color], opacity: Double) -> some View {
    let inset = layer.inset ?? (layer.insetRatio.map { $0 * side } ?? 0)
    let lineWidth = layer.lineWidth ?? (layer.lineWidthRatio.map { $0 * side } ?? 0)
    let radius = layer.radius ?? (layer.radiusRatio.map { $0 * side } ?? 0)
    let fill = ColorToken.resolve(layer.fill, line: line, palette: palette).map { dim($0, opacity) }
    let stroke = ColorToken.resolve(layer.stroke, line: line, palette: palette).map { dim($0, opacity) }

    // SwiftUI draws its built-in shapes on a different path than an equivalent
    // custom Shape, so each primitive is emitted directly rather than wrapped.
    Group {
        switch layer.shape {
        case "circle":
            if let stroke { Circle().strokeBorder(stroke, lineWidth: lineWidth) }
            else if let fill { Circle().fill(fill) }
        case "rect":
            if let stroke { Rectangle().strokeBorder(stroke, lineWidth: lineWidth) }
            else if let fill { Rectangle().fill(fill) }
        case "hexagon":
            if let fill { FlatTopHexagon().fill(fill) }
        case "sakura":
            if let fill { SakuraBlossom().fill(fill) }
        case "serifI":
            if let fill { SerifI().fill(fill) }
        case "seasideWave":
            if let fill {
                if layer.clipCircle == true { SeasideWave().fill(fill).clipShape(Circle()) }
                else { SeasideWave().fill(fill) }
            }
        case "minatomiraiWave":
            if let fill {
                MinatomiraiWave().fill(fill)
                    .modifier(LayerFrame(heightRatio: layer.heightRatio, side: side,
                                         offsetYRatio: layer.offsetYRatio))
            }
        default:
            // The bare initializer's default corner style is not .circular on
            // current SDKs, so only pass a style when the spec asks for one.
            if let stroke {
                if layer.continuous == true {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .strokeBorder(stroke, lineWidth: lineWidth)
                } else {
                    RoundedRectangle(cornerRadius: radius).strokeBorder(stroke, lineWidth: lineWidth)
                }
            } else if let fill {
                if layer.continuous == true {
                    RoundedRectangle(cornerRadius: radius, style: .continuous).fill(fill)
                } else {
                    RoundedRectangle(cornerRadius: radius).fill(fill)
                }
            }
        }
    }
    .padding(inset)
    .modifier(TopAlign(enabled: layer.alignTop == true))
}

private struct TopAlign: ViewModifier {
    let enabled: Bool
    func body(content: Content) -> some View {
        if enabled { content.frame(maxHeight: .infinity, alignment: .top) } else { content }
    }
}

private struct LayerFrame: ViewModifier {
    let heightRatio: CGFloat?
    let side: CGFloat
    let offsetYRatio: CGFloat?

    func body(content: Content) -> some View {
        if heightRatio == nil && offsetYRatio == nil {
            content
        } else {
            content
                .frame(height: heightRatio.map { $0 * side })
                .offset(y: (offsetYRatio ?? 0) * side)
        }
    }
}

@ViewBuilder
private func ruleView(_ rule: RuleSpec, side: CGFloat, line: Color,
                      palette: [String: Color], opacity: Double) -> some View {
    let w = rule.width ?? (rule.widthRatio.map { $0 * side } ?? side)
    let h = rule.height ?? (rule.heightRatio.map { $0 * side } ?? 1)
    Rectangle()
        .fill(dim(ColorToken.resolve(rule.color, line: line, palette: palette) ?? .clear, opacity))
        .frame(width: w, height: max(1, h))
}

// MARK: - Line symbol badge, drawn from a style spec

struct SpecLineSymbolBadge: View {
    let symbol: String
    let color: Color
    var dimension: CGFloat = 32
    let spec: BadgeStyleSpec
    /// Raw per-line colour overrides from Badge.json.
    var overrides: [String: String]? = nil

    private var f: CGFloat { dimension / 32 }
    private var palette: [String: Color] {
        ColorToken.palette(spec, overrides: overrides, line: color)
    }

    var body: some View {
        let face = spec.line
        if face.renderer == "seibuTrainLogo" {
            SeibuTrainPlate(symbol: symbol, color: color, dimension: dimension)
        } else {
            content(face)
                .frame(width: dimension, height: dimension)
                .background {
                    layerStack(face.layers, side: dimension, line: color,
                               palette: palette, opacity: 1)
                }
                .overlay {
                    layerStack(face.overlays, side: dimension, line: color,
                               palette: palette, opacity: 1)
                }
        }
    }

    @ViewBuilder
    private func content(_ face: LineFace) -> some View {
        if let glyph = face.glyphShape {
            glyphView(glyph, ColorToken.resolve(face.glyphFill, line: color, palette: palette) ?? .black)
                .frame(width: (face.glyphWidth ?? 0) * f, height: (face.glyphHeight ?? 0) * f)
        } else if let rule = face.rule {
            VStack(spacing: (face.stackSpacing ?? 0) * f) {
                symbolText(face)
                ruleView(rule, side: dimension, line: color, palette: palette, opacity: 1)
            }
        } else {
            symbolText(face)
        }
    }

    @ViewBuilder
    private func symbolText(_ face: LineFace) -> some View {
        let multi = symbol.count > 1
        let size = (face.glyphSize?[symbol]
                    ?? (multi ? (face.sizeMulti ?? face.size ?? 15) : (face.size ?? 15))) * f
        let nudgeBase = multi ? (face.nudgeBaseMulti ?? face.nudgeBase ?? 0) : (face.nudgeBase ?? 0)
        let nudge = nudgeBase * f * 0.085

        Text(face.literal ?? symbol)
            .font(font(face, size: size))
            .kerning((face.kerning ?? false) && multi ? -0.5 * f : 0)
            .lineLimit(1)
            .minimumScaleFactor(face.minimumScaleFactor ?? 0.5)
            .foregroundColor(ColorToken.resolve(face.color, line: color, palette: palette) ?? .black)
            .offset(x: (face.glyphOffsetX?[symbol] ?? 0) * f,
                    y: nudge + (face.offsetY ?? 0) * f + (face.glyphOffsetY?[symbol] ?? 0) * f)
            .padding(.horizontal, (face.insetH ?? 0) * f)
    }

    private func font(_ face: LineFace, size: CGFloat) -> Font {
        if let family = face.family {
            return .custom(family, fixedSize: size)
        }
        var f = Font.system(size: size, weight: swiftUIWeight(face.weight) ?? .regular)
        switch face.width {
        case "condensed": f = f.width(.condensed)
        case "expanded":  f = f.width(.expanded)
        case "standard":  f = f.width(.standard)
        default: break
        }
        return f
    }
}

// MARK: - Station number badge, drawn from a style spec

struct SpecStationNumberBadge: View {
    let code: String
    let color: Color
    var opacity: Double = 1.0
    var side: CGFloat = 28
    let spec: BadgeStyleSpec
    /// Raw per-line colour overrides from Badge.json.
    var overrides: [String: String]? = nil

    private var palette: [String: Color] {
        ColorToken.palette(spec, overrides: overrides, line: color)
    }

    private var parsed: (prefix: String, number: String) {
        let letters = code.prefix(while: \.isLetter)
        let digits = code.drop(while: \.isLetter)
        return (String(letters), String(digits))
    }

    var body: some View {
        let face = spec.station ?? StationFace()
        let (prefix, number) = parsed

        stack(face, prefix: prefix, number: number)
            .lineLimit(1)
            .minimumScaleFactor(face.minimumScaleFactor ?? 0.6)
            .foregroundColor(
                dim(ColorToken.resolve(face.color, line: color, palette: palette) ?? .black, opacity))
            .frame(width: side, height: side)
            .background {
                layerStack(face.layers, side: side, line: color,
                           palette: palette, opacity: opacity)
            }
            .modifier(ClipModifier(clip: face.clip, side: side))
            .overlay {
                layerStack(face.overlays, side: side, line: color,
                           palette: palette, opacity: opacity)
            }
    }

    @ViewBuilder
    private func stack(_ face: StationFace, prefix: String, number: String) -> some View {
        if prefix.isEmpty, let solo = face.solo {
            row(solo, prefix: prefix, number: number, face: face)
        } else {
            let spacing = face.spacing ?? (face.spacingRatio.map { $0 * side } ?? 0)
            VStack(spacing: spacing) {
                ForEach(Array((face.rows ?? []).enumerated()), id: \.offset) { _, r in
                    row(r, prefix: prefix, number: number, face: face)
                }
            }
        }
    }

    @ViewBuilder
    private func row(_ r: StationRow, prefix: String, number: String, face: StationFace) -> some View {
        if r.kind == "rule", let rule = r.rule {
            ruleView(rule, side: side, line: color, palette: palette, opacity: opacity)
        } else if let glyph = r.glyphShape {
            glyphView(glyph, dim(ColorToken.resolve(r.glyphFill, line: color, palette: palette) ?? .black, opacity))
                .frame(width: (r.glyphWidthRatio ?? 0) * side,
                       height: (r.glyphHeightRatio ?? 0) * side)
                .frame(height: (r.heightRatio ?? 0) * side)
                .offset(y: (r.offsetYRatio ?? 0) * side)
        } else {
            let text = r.kind == "prefix"
                ? prefix
                : (r.stripLeadingZeros == true ? String(number.drop(while: { $0 == "0" })) : number)

            Text(text)
                .font(font(r, prefix: prefix, face: face))
                .modifier(BoldIf(bold: r.bold ?? false))
                .kerning((r.kerningRatio ?? 0) * side)
                .modifier(RowForeground(
                    color: ColorToken.resolve(r.color, line: color, palette: palette)
                        .map { dim($0, opacity) }))
                .offset(y: (r.offsetYRatio ?? 0) * side + (r.offsetY ?? 0))
                .modifier(RowFrame(row: r, side: side))
                .background(ColorToken.resolve(r.background, line: color, palette: palette)
                    .map { dim($0, opacity) })
        }
    }

    private func font(_ r: StationRow, prefix: String = "",
                      face: StationFace? = nil) -> Font {
        let override = r.kind == "prefix" ? face?.prefixSizes?[prefix] : nil
        let size = (override ?? r.sizeRatio ?? 0.5) * side
        if let family = r.family {
            return .custom(family, size: size)
        }
        var f = Font.system(size: size, weight: swiftUIWeight(r.weight) ?? .regular)
        switch r.width {
        case "condensed": f = f.width(.condensed)
        case "expanded":  f = f.width(.expanded)
        case "standard":  f = f.width(.standard)
        default: break
        }
        return f
    }
}

private struct RowForeground: ViewModifier {
    let color: Color?
    func body(content: Content) -> some View {
        if let color { content.foregroundColor(color) } else { content }
    }
}

private struct BoldIf: ViewModifier {
    let bold: Bool
    func body(content: Content) -> some View {
        if bold { content.fontWeight(.bold) } else { content }
    }
}

private struct RowFrame: ViewModifier {
    let row: StationRow
    let side: CGFloat

    func body(content: Content) -> some View {
        content
            .modifier(WidthFrame(row: row, side: side))
            .modifier(HeightFrame(row: row, side: side))
    }
}

private struct WidthFrame: ViewModifier {
    let row: StationRow
    let side: CGFloat
    func body(content: Content) -> some View {
        if row.fullWidth == true {
            content.frame(maxWidth: .infinity)
        } else if let w = row.widthRatio {
            content.frame(maxWidth: w * side)
        } else {
            content
        }
    }
}

private struct HeightFrame: ViewModifier {
    let row: StationRow
    let side: CGFloat
    func body(content: Content) -> some View {
        if row.expandHeight == true {
            content.frame(maxHeight: .infinity)
        } else if let mh = row.maxHeightRatio {
            content.frame(maxHeight: mh * side)
        } else if let h = row.heightRatio {
            content.frame(height: h * side)
        } else {
            content
        }
    }
}

private struct ClipShapeModifier: ViewModifier {
    let clip: BadgeLayer
    let side: CGFloat
    func body(content: Content) -> some View {
        let radius = clip.radius ?? (clip.radiusRatio.map { $0 * side } ?? 0)
        if clip.shape == "circle" {
            content.clipShape(Circle())
        } else if clip.continuous == true {
            content.clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        } else {
            content.clipShape(RoundedRectangle(cornerRadius: radius))
        }
    }
}

private struct ClipModifier: ViewModifier {
    let clip: BadgeLayer?
    let side: CGFloat
    func body(content: Content) -> some View {
        if let clip {
            content.modifier(ClipShapeModifier(clip: clip, side: side))
        } else {
            content
        }
    }


}

// MARK: - Bespoke plate: 西武's train-front logo

struct SeibuTrainPlate: View {
    let symbol: String
    let color: Color
    let dimension: CGFloat
    private var f: CGFloat { dimension / 32 }

    var body: some View {
        ZStack {
            SeibuTrainLegs().fill(color)

            UnevenRoundedRectangle(
                topLeadingRadius: 0.20 * dimension, bottomLeadingRadius: 0.07 * dimension,
                bottomTrailingRadius: 0.07 * dimension, topTrailingRadius: 0.20 * dimension,
                style: .continuous
            )
            .fill(color)
            .frame(width: 0.82 * dimension, height: 0.78 * dimension)
            .offset(y: -0.11 * dimension)

            UnevenRoundedRectangle(
                topLeadingRadius: 0.10 * dimension, bottomLeadingRadius: 0.30 * dimension,
                bottomTrailingRadius: 0.30 * dimension, topTrailingRadius: 0.10 * dimension,
                style: .continuous
            )
            .fill(Color.white)
            .frame(width: 0.60 * dimension, height: 0.48 * dimension)
            .offset(y: -0.16 * dimension)

            Text(symbol)
                .font(.custom("Hind-Bold", fixedSize: 0.40 * dimension))
                .kerning(symbol.count > 1 ? -0.5 * f : 0)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .foregroundColor(.black)
                .frame(width: 0.56 * dimension)
                .offset(y: -0.20 * dimension + 0.30 * dimension * 0.085)

            ForEach([-1.0, 1.0], id: \.self) { side in
                Circle()
                    .fill(Color.white)
                    .frame(width: 0.11 * dimension, height: 0.11 * dimension)
                    .offset(x: side * 0.20 * dimension, y: 0.14 * dimension)
            }
        }
        .frame(width: dimension, height: dimension)
    }
}


@ViewBuilder
func glyphView(_ name: String, _ color: Color) -> some View {
    switch name {
    case "serifI":          SerifI().fill(color)
    case "sakura":          SakuraBlossom().fill(color)
    case "hexagon":         FlatTopHexagon().fill(color)
    case "seasideWave":     SeasideWave().fill(color)
    case "minatomiraiWave": MinatomiraiWave().fill(color)
    default:                Circle().fill(color)
    }
}
