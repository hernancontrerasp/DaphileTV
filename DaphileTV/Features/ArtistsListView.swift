import SwiftUI

struct ArtistsListView: View {
    @EnvironmentObject private var appState: AppState
    
    // Grilla de 6 columnas basada en tu diseño
    let columns = Array(repeating: GridItem(.flexible(), spacing: 20), count: 6)
    let alphabet = ["#", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]
    
    @FocusState private var focusedArtistID: Int?
    
    var body: some View {
        ScrollViewReader { proxy in
            HStack(alignment: .top, spacing: 0) {
                
                // MARK: - BARRA ALFABÉTICA LATERAL
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 5) {
                        ForEach(alphabet, id: \.self) { letter in
                            Button {
                                // Asumimos que appState.daphileClient tiene la lista de artistas
                                if let targetIndex = appState.daphileClient.artistsList.firstIndex(where: { $0.firstLetter == letter }) {
                                    let targetArtist = appState.daphileClient.artistsList[targetIndex]
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        proxy.scrollTo(targetArtist.id, anchor: .top)
                                    }
                                    focusedArtistID = targetArtist.id
                                }
                            } label: {
                                Text(letter)
                                    .font(.system(size: 15, weight: .bold))
                                    .frame(width: 35, height: 28)
                            }
                            // Usamos plain aquí porque son botones muy pequeños de navegación rápida
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 10)
                }
                .frame(width: 50)
                // Color semántico para soportar ambos temas
                .background(Color.secondary.opacity(0.1))
                
                // MARK: - MOSAICO DE ARTISTAS
                ScrollView {
                    VStack(alignment: .leading, spacing: 15) {
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text("Artistas")
                                .font(.system(size: 38, weight: .bold))
                                .foregroundStyle(.primary) // Reemplaza .white
                            
                            Text("(\(appState.daphileClient.artistsList.count))")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        if appState.daphileClient.artistsList.isEmpty {
                            ProgressView()
                                .scaleEffect(2.0)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .padding(.top, 150)
                        } else {
                            LazyVGrid(columns: columns, spacing: 35) {
                                ForEach(appState.daphileClient.artistsList) { artist in
                                    NavigationLink {
                                        // Aquí irá ArtistDetailView
                                        Text("Detalle de \(artist.name)")
                                    } label: {
                                        ArtistCardView(
                                            artist: artist,
                                            serverIP: appState.serverIP,
                                            isFocused: focusedArtistID == artist.id
                                        )
                                    }
                                    .buttonStyle(CardButtonStyle()) // Anula el fondo blanco nativo
                                    .id(artist.id)
                                    .focused($focusedArtistID, equals: artist.id)
                                    .contextMenu {
                                        Button {
                                            Task { await appState.daphileClient.sendCommand( targetPlayer: appState.selectedPlayerID, command: ["playlist", "add", "artist_id:\(artist.id)"]) }
                                        } label: { Label("Añadir a la cola", systemImage: "text.badge.plus") }
                                        
                                        Button {
                                            Task { await appState.daphileClient.sendCommand( targetPlayer: appState.selectedPlayerID, command: ["playlist", "insert", "artist_id:\(artist.id)"]) }
                                        } label: { Label("Reproducir siguiente", systemImage: "arrow.turn.down.right") }
                                        
                                        Button {
                                            Task { await appState.daphileClient.sendCommand( targetPlayer: appState.selectedPlayerID, command: ["playlist", "play", "artist_id:\(artist.id)"]) }
                                        } label: { Label("Reproducir Ahora", systemImage: "play.fill") }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 30)
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)
        }
        .task {
            // Asumimos que creas esta función en tu cliente para mantener la consistencia
            if appState.daphileClient.artistsList.isEmpty {
                await appState.daphileClient.fetchArtists()
            }
        }
    }
}
