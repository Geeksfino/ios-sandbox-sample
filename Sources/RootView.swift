import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            PolicyDashboardView()
                .tabItem { Label("Policies", systemImage: "gearshape") }

            MainMenuView()
                .tabItem { Label("Demos", systemImage: "list.bullet") }
        }
    }
}
