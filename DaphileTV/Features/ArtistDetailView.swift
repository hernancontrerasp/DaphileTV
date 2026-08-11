import SwiftUI

struct ArtistDetailView: View {
    let artist: LMSArtistItem
    let serverIP: String
    let playerMAC: String
    @ObservedObject var networkClient: DaphileClient
    
    // Matriz de 4 columnas optimizada para el televisor
    let columns = [
        GridItem(.flexible(), spacing: 30),
        GridItem(.flexible(), spacing: 30),
        GridItem(.flexible(), spacing: 30),
        GridItem(.flexible(), spacing: 30)
    ]
    
    // Estado para controlar el enfoque de los álbumes en la grilla
    @FocusState private var focusedAlbumID: Int?
    
    var body: some View {
        let filteredAlbums = networkClient.albums
            .filter { $0.artist.lowercased() == artist.name.lowercased() }
            .sorted { ($0.year ?? 0) < ($1.year ?? 0) }

        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                
                // --- ENCABEZADO INFORMATIVO SUPERIOR ---
                HStack(alignment: VerticalAlignment.top, spacing: 40) {
                    AsyncImage(url: artist.pictureURL(serverIP: serverIP)) { image in
                        image.resizable()
                             .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gray.opacity(0.2)
                    }
                    .frame(width: 150, height: 150)
                    .clipShape(Circle())
                    .shadow(radius: 10)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text(artist.name)
                            .font(.system(size: 45, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Alternative • Electronic • Synth-pop")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("\(filteredAlbums.count) Álbumes")
                            .font(.subheadline)
                            .foregroundColor(.accentColor)
                        
                        HStack(spacing: 20) {
                            Button(action: {
                                Task { await networkClient.sendCommand(targetPlayer: playerMAC, command: ["playlist", "add", "artist_id:\(artist.id)"]) }
                            }) { Label("Añadir", systemImage: "plus.circle.fill") }
                            
                            Button(action: {
                                Task { await networkClient.sendCommand(targetPlayer: playerMAC, command: ["playlist", "insert", "artist_id:\(artist.id)"]) }
                            }) { Label("Siguiente", systemImage: "arrow.turn.down.right") }
                            
                            Button(action: {
                                Task { await networkClient.sendCommand(targetPlayer: playerMAC, command: ["playlist", "play", "artist_id:\(artist.id)"]) }
                            }) { Label("Reproducir", systemImage: "play.fill") }
                        }
                        .buttonStyle(.bordered)
                        .padding(.top, 10)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 30)
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                    .padding(.horizontal, 20)
                
                // --- MOSAICO INFERIOR DE ÁLBUMES ---
                if filteredAlbums.isEmpty {
                    ContentUnavailableView(
                        "Sin Álbumes",
                        systemImage: "record.circle",
                        description: Text("No se encontraron álbumes cargados en memoria para \(artist.name).")
                    )
                    .padding(.top, 100)
                } else {
                    LazyVGrid(columns: columns, spacing: 40) {
                        ForEach(filteredAlbums) { album in
                            let isFocused = (focusedAlbumID == album.id)
                            
                            NavigationLink(destination: AlbumDetailView(album: album, serverIP: serverIP, playerMAC: playerMAC, networkClient: networkClient)) {
                                AlbumCardView(
                                    album: album,
                                    serverIP: serverIP,
                                    isFocused: isFocused
                                )
                                .frame(width: 360) // <-- Aquí le damos el tamaño grande deseado en esta vista
                            }
                            .buttonStyle(NoBackgroundButtonStyle())
                            .id(album.id)
                            .focused($focusedAlbumID, equals: album.id)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.bottom, 60)
        }
    }
}
