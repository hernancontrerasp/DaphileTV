import SwiftUI

struct HomeView: View {

@EnvironmentObject private var appState: AppState

@FocusState private var focusedItem: FocusArea?

@State private var focusedExploreItem: String?

@State private var focusHomeRequest = false

@State private var navigationSelection:
    MainNavigationBar.Destination = .home

let onPlayerRequested: () -> Void

enum FocusArea: Hashable {

    case album(Int)
    case explore(String)
}

var body: some View {

    ScrollView(
        .vertical,
        showsIndicators: false
    ) {

        VStack(
            alignment: .leading,
            spacing: 32
        ) {

            // MARK: - Barra superior

            HStack {

                Spacer()

                MainNavigationBar(
                    selection:
                        $navigationSelection,
                    focusHomeRequest:
                        $focusHomeRequest,
                    onDestinationFocused: {
                        destination in

                        if destination == .player {

                            onPlayerRequested()
                        }
                    }
                )

                Spacer()
            }
            .focusSection()

            // MARK: - Contenido

            VStack(
                alignment: .leading,
                spacing: 32
            ) {

                // MARK: - Música Nueva

                musicNewSection
                    .padding(.top, 20)

                // MARK: - Explorar

                exploreSection
            }
            .onExitCommand {

                focusHomeRequest = true
            }
        }
        .padding(.horizontal, 35)
        .padding(.top, 0)
        .padding(.bottom, 30)
    }
    .focusSection()
    .task {

        await loadAlbumsIfNeeded()
    }
}

// MARK: - Cargar álbumes

private func loadAlbumsIfNeeded() async {

    if appState.daphileClient.albums.isEmpty {

        await appState.daphileClient
            .fetchAlbums()
    }
}

// MARK: - Música Nueva

private var musicNewSection: some View {

    VStack(
        alignment: .leading,
        spacing: 22
    ) {

        HStack {

            Label(
                "Música Nueva",
                systemImage: "clock.fill"
            )
            .font(.headline)
            .foregroundStyle(.primary)

            Spacer()

            Text("Más")
                .font(.headline)
                .foregroundStyle(.secondary)
        }

        ScrollView(
            .horizontal,
            showsIndicators: false
        ) {

            HStack(spacing: 15) {

                ForEach(
                    appState.daphileClient.albums
                        .prefix(15)
                ) { album in

                    NavigationLink {

                        AlbumDetailView(
                            album: album,
                            serverIP:
                                appState.serverIP,
                            playerMAC:
                                appState.selectedPlayerID,
                            networkClient:
                                appState.daphileClient
                        )

                    } label: {

                        AlbumCardView(
                            album: album,
                            serverIP:
                                appState.serverIP,
                            isFocused:
                                focusedItem ==
                                .album(album.id)
                        )
                    }
                    .buttonStyle(.plain)
                    .focused(
                        $focusedItem,
                        equals:
                            .album(album.id)
                    )
                }
            }
            .padding(.horizontal, 55)
            .padding(.vertical, 20)
        }
        .padding(.horizontal, -35)
    }
}

// MARK: - Explorar

private var exploreSection: some View {

    VStack(
        alignment: .leading,
        spacing: 22
    ) {

        Label(
            "Explorar",
            systemImage:
                "music.note.list"
        )
        .font(.headline)
        .foregroundStyle(.primary)

        HStack(spacing: 24) {

            ExploreFocusView(
                title: "Mi Música",
                focusedItem:
                    focusedExploreItem,
                onFocusChanged: {
                    focused in

                    if focused {

                        focusedExploreItem =
                            "Mi Música"

                    }
                    else if
                        focusedExploreItem ==
                        "Mi Música" {

                        focusedExploreItem =
                            nil
                    }
                },
                onSelect: {
                    // Futuro
                }
            )
            .focused(
                $focusedItem,
                equals:
                    .explore("Mi Música")
            )

            ExploreFocusView(
                title: "Radio",
                focusedItem:
                    focusedExploreItem,
                onFocusChanged: {
                    focused in

                    if focused {

                        focusedExploreItem =
                            "Radio"

                    }
                    else if
                        focusedExploreItem ==
                        "Radio" {

                        focusedExploreItem =
                            nil
                    }
                },
                onSelect: {
                    // Futuro
                }
            )
            .focused(
                $focusedItem,
                equals:
                    .explore("Radio")
            )

            ExploreFocusView(
                title: "Favoritos",
                focusedItem:
                    focusedExploreItem,
                onFocusChanged: {
                    focused in

                    if focused {

                        focusedExploreItem =
                            "Favoritos"

                    }
                    else if
                        focusedExploreItem ==
                        "Favoritos" {

                        focusedExploreItem =
                            nil
                    }
                },
                onSelect: {
                    // Futuro
                }
            )
            .focused(
                $focusedItem,
                equals:
                    .explore("Favoritos")
            )

            ExploreFocusView(
                title: "Aplicaciones",
                focusedItem:
                    focusedExploreItem,
                onFocusChanged: {
                    focused in

                    if focused {

                        focusedExploreItem =
                            "Aplicaciones"

                    }
                    else if
                        focusedExploreItem ==
                        "Aplicaciones" {

                        focusedExploreItem =
                            nil
                    }
                },
                onSelect: {
                    // Futuro
                }
            )
            .focused(
                $focusedItem,
                equals:
                    .explore("Aplicaciones")
            )
        }
    }
}

}

