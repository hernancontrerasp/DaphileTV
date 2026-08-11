import SwiftUI

struct NowPlayingRootView: View {
    @EnvironmentObject private var appState: AppState
    @State private var isLoading = true

    var body: some View {
        ZStack {
            // Fondo oscuro base de la pestaña
            Color.black.ignoresSafeArea()

            Group {
                if isLoading {
                    ProgressView("Sincronizando reproductor...")
                        .tint(.white)
                } else if let currentTrack = appState.daphileClient.currentTrack,
                          let targetAlbum = resolveAlbum(for: currentTrack) {
                    
                    // Renderizamos el reproductor adaptado al espacio de la pestaña
                    PlayerFullScreenView(
                        album: targetAlbum,
                        serverIP: appState.serverIP,
                        playerMAC: appState.selectedPlayerID,
                        startIndex: 0,
                        shuffle: false,
                        resumeExistingPlayback: true,
                        networkClient: appState.daphileClient
                    )
                    .transition(.opacity) // Transición suave al aparecer
                    
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "music.note.tv")
                            .font(.system(size: 70))
                            .foregroundStyle(.secondary)
                        
                        Text("No hay reproducción activa")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundStyle(.white)
                        
                        Text("Selecciona un álbum o artista de tu biblioteca para comenzar a escuchar.")
                            .font(.system(size: 20, weight: .regular))
                            .foregroundStyle(Color.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .frame(width: 600)
                    }
                }
            }
        }
        .task {
            await appState.daphileClient.fetchCurrentTrackInfo(targetPlayer: appState.selectedPlayerID)
            
            try? await Task.sleep(for: .milliseconds(300))
            
            await MainActor.run {
                isLoading = false
            }
        }
    }
    
    private func resolveAlbum(for track: LMSCurrentTrack) -> LMSAlbum? {
        if let id = track.albumID,
           let album = appState.daphileClient.albums.first(where: { $0.id == id }) {
            return album
        }
        
        if let title = track.album, title != "Sin álbum",
           let album = appState.daphileClient.albums.first(where: { $0.title.lowercased() == title.lowercased() }) {
            return album
        }
        
        if let artistName = track.artist,
           let album = appState.daphileClient.albums.first(where: { $0.artist.lowercased() == artistName.lowercased() }) {
            return album
        }
        
        return LMSAlbum(
            id: track.albumID ?? 0,
            title: track.album ?? "Música Actual",
            artist: track.artist ?? "Desconocido",
            year: nil,
            artworkTrackID: track.artworkTrackID
        )
    }
}
