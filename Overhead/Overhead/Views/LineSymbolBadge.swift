import SwiftUI

// MARK: - Line Symbol Badge
/// Renders line symbol badges matching Tokyo rail signage:
/// - JR East: Rounded rectangle (e.g. "JY", "JC")
/// - Tokyo Metro: Circle (e.g. "G", "C", "M")
/// - Toei: Circle (e.g. "A", "E")
/// Shows only the line prefix letter(s), no station number.

struct LineSymbolBadge: View {
    let symbol: String
    let color: Color

    private var isJR: Bool {
        symbol.hasPrefix("J")
    }

    var body: some View {
        if isJR {
            jrBadge
        } else {
            metroBadge
        }
    }

    // MARK: - JR Style: Rounded Rectangle

    private var jrBadge: some View {
        Text(symbol)
            .font(.custom("HelveticaNeue-Bold", size: 14))
            .foregroundColor(.black)
            .frame(width: 32, height: 32)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .strokeBorder(color, lineWidth: 2.5)
            )
    }

    // MARK: - Metro / Toei Style: Circle

    private var metroBadge: some View {
        Text(symbol)
            .font(.system(size: 16, weight: .heavy, design: .default))
            .foregroundColor(.black)
            .frame(width: 32, height: 32)
            .background(Color.white)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .strokeBorder(color, lineWidth: 2.5)
            )
    }
}
