import SwiftUI

struct ContentView: View {

    @StateObject private var appState = AppState()

    @State private var navigationSelection:
        MainNavigationBar.Destination = .home

    @State private var focusHomeRequest = false

    var body: some View {

        NavigationStack {

            VStack(
                alignment: .center,
                spacing: 0
            ) {

                // MARK: - Barra superior

                HStack {

                    Spacer()

                    MainNavigationBar(
                        selection: $navigationSelection,
                        focusHomeRequest: $focusHomeRequest,
                        onDestinationFocused: {
                            destination in

                            navigationSelection = destination
                        }
                    )

                    Spacer()
                }
                .focusSection()

                // MARK: - Contenido principal

                contentView
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity
                    )
            }
        }
        .environmentObject(appState)
        .onAppear {
            navigationSelection = .home
        }
    }

    // MARK: - Contenido

    @ViewBuilder
    private var contentView: some View {

        switch navigationSelection {

        case .home:

            HomeView()

        case .nowPlaying:

            Text("En reproducción")
                .font(.largeTitle)

        case .search:

            Text("Buscar")
                .font(.largeTitle)

        case .queue:

            Text("Cola de reproducción")
                .font(.largeTitle)

        case .player:

            PlayerPickerView()
        }
    }
}

#Preview {
    ContentView()
}
