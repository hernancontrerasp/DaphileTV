import SwiftUI
import Combine

struct PlayerFullScreenView: View {

    let album: LMSAlbum
    let serverIP: String
    let playerMAC: String
    let startIndex: Int
    let shuffle: Bool
    var resumeExistingPlayback: Bool = false

    @ObservedObject var networkClient: DaphileClient

    @State private var isPlaying = false
    @State private var isStartingPlayback = true

    @State private var currentTime: TimeInterval = 0
    @State private var totalTime: TimeInterval = 1

    @State private var seekTask: Task<Void, Never>?
    @State private var isSeeking = false

    @FocusState private var isProgressFocused: Bool
    @FocusState private var focusedControl: PlaybackControl?

    enum PlaybackControl: Hashable {
        case previous, playPause, next
    }

    private let timer =
        Timer.publish(
            every: 0.25,
            on: .main,
            in: .common
        )
        .autoconnect()

    var body: some View {
        ZStack {
            // MARK: - Fondo Dinámico Inspirado en Apple Music
            GeometryReader { proxy in
                AsyncImage(url: album.artworkURL(serverIP: serverIP)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: proxy.size.width, height: proxy.size.height)
                            .blur(radius: 80) // Desenfoque profundo para mezclar los colores
                            .saturation(1.4)  // Intensifica ligeramente los tonos de la carátula
                            .brightness(-0.35) // Oscurece el fondo para mantener el contraste con el texto blanco
                    default:
                        Color.black // Fondo oscuro de respaldo si falla la carátula
                    }
                }
                .ignoresSafeArea()
            }

            // Capa sutil de gradiente para darle profundidad cinematográfica
            LinearGradient(
                colors: [Color.black.opacity(0.3), Color.black.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // MARK: - Contenido Principal de la Reproducción
            VStack(spacing: 0) {

                // Información principal
                HStack(
                    alignment: .center,
                    spacing: 70
                ) {
                    albumArtwork
                        .overlay(
                            Group {
                                if isStartingPlayback {
                                    ZStack {
                                        Color.black.opacity(0.4)
                                            .cornerRadius(24)
                                        ProgressView()
                                            .scaleEffect(1.5)
                                    }
                                }
                            }
                        )

                    trackInformation

                    Spacer(minLength: 0)
                }
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
                .padding(.horizontal, 75)
                .padding(.top, 0)
                .offset(y: -10)

                Spacer(minLength: 25)

                // Barra de progreso
                progressSection
                    .offset(y: 45)

                Spacer(minLength: 30)

                // Controles
                playbackControls
                    .offset(y: 45)

                Spacer(minLength: 15)
            }
            .padding(.vertical, 20)
        }
        .task {
            if resumeExistingPlayback {
                    // Si venimos de la pestaña "En reproducción", solo sincronizamos el estado actual
                await refreshPlayerState()
                isStartingPlayback = false
            } else {
                // Si venimos de hacer click en un álbum de la grilla, iniciamos la reproducción normal
                await startPlayback()
            }
        }
        .onReceive(timer) { _ in
            guard isPlaying, totalTime > 0, !isSeeking, currentTime < totalTime else {
                return
            }
            currentTime = min(currentTime + 0.25, totalTime)
        }
    }

    // MARK: - Artwork con Iluminación Estilo tvOS

    private var albumArtwork: some View {
        AsyncImage(
            url: album.artworkURL(
                serverIP: serverIP
            )
        ) { phase in
            switch phase {
            case .empty:
                artworkPlaceholder
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case .failure:
                artworkPlaceholder
            @unknown default:
                artworkPlaceholder
            }
        }
        .frame(width: 680, height: 680)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.25), lineWidth: 2)
        )
        .shadow(
            color: Color.white.opacity(0.15),
            radius: 35,
            x: 0,
            y: 15
        )
    }

    private var artworkPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.08))

            Image(systemName: "music.note")
                .font(.system(size: 80))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Track information

    private var trackInformation: some View {
        VStack(
            alignment: .leading,
            spacing: 16
        ) {
            if let currentTrack = networkClient.currentTrack {
                Text(currentTrack.title ?? "Sin título")
                    .font(.system(size: 58, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                Text(currentTrack.artist ?? album.artist)
                    .font(.system(size: 38, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.72))
                    .lineLimit(1)

                Text(currentTrack.album ?? album.title)
                    .font(.system(size: 30, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.52))
                    .lineLimit(1)

                if let year = currentTrack.year, !year.isEmpty {
                    Text(year)
                        .font(.system(size: 24, weight: .regular))
                        .foregroundStyle(Color.white.opacity(0.42))
                }

                technicalInformation

            } else {
                Text(album.title)
                    .font(.system(size: 58, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                Text(album.artist)
                    .font(.system(size: 38, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.72))
                    .lineLimit(1)

                HStack(spacing: 12) {
                    ProgressView()
                        .tint(.white)
                    Text("Cargando pista...")
                        .font(.system(size: 30, weight: .regular))
                        .foregroundStyle(Color.white.opacity(0.45))
                }
            }
        }
        .frame(width: 650, alignment: .leading)
    }

    // MARK: - Technical information

    @ViewBuilder
    private var technicalInformation: some View {
        if let track = currentLMSTrack {
            let codec = track.fileType?.lowercased() == "flc" ? "FLAC" : (track.fileType?.uppercased() ?? "")
            let parts = [codec, track.sampleSize ?? "", track.sampleRate ?? "", track.bitrate ?? ""].filter { !$0.isEmpty }

            if !parts.isEmpty {
                Text(parts.joined(separator: " • "))
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.38))
                    .padding(.top, 8)
            }
        }
    }

    private var currentLMSTrack: LMSTrack? {
        guard let currentTrack = networkClient.currentTrack else { return nil }
        return networkClient.tracks.first { $0.title == currentTrack.title }
    }

    // MARK: - Progress

    private var progressSection: some View {
        HStack(spacing: 24) {
            Text(formatTime(currentTime))
                .font(.system(size: 18))
                .foregroundStyle(Color.white.opacity(0.55))
                .frame(width: 70, alignment: .leading)

            GeometryReader { geometry in
                let progress = totalTime > 0 ? min(max(currentTime / totalTime, 0), 1) : 0

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.18))
                        .frame(height: 6)

                    Capsule()
                        .fill(isProgressFocused ? Color.white : Color.accentColor)
                        .frame(width: geometry.size.width * progress, height: isProgressFocused ? 8 : 6)

                    Rectangle()
                        .fill(.white)
                        .frame(width: 3, height: isProgressFocused ? 26 : 18)
                        .offset(x: geometry.size.width * progress)
                }
                .frame(height: 24)
                .animation(.interactiveSpring(response: 0.15, dampingFraction: 0.85), value: currentTime)
            }
            .frame(height: 24)
            .focusable(true)
            .focused($isProgressFocused)
            .scaleEffect(isProgressFocused ? 1.02 : 1.0)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isProgressFocused ? Color.white.opacity(0.8) : Color.clear, lineWidth: 3)
                    .padding(-6)
            )
            .animation(.easeOut(duration: 0.2), value: isProgressFocused)
            .onChange(of: isProgressFocused) { _, focused in
                isSeeking = focused
            }
            .onMoveCommand { direction in
                handleProgressMovement(direction)
            }

            Text(formatTime(totalTime))
                .font(.system(size: 18))
                .foregroundStyle(Color.white.opacity(0.55))
                .frame(width: 70, alignment: .trailing)
        }
        .padding(.horizontal, 75)
    }

    private func handleProgressMovement(_ direction: MoveCommandDirection) {
        switch direction {
        case .left:
            let target = max(0, currentTime - 10)
            currentTime = target
            scheduleSeek(target)
        case .right:
            let target = min(totalTime, currentTime + 10)
            currentTime = target
            scheduleSeek(target)
        default:
            break
        }
    }

    private func scheduleSeek(_ seconds: TimeInterval) {
        seekTask?.cancel()
        isSeeking = true

        seekTask = Task {
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled else { return }

            await networkClient.sendCommand(
                targetPlayer: playerMAC,
                command: ["time", String(Int(seconds))]
            )

            guard !Task.isCancelled else { return }

            await MainActor.run {
                seekTask = nil
                isSeeking = false
            }
        }
    }

    // MARK: - Playback controls

    private var playbackControls: some View {
        HStack(spacing: 50) {
            Button {
                Task { await previousTrack() }
            } label: {
                Image(systemName: "backward.fill")
                    .font(.system(size: 28, weight: .medium))
                    .frame(width: 68, height: 68)
            }
            .buttonStyle(PlayerControlButtonStyle(isFocused: focusedControl == .previous))
            .focused($focusedControl, equals: .previous)

            Button {
                Task { await togglePlayPause() }
            } label: {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 34, weight: .semibold))
                    .frame(width: 86, height: 86)
            }
            .buttonStyle(PlayerControlButtonStyle(isFocused: focusedControl == .playPause))
            .focused($focusedControl, equals: .playPause)

            Button {
                Task { await nextTrack() }
            } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 28, weight: .medium))
                    .frame(width: 68, height: 68)
            }
            .buttonStyle(PlayerControlButtonStyle(isFocused: focusedControl == .next))
            .focused($focusedControl, equals: .next)
        }
    }

    private func startPlayback() async {
        isStartingPlayback = true

        await networkClient.fetchTracks(
            targetPlayer: playerMAC,
            albumID: album.id
        )

        guard !networkClient.tracks.isEmpty else {
            isStartingPlayback = false
            return
        }

        let initialIndex = max(startIndex, 0)

        await networkClient.sendCommand(
            targetPlayer: playerMAC,
            command: [
                "playlistcontrol",
                "cmd:load",
                "album_id:\(album.id)",
                "play_index:\(initialIndex)"
            ]
        )

        try? await Task.sleep(for: .milliseconds(400))

        let shuffleValue = shuffle ? "1" : "0"
        await networkClient.sendCommand(
            targetPlayer: playerMAC,
            command: ["playlist", "shuffle", shuffleValue]
        )

        if shuffle {
            try? await Task.sleep(for: .milliseconds(300))
            await networkClient.sendCommand(
                targetPlayer: playerMAC,
                command: ["playlist", "index", "0"]
            )
        }

        try? await Task.sleep(for: .milliseconds(400))
        await refreshPlayerState()
        isStartingPlayback = false
    }

    private func refreshPlayerState() async {
        await networkClient.fetchCurrentTrackInfo(targetPlayer: playerMAC)
        isPlaying = networkClient.currentTrack != nil

        if let track = networkClient.currentTrack, let duration = track.duration, duration > 0 {
            totalTime = duration
        }
    }

    private func togglePlayPause() async {
        if isPlaying {
            await networkClient.sendCommand(targetPlayer: playerMAC, command: ["pause", "1"])
            isPlaying = false
        } else {
            await networkClient.sendCommand(targetPlayer: playerMAC, command: ["pause", "0"])
            isPlaying = true
        }
    }

    private func previousTrack() async {
        await networkClient.sendCommand(targetPlayer: playerMAC, command: ["button", "jump_rew"])
        try? await Task.sleep(for: .milliseconds(250))
        currentTime = 0
        await refreshPlayerState()
    }

    private func nextTrack() async {
        await networkClient.sendCommand(targetPlayer: playerMAC, command: ["button", "jump_fwd"])
        try? await Task.sleep(for: .milliseconds(250))
        currentTime = 0
        await refreshPlayerState()
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let totalSeconds = max(0, Int(seconds))
        let minutes = totalSeconds / 60
        let remainingSeconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

struct PlayerControlButtonStyle: ButtonStyle {
    let isFocused: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                Circle()
                    .fill(isFocused ? Color.white : Color.white.opacity(0.15))
            )
            .foregroundStyle(isFocused ? Color.black : Color.white)
            .overlay(
                Circle()
                    .stroke(isFocused ? Color.white : Color.clear, lineWidth: 4)
            )
            .shadow(
                color: isFocused ? Color.white.opacity(0.5) : Color.black.opacity(0.3),
                radius: isFocused ? 20 : 5,
                x: 0,
                y: isFocused ? 8 : 4
            )
            .scaleEffect(isFocused ? 1.18 : 1.0)
            .animation(.easeOut(duration: 0.18), value: isFocused)
    }
}
