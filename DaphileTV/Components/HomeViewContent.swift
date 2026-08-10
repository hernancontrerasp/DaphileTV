import SwiftUI

struct HomeViewContent: View {

    @EnvironmentObject private var appState: AppState

    @Binding var focusMusicRequest: Bool

    @FocusState private var focusedItem: FocusArea?

    @State private var focusedExploreItem: String?

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

                // MARK: - Música Nueva

                musicNewSection

                // MARK: - Explorar

                exploreSection
            }
            .padding(.horizontal, 35)
            .padding(.top, 0)
            .padding(.bottom, 30)
        }
        .onChange(
            of: focusMusicRequest
        ) { _, requested in

            guard requested else {
                return
            }

            focusMusicRequest = false

            focusFirstAlbum()
        }
        .task {

            await loadAlbumsIfNeeded()
        }
    }

    // MARK: - Cargar álbumes

    private func loadAlbumsIfNeeded() async {

        if appState.daphileClient.albums.isEmpty {

            await appState.daphileClient.fetchAlbums()
        }
    }

    // MARK: - Primer álbum

    private func focusFirstAlbum() {

        guard let firstAlbum =
            appState
                .daphileClient
                .albums
                .prefix(15)
                .first
        else {
            return
        }

        focusedItem = .album(firstAlbum.id)
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

                HStack(
                    alignment: .top,
                    spacing: 15
                ) {

                    ForEach(
                        Array(
                            appState
                                .daphileClient
                                .albums
                                .prefix(15)
                        )
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
                .padding(
                    .horizontal,
                    55
                )
                .padding(
                    .vertical,
                    20
                )
            }
            .padding(
                .horizontal,
                -35
            )
        }
        .focusSection()
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

            HStack(
                alignment: .top,
                spacing: 24
            ) {

                ExploreFocusView(
                    title: "Mi Música",
                    focusedItem:
                        focusedExploreItem,
                    onFocusChanged: {
                        focused in

                        if focused {

                            focusedExploreItem =
                                "Mi Música"

                        } else if
                            focusedExploreItem ==
                            "Mi Música" {

                            focusedExploreItem =
                                nil
                        }
                    },
                    onSelect: {
                        // Acción futura
                    }
                )
                .focused(
                    $focusedItem,
                    equals:
                        .explore(
                            "Mi Música"
                        )
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

                        } else if
                            focusedExploreItem ==
                            "Radio" {

                            focusedExploreItem =
                                nil
                        }
                    },
                    onSelect: {
                        // Acción futura
                    }
                )
                .focused(
                    $focusedItem,
                    equals:
                        .explore(
                            "Radio"
                        )
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

                        } else if
                            focusedExploreItem ==
                            "Favoritos" {

                            focusedExploreItem =
                                nil
                        }
                    },
                    onSelect: {
                        // Acción futura
                    }
                )
                .focused(
                    $focusedItem,
                    equals:
                        .explore(
                            "Favoritos"
                        )
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

                        } else if
                            focusedExploreItem ==
                            "Aplicaciones" {

                            focusedExploreItem =
                                nil
                        }
                    },
                    onSelect: {
                        // Acción futura
                    }
                )
                .focused(
                    $focusedItem,
                    equals:
                        .explore(
                            "Aplicaciones"
                        )
                )
            }
        }
    }
}

// MARK: - ExploreFocusView

struct ExploreFocusView: View {

    let title: String
    let focusedItem: String?

    let onFocusChanged:
        (Bool) -> Void

    let onSelect:
        () -> Void

    private var isFocused: Bool {

        focusedItem == title
    }

    private var icon: String {

        switch title {

        case "Mi Música":
            return "music.note.house.fill"

        case "Radio":
            return
                "antenna.radiowaves.left.and.right"

        case "Favoritos":
            return "heart.fill"

        case "Aplicaciones":
            return
                "square.grid.3x3.fill"

        default:
            return "music.note"
        }
    }

    private var iconBackground: Color {

        switch title {

        case "Mi Música":
            return Color.blue.opacity(0.8)

        case "Radio":
            return Color.orange.opacity(0.8)

        case "Favoritos":
            return Color.red.opacity(0.8)

        case "Aplicaciones":
            return Color.purple.opacity(0.8)

        default:
            return Color.gray.opacity(0.8)
        }
    }

    var body: some View {

        TVFocusableView(
            isFocused: Binding(
                get: {
                    isFocused
                },
                set: { focused in

                    onFocusChanged(
                        focused
                    )
                }
            ),
            onSelect: {

                onSelect()
            }
        ) {

            Button {

                onSelect()

            } label: {

                VStack(
                    spacing: 20
                ) {

                    Image(
                        systemName: icon
                    )
                    .font(
                        .system(
                            size: 65
                        )
                    )
                    .foregroundColor(
                        .white
                    )
                    .frame(
                        width: 140,
                        height: 140
                    )
                    .background(
                        iconBackground
                    )
                    .cornerRadius(25)

                    Text(title)
                        .font(
                            .system(
                                size: 26,
                                weight: .medium
                            )
                        )
                        .foregroundColor(
                            isFocused
                            ? .black
                            : .primary
                        )
                }
                .frame(
                    maxWidth: .infinity
                )
                .padding(
                    .vertical,
                    20
                )
            }
            .buttonStyle(
                .bordered
            )
            .tint(
                isFocused
                ? .white
                : nil
            )
            .scaleEffect(
                isFocused
                ? 1.06
                : 1.0
            )
            .animation(
                .easeOut(
                    duration: 0.15
                ),
                value: isFocused
            )
        }
        .frame(
            maxWidth: .infinity,
            minHeight: 220,
            maxHeight: 240
        )
    }
}

// MARK: - Preview

#Preview {

    HomeViewContent(
        focusMusicRequest:
            .constant(false)
    )
    .environmentObject(
        AppState()
    )
}
