import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @FocusState private var focusedItem: FocusArea?

    // Eliminamos 'focusedExploreItem' porque @FocusState ya hace ese trabajo.

    enum FocusArea: Hashable {
        case album(Int)
        case explore(String)
    }
    
    // Estructuramos las categorías para iterarlas limpiamente
    let exploreCategories = ["Mi Música", "Radio", "Favoritos", "Aplicaciones"]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 32) {
                // MARK: - Música Nueva
                musicNewSection

                // MARK: - Explorar
                exploreSection
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
        // Nota arquitectónica: Idealmente AppState debería encapsular esto.
        // Ej: await appState.loadInitialData() para que la vista no conozca a daphileClient.
        if appState.daphileClient.albums.isEmpty {
            await appState.daphileClient.fetchAlbums()
        }
    }

    // MARK: - Música Nueva
    private var musicNewSection: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack {
                Label("Música Nueva", systemImage: "clock.fill")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                Text("Más")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                // CAMBIO CLAVE: LazyHStack para optimizar memoria en tvOS
                LazyHStack(spacing: 15) {
                    ForEach(appState.daphileClient.albums.prefix(15)) { album in
                        NavigationLink {
                            AlbumDetailView(
                                album: album,
                                serverIP: appState.serverIP,
                                playerMAC: appState.selectedPlayerID,
                                networkClient: appState.daphileClient
                            )
                        } label: {
                            AlbumCardView(
                                album: album,
                                serverIP: appState.serverIP,
                                isFocused: focusedItem == .album(album.id)
                            )
                        }
                        .buttonStyle(CardButtonStyle()) // Tienes que asegurarte de desactivar el estilo por defecto de tvOS
                        .focused($focusedItem, equals: .album(album.id))
                    }
                }
                .padding(.horizontal, 55)
                .padding(.vertical, 20)
            }
            .padding(.horizontal, -35)
        }
        .focusSection()
    }

    // MARK: - Explorar
        private var exploreSection: some View {
            VStack(alignment: .leading, spacing: 22) {
                Label("Explorar", systemImage: "music.note.list")
                    .font(.headline)
                    .foregroundStyle(.primary)

                HStack(alignment: .top, spacing: 24) {
                    ForEach(exploreCategories, id: \.self) { category in
                        if category == "Mi Música" {
                            // Conectamos la nueva vista
                            NavigationLink {
                                MyMusicView()
                            } label: {
                                ExploreFocusView(
                                    title: category,
                                    focusedItem: focusedItem == .explore(category) ? category : nil,
                                    onFocusChanged: { _ in },
                                    onSelect: { }
                                )
                            }
                            .buttonStyle(CardButtonStyle()) // Anula el fondo nativo de tvOS
                            .focused($focusedItem, equals: .explore(category))
                            
                        } else {
                            // Los demás botones quedan como vistas estáticas por ahora
                            ExploreFocusView(
                                title: category,
                                focusedItem: focusedItem == .explore(category) ? category : nil,
                                onFocusChanged: { _ in },
                                onSelect: { }
                            )
                            .focused($focusedItem, equals: .explore(category))
                        }
                    }
                }
                .focusSection()
            }
            .focusSection()
        }
}
