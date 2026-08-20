# Badge comparison harness

Renders the **pre-refactor** badge implementation next to the current
data-driven engine and pixel-diffs every plate.

`Old_LineSymbolBadge.swift` / `Old_StationNumberBadge.swift` are a frozen
snapshot of the hardcoded views as they stood before the refactor (the only
edit is swapping their `UIColor` probe for an `NSColor` one, since
`isGreenDominant` returns `false` off-iOS and would break the dispatch under
test). They are deliberately *not* regenerated from the app sources any more —
those are now thin wrappers over the engine, so there would be nothing to
compare against.

    swiftc -O -o /tmp/badgecompare \
      Shim.swift Old_LineSymbolBadge.swift Old_StationNumberBadge.swift \
      BadgeStyleSpec.swift SpecBadgeViews.swift Zoom.swift main.swift
    /tmp/badgecompare [outdir]

`ZOOM=jr,tobu` renders one style large, old vs new, with a diff bounding box.
`SELFTEST=1` runs the SwiftUI-primitive equivalence checks.

`BadgeStyleSpec.swift` / `SpecBadgeViews.swift` here are copies of the engine
that shipped into `Backbone/Badges/`; keep them in sync when the engine changes.
