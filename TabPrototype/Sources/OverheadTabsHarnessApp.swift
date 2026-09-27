import SwiftUI

@main
struct OverheadTabsHarnessApp: App {
    @StateObject private var tabs = PrototypeTabStore()

    var body: some Scene {
        WindowGroup {
            TabShellView(store: tabs)
        }
    }
}

