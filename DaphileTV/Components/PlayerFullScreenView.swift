import SwiftUI

struct PlayerFullScreenView: View {

    let album: LMSAlbum
    let serverIP: String
    let playerMAC: String
    let startIndex: Int
    let shuffle: Bool

    @ObservedObject var networkClient: DaphileClient

    @State private var isPlaying = false
    @State private var isStartingPlayback = true

    var body: some View {

        ZStack {

            Color.black
                .ignoresSafeArea()

            HStack(
                alignment: .center,
                spacing: 70
            ) {

                // MARK: - Carátula

                AsyncImage(
                    url: album.artworkURL(
                        serverIP: serverIP
                    )
                ) { phase in

                    switch phase {

                    case .empty:

                        ZStack {

                            RoundedRectangle(
                                cornerRadius: 24
                            )
                            .fill(
                                Color.gray.opacity(0.2)
                            )

                            ProgressView()
                        }

                    case .success(let image):

                        image
                            .resizable()
                            .aspectRatio(
                                contentMode: .fill
                            )

                    case .failure:

                        ZStack {

                            RoundedRectangle(
                                cornerRadius: 24
                            )
                            .fill(
                                Color.gray.opacity(0.2)
                            )

                            Image(
                                systemName: "music.note"
                            )
                            .font(
                                .system(size: 70)
                            )
                            .foregroundStyle(
                                .secondary
                            )
                        }

                    @unknown default:

                        RoundedRectangle(
                            cornerRadius: 24
                        )
                        .fill(
                            Color.gray.opacity(0.2)
                        )
                    }
                }
                .frame(
                    width: 650,
                    height: 650
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 24
                    )
                )
                .shadow(
                    color: .black.opacity(0.6),
                    radius: 35,
                    x: 0,
                    y: 20
                )

                // MARK: - Información

                VStack(
                    alignment: .leading,
                    spacing: 18
                ) {

                    if let currentTrack =
                        networkClient.currentTrack {

                        Text(
                            currentTrack.title ??
                            "Sin título"
                        )
                        .font(
                            .system(
                                size: 48,
                                weight: .bold
                            )
                        )
                        .foregroundStyle(.white)
                        .lineLimit(2)

                        Text(
                            currentTrack.artist ??
                            "Artista desconocido"
                        )
                        .font(
                            .system(
                                size: 30,
                                weight: .medium
                            )
                        )
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    } else {

                        Text(album.title)
                            .font(
                                .system(
                                    size: 48,
                                    weight: .bold
                                )
                            )
                            .foregroundStyle(.white)
                            .lineLimit(2)

                        Text(album.artist)
                            .font(
                                .system(
                                    size: 30,
                                    weight: .medium
                                )
                            )
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    // MARK: - Estado

                    if isStartingPlayback {

                        ProgressView()
                            .controlSize(.large)

                    } else {

                        // MARK: - Controles

                        HStack(spacing: 35) {

                            Button {

                                Task {
                                    await previousTrack()
                                }

                            } label: {

                                Image(
                                    systemName:
                                        "backward.fill"
                                )
                                .font(
                                    .system(size: 38)
                                )
                            }

                            Button {

                                Task {
                                    await togglePlayPause()
                                }

                            } label: {

                                Image(
                                    systemName:
                                        isPlaying
                                        ? "pause.fill"
                                        : "play.fill"
                                )
                                .font(
                                    .system(size: 55)
                                )
                            }

                            Button {

                                Task {
                                    await nextTrack()
                                }

                            } label: {

                                Image(
                                    systemName:
                                        "forward.fill"
                                )
                                .font(
                                    .system(size: 38)
                                )
                            }
                        }
                        .foregroundStyle(.white)
                    }

                    Spacer()
                }
                .frame(
                    width: 600,
                    alignment: .leading
                )
            }
            .padding(60)
        }
        .task {

            await startPlayback()
        }
    }

    // MARK: - Iniciar reproducción

    private func startPlayback() async {

        isStartingPlayback = true

        // -------------------------------------------------
        // 1. Obtener las canciones del álbum
        // -------------------------------------------------

        await networkClient.fetchTracks(
            targetPlayer: playerMAC,
            albumID: album.id
        )

        guard !networkClient.tracks.isEmpty else {

            isStartingPlayback = false
            return
        }

        // -------------------------------------------------
        // 2. Cargar el álbum en la playlist
        // -------------------------------------------------

        await networkClient.sendCommand(
            targetPlayer: playerMAC,
            command: [
                "playlistcontrol",
                "cmd:load",
                "album_id:\(album.id)",
                "play_index:\(max(startIndex, 0))"
            ]
        )

        // -------------------------------------------------
        // 3. Dar tiempo a Daphile para construir la playlist
        // -------------------------------------------------

        try? await Task.sleep(
            for: .milliseconds(400)
        )

        // -------------------------------------------------
        // 4. Configurar el modo shuffle
        //
        // 0 = orden normal
        // 1 = canciones aleatorias
        // -------------------------------------------------

        await networkClient.sendCommand(
            targetPlayer: playerMAC,
            command: [
                "playlist",
                "shuffle",
                shuffle ? "1" : "0"
            ]
        )

        // -------------------------------------------------
        // 5. Si estamos en modo aleatorio:
        //
        // Daphile ya tiene el álbum cargado y el shuffle
        // activado. Seleccionamos el primer índice de la
        // playlist resultante.
        //
        // Esto evita escoger nosotros una canción al azar.
        // El orden lo determina Daphile.
        // -------------------------------------------------

        if shuffle {

            try? await Task.sleep(
                for: .milliseconds(300)
            )

            await networkClient.sendCommand(
                targetPlayer: playerMAC,
                command: [
                    "playlist",
                    "index",
                    "0"
                ]
            )
        }

        // -------------------------------------------------
        // 6. Dar tiempo a Daphile para actualizar el estado
        // -------------------------------------------------

        try? await Task.sleep(
            for: .milliseconds(400)
        )

        await refreshPlayerState()

        isStartingPlayback = false
    }

    // MARK: - Estado del reproductor

    private func refreshPlayerState() async {

        await networkClient.fetchCurrentTrackInfo(
            targetPlayer: playerMAC
        )

        if networkClient.currentTrack != nil {

            isPlaying = true
        }
    }

    // MARK: - Play / Pause

    private func togglePlayPause() async {

        if isPlaying {

            await networkClient.sendCommand(
                targetPlayer: playerMAC,
                command: [
                    "pause",
                    "1"
                ]
            )

            isPlaying = false

        } else {

            await networkClient.sendCommand(
                targetPlayer: playerMAC,
                command: [
                    "pause",
                    "0"
                ]
            )

            isPlaying = true
        }
    }

    // MARK: - Canción anterior

    private func previousTrack() async {

        await networkClient.sendCommand(
            targetPlayer: playerMAC,
            command: [
                "button",
                "jump_rew"
            ]
        )

        try? await Task.sleep(
            for: .milliseconds(250)
        )

        await refreshPlayerState()
    }

    // MARK: - Canción siguiente

    private func nextTrack() async {

        await networkClient.sendCommand(
            targetPlayer: playerMAC,
            command: [
                "button",
                "jump_fwd"
            ]
        )

        try? await Task.sleep(
            for: .milliseconds(250)
        )

        await refreshPlayerState()
    }
}
