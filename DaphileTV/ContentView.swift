import SwiftUI

struct ContentView: View {

    @StateObject private var appState =
        AppState()

    @State private var showPlayerPicker =
        false

    var body: some View {

        NavigationStack {

            HomeView(
                onPlayerRequested: {

                    showPlayerPicker = true
                }
            )
            .environmentObject(appState)

            .navigationDestination(
                isPresented:
                    $showPlayerPicker
            ) {

                PlayerPickerView()
                    .environmentObject(
                        appState
                    )
            }
        }
    }
}

#Preview {

    ContentView()
}
