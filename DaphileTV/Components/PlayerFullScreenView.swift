import SwiftUI
import Combine

struct PlayerFullScreenView: View {

    let album: LMSAlbum
    let serverIP: String
    let playerMAC: String
    let startIndex: Int
    let shuffle: Bool

    @ObservedObject var networkClient: DaphileClient

    @State private var isPlaying = false
    @State private var isStartingPlayback = true

    @State private var currentTime: TimeInterval = 0
    @State private var totalTime: TimeInterval = 1

    @State private var seekTask: Task<Void, Never>?
    @State private var isSeeking = false

    @FocusState private var isProgressFocused: Bool

    // Timer visual.
    //
    // Se utiliza únicamente para mantener actualizado el tiempo
    // que se muestra en pantalla. No consulta LMSCurrentTrack.time,
    // porque esa propiedad no existe.
    private let timer =
        Timer.publish(
            every: 0.25,
            on: .main,
            in: .common
        )
        .autoconnect()

    var body: some View {

        VStack(spacing: 0) {

            // MARK: - Información principal

            HStack(
                alignment: .center,
                spacing: 70
            ) {

                albumArtwork

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

            // MARK: - Barra de progreso

            progressSection
                .offset(y: 45)

            Spacer(minLength: 30)

            // MARK: - Controles

            playbackControls
                .offset(y: 45)

            Spacer(minLength: 15)
        }
        .padding(.vertical, 20)
        .task {
            await startPlayback()
        }
        .onReceive(timer) { _ in

            guard isPlaying else {
                return
            }

            guard totalTime > 0 else {
                return
            }

            /*
             Durante un seek no dejamos que el temporizador
             compita con el valor que está seleccionando
             el usuario.

             La operación de seek vuelve a liberar este estado
             inmediatamente después de enviar el comando.
             */

            guard !isSeeking else {
                return
            }

            guard currentTime < totalTime else {
                return
            }

            /*
             El timer corre cada 0.25 segundos, por lo que
             avanzamos proporcionalmente.

             Esto hace que la barra se vea mucho más fluida
             que incrementándola únicamente cada 1 segundo.
             */

            currentTime = min(
                currentTime + 0.25,
                totalTime
            )
        }
    }

    // MARK: - Artwork

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
                    .aspectRatio(
                        contentMode: .fill
                    )

            case .failure:

                artworkPlaceholder

            @unknown default:

                artworkPlaceholder
            }
        }
        .frame(
            width: 680,
            height: 680
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 24
            )
        )
        .shadow(
            color: .black.opacity(0.45),
            radius: 30,
            x: 0,
            y: 16
        )
    }

    private var artworkPlaceholder: some View {

        ZStack {

            RoundedRectangle(
                cornerRadius: 24
            )
            .fill(
                Color.white.opacity(0.08)
            )

            Image(
                systemName: "music.note"
            )
            .font(
                .system(size: 80)
            )
            .foregroundStyle(
                .secondary
            )
        }
    }

    // MARK: - Track information

    private var trackInformation: some View {

        VStack(
            alignment: .leading,
            spacing: 16
        ) {

            if let currentTrack =
                networkClient.currentTrack {

                Text(
                    currentTrack.title ??
                    "Sin título"
                )
                .font(
                    .system(
                        size: 58,
                        weight: .bold
                    )
                )
                .foregroundStyle(.white)
                .lineLimit(2)

                Text(
                    currentTrack.artist ??
                    album.artist
                )
                .font(
                    .system(
                        size: 38,
                        weight: .medium
                    )
                )
                .foregroundStyle(
                    Color.white.opacity(0.72)
                )
                .lineLimit(1)

                Text(
                    currentTrack.album ??
                    album.title
                )
                .font(
                    .system(
                        size: 30,
                        weight: .regular
                    )
                )
                .foregroundStyle(
                    Color.white.opacity(0.52)
                )
                .lineLimit(1)

                if let year =
                    currentTrack.year,
                   !year.isEmpty {

                    Text(year)
                        .font(
                            .system(
                                size: 24,
                                weight: .regular
                            )
                        )
                        .foregroundStyle(
                            Color.white.opacity(0.42)
                        )
                }

                technicalInformation

            } else {

                Text(album.title)
                    .font(
                        .system(
                            size: 58,
                            weight: .bold
                        )
                    )
                    .foregroundStyle(.white)
                    .lineLimit(2)

                Text(album.artist)
                    .font(
                        .system(
                            size: 38,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(
                        Color.white.opacity(0.72)
                    )
                    .lineLimit(1)

                Text("Cargando...")
                    .font(
                        .system(
                            size: 30,
                            weight: .regular
                        )
                    )
                    .foregroundStyle(
                        Color.white.opacity(0.45)
                    )
            }
        }
        .frame(
            width: 650,
            alignment: .leading
        )
    }

    // MARK: - Technical information

    @ViewBuilder
    private var technicalInformation: some View {

        if let track =
            currentLMSTrack {

            let codec =
                track.fileType?
                    .lowercased() == "flc"
                ? "FLAC"
                : (
                    track.fileType?
                        .uppercased() ?? ""
                )

            let parts =
                [
                    codec,
                    track.sampleSize ?? "",
                    track.sampleRate ?? "",
                    track.bitrate ?? ""
                ]
                .filter {
                    !$0.isEmpty
                }

            if !parts.isEmpty {

                Text(
                    parts.joined(
                        separator: " • "
                    )
                )
                .font(
                    .system(
                        size: 18,
                        weight: .regular
                    )
                )
                .foregroundStyle(
                    Color.white.opacity(0.38)
                )
                .padding(.top, 8)
            }
        }
    }

    // MARK: - Current LMSTrack

    private var currentLMSTrack: LMSTrack? {

        guard
            let currentTrack =
                networkClient.currentTrack
        else {
            return nil
        }

        return networkClient.tracks.first {
            $0.title == currentTrack.title
        }
    }

    // MARK: - Progress

    private var progressSection: some View {

        HStack(
            spacing: 24
        ) {

            Text(
                formatTime(currentTime)
            )
            .font(
                .system(
                    size: 18
                )
            )
            .foregroundStyle(
                Color.white.opacity(0.55)
            )
            .frame(
                width: 70,
                alignment: .leading
            )

            GeometryReader { geometry in

                let progress =
                    totalTime > 0
                    ? min(
                        max(
                            currentTime /
                                totalTime,
                            0
                        ),
                        1
                    )
                    : 0

                ZStack(
                    alignment: .leading
                ) {

                    Capsule()
                        .fill(
                            Color.white.opacity(
                                0.18
                            )
                        )
                        .frame(
                            height: 6
                        )

                    Capsule()
                        .fill(
                            isProgressFocused
                            ? Color.white.opacity(
                                0.60
                            )
                            : Color.accentColor
                        )
                        .frame(
                            width:
                                geometry.size.width *
                                progress,
                            height: 6
                        )

                    Rectangle()
                        .fill(.white)
                        .frame(
                            width: 2,
                            height:
                                isProgressFocused
                                ? 22
                                : 18
                        )
                        .offset(
                            x:
                                geometry.size.width *
                                progress
                        )
                }
                .frame(
                    height: 24
                )
                .animation(
                    .interactiveSpring(
                        response: 0.15,
                        dampingFraction: 0.85
                    ),
                    value: currentTime
                )
            }
            .frame(
                height: 24
            )
            .focusable(true)
            .focused(
                $isProgressFocused
            )
            .onChange(
                of: isProgressFocused
            ) { _, focused in

                if focused {

                    isSeeking = true

                } else {

                    /*
                     Si el usuario abandona el foco
                     después de mover la barra, aseguramos
                     que el timer vuelva a tomar el control.
                     */

                    isSeeking = false
                }
            }
            .onMoveCommand { direction in

                handleProgressMovement(
                    direction
                )
            }

            Text(
                formatTime(totalTime)
            )
            .font(
                .system(
                    size: 18
                )
            )
            .foregroundStyle(
                Color.white.opacity(0.55)
            )
            .frame(
                width: 70,
                alignment: .trailing
            )
        }
        .padding(
            .horizontal,
            75
        )
    }

    // MARK: - Progress movement

    private func handleProgressMovement(
        _ direction: MoveCommandDirection
    ) {

        switch direction {

        case .left:

            let target =
                max(
                    0,
                    currentTime - 10
                )

            /*
             Actualización inmediata de la UI.

             El usuario ve el nuevo punto de reproducción
             inmediatamente, sin esperar al servidor.
             */

            currentTime = target

            scheduleSeek(
                target
            )

        case .right:

            let target =
                min(
                    totalTime,
                    currentTime + 10
                )

            /*
             Actualización inmediata de la UI.
             */

            currentTime = target

            scheduleSeek(
                target
            )

        default:

            break
        }
    }

    // MARK: - Seek scheduling

    private func scheduleSeek(
        _ seconds: TimeInterval
    ) {

        /*
         Cancelamos el seek anterior.

         Si el usuario pulsa varias veces rápidamente,
         no enviamos un comando al servidor por cada
         pulsación.
         */

        seekTask?.cancel()

        isSeeking = true

        seekTask = Task {

            /*
             Debounce corto.

             150 ms mantiene la sensación inmediata
             pero evita una avalancha de comandos LMS.
             */

            try? await Task.sleep(
                for: .milliseconds(150)
            )

            guard
                !Task.isCancelled
            else {
                return
            }

            await networkClient.sendCommand(
                targetPlayer: playerMAC,
                command: [
                    "time",
                    String(
                        Int(seconds)
                    )
                ]
            )

            guard
                !Task.isCancelled
            else {
                return
            }

            /*
             El comando ya fue enviado.

             El temporizador vuelve a controlar
             el avance visual del tiempo.
             */

            await MainActor.run {

                seekTask = nil
                isSeeking = false
            }
        }
    }

    // MARK: - Playback controls

    private var playbackControls: some View {

        HStack(
            spacing: 55
        ) {

            // Previous

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
                    .system(
                        size: 28,
                        weight: .medium
                    )
                )
                .frame(
                    width: 64,
                    height: 64
                )
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.circle)
            .tint(
                Color.white.opacity(0.12)
            )
            .foregroundStyle(.white)

            // Play / Pause

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
                    .system(
                        size: 34,
                        weight: .semibold
                    )
                )
                .frame(
                    width: 82,
                    height: 82
                )
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.circle)
            .tint(
                Color.white.opacity(0.18)
            )
            .foregroundStyle(.white)

            // Next

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
                    .system(
                        size: 28,
                        weight: .medium
                    )
                )
                .frame(
                    width: 64,
                    height: 64
                )
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.circle)
            .tint(
                Color.white.opacity(0.12)
            )
            .foregroundStyle(.white)
        }
    }

    // MARK: - Start playback

    private func startPlayback() async {

        isStartingPlayback = true

        await networkClient.fetchTracks(
            targetPlayer: playerMAC,
            albumID: album.id
        )

        guard
            !networkClient.tracks.isEmpty
        else {

            isStartingPlayback = false
            return
        }

        let initialIndex =
            max(
                startIndex,
                0
            )

        await networkClient.sendCommand(
            targetPlayer: playerMAC,
            command: [
                "playlistcontrol",
                "cmd:load",
                "album_id:\(album.id)",
                "play_index:\(initialIndex)"
            ]
        )

        try? await Task.sleep(
            for: .milliseconds(400)
        )

        // -------------------------------------------------
        // Configurar shuffle
        //
        // 0 = orden normal
        // 1 = canciones aleatorias
        // -------------------------------------------------

        let shuffleValue =
            shuffle
            ? "1"
            : "0"

        await networkClient.sendCommand(
            targetPlayer: playerMAC,
            command: [
                "playlist",
                "shuffle",
                shuffleValue
            ]
        )

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

        try? await Task.sleep(
            for: .milliseconds(400)
        )

        await refreshPlayerState()

        isStartingPlayback = false
    }

    // MARK: - Refresh player state

    private func refreshPlayerState() async {

        await networkClient.fetchCurrentTrackInfo(
            targetPlayer: playerMAC
        )

        isPlaying =
            networkClient.currentTrack != nil

        if let track =
            networkClient.currentTrack {

            if let duration =
                track.duration,
               duration > 0 {

                totalTime = duration
            }
        }

        /*
         IMPORTANTE:

         No intentamos actualizar currentTime desde
         LMSCurrentTrack porque ese modelo no contiene
         una propiedad `time`.

         El tiempo transcurrido se mantiene mediante
         el timer local y los seeks realizados por
         el usuario.
         */
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

    // MARK: - Previous

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

        /*
         Reiniciamos la posición visual porque
         hemos cambiado de pista.

         El refresh obtiene la nueva pista y duración.
         */

        currentTime = 0

        await refreshPlayerState()
    }

    // MARK: - Next

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

        /*
         Reiniciamos la posición visual porque
         hemos cambiado de pista.
         */

        currentTime = 0

        await refreshPlayerState()
    }

    // MARK: - Time formatting

    private func formatTime(
        _ seconds: TimeInterval
    ) -> String {

        let totalSeconds =
            max(
                0,
                Int(seconds)
            )

        let minutes =
            totalSeconds / 60

        let remainingSeconds =
            totalSeconds % 60

        return String(
            format: "%d:%02d",
            minutes,
            remainingSeconds
        )
    }
}
