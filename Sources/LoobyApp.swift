import SwiftUI

@main
struct LoobyApp: App {
    @StateObject private var viewModel = LoobyViewModel()

    var body: some Scene {
        WindowGroup {
            LoobyMainTabView()
                .environmentObject(viewModel)
                .task {
                    await viewModel.bootstrap()
                }
        }
    }
}
