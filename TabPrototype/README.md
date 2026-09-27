# Overhead Tabs Harness

An isolated SwiftUI app for prototyping Safari-style journey workspaces. It has
no dependency on the production app, train data, location services, widgets, or
Live Activities.

The harness includes:

- independent planner, search, and journey tab states;
- a native bottom toolbar with a next-stop badge, maximized address-style
  transit search, and tab-overview button;
- station, line, and operator matching with route, timetable, line, and
  operator actions;
- horizontal swiping on the address bar to move between tabs;
- a Safari-style overview for adding, selecting, duplicating, closing, and
  reordering tabs; and
- JSON persistence in Application Support.

Generate the project and build it with:

```sh
cd TabPrototype
xcodegen generate
xcodebuild -project OverheadTabsHarness.xcodeproj \
  -scheme OverheadTabsHarness \
  -destination 'platform=iOS Simulator,name=iPhone (iOS 27)' build
```

Use the Reset Prototype button in the in-app menu to restore the three sample
tabs.
