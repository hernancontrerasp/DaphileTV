import Foundation
import Combine

@MainActor
final class DaphileClient: ObservableObject {

    // MARK: - API

    private let api: DaphileAPI

    init(serverIP: String) {
        self.api = DaphileAPI(
            serverIP: serverIP
        )
    }

    // MARK: - Library

    @Published private(set) var albums: [LMSAlbum] = []
    @Published private(set) var tracks: [LMSTrack] = []
    @Published private(set) var artistsList: [LMSArtistItem] = []

    // MARK: - Players

    @Published private(set) var availablePlayers: [LMSPlayer] = []

    // MARK: - Player

    @Published private(set) var currentTrack: LMSCurrentTrack?

    @Published private(set) var playbackTime: TimeInterval = 0
    @Published private(set) var playbackDuration: TimeInterval = 0

    // MARK: - Apps / Plugins

    @Published private(set) var installedApps: [LMSAppItem] = []

    // MARK: - State

    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    // MARK: - Players

    func fetchAllPlayers() async -> [LMSPlayer] {

        do {
            let data = try await api.request(
                playerID: "0",
                command: [
                    "serverstatus",
                    "0",
                    "10"
                ]
            )

            let response = try JSONDecoder().decode(
                LMSPlayersResponse.self,
                from: data
            )

            let players =
                response.result?.playersLoop ?? []

            availablePlayers = players

            return players

        } catch {

            errorMessage =
                error.localizedDescription

            print(
                "Error descubriendo zonas: \(error.localizedDescription)"
            )

            return []
        }
    }

    // MARK: - Albums

    func fetchAlbums(
        forceReload: Bool = false
    ) async {

        if !forceReload && !albums.isEmpty {
            return
        }

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            let data = try await api.request(
                playerID: "",
                command: [
                    "albums",
                    "0",
                    "2000",
                    "tags:alyj"
                ]
            )

            let response = try JSONDecoder().decode(
                LMSResponse.self,
                from: data
            )

            albums =
                response.result.albumsLoop ?? []

            print(
                "Álbumes cargados: \(albums.count)"
            )

        } catch {

            errorMessage =
                error.localizedDescription

            print(
                "Error cargando álbumes: \(error.localizedDescription)"
            )
        }
    }

    // MARK: - Artists

    func fetchArtists(
        forceReload: Bool = false
    ) async {

        if !forceReload && !artistsList.isEmpty {
            return
        }

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            let data = try await api.request(
                playerID: "0",
                command: [
                    "artists",
                    "0",
                    "3000",
                    "tags:o"
                ]
            )

            let response =
                try JSONDecoder().decode(
                    LMSArtistsResponse.self,
                    from: data
                )

            artistsList =
                response.result.artistsLoop ?? []

        } catch {

            errorMessage =
                error.localizedDescription

            print(
                "Error cargando artistas: \(error.localizedDescription)"
            )
        }
    }

    // MARK: - Tracks

    func fetchTracks(
        targetPlayer: String,
        albumID: Int
    ) async {

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            let data = try await api.request(
                playerID:
                    targetPlayer.isEmpty
                    ? "0"
                    : targetPlayer,
                command: [
                    "tracks",
                    "0",
                    "100",
                    "tags:distbhz1kyuAACGPSorITYE",
                    "sort:tracknum",
                    "album_id:\(albumID)"
                ]
            )

            let response =
                try JSONDecoder().decode(
                    LMSTracksResponse.self,
                    from: data
                )

            let rawTracks =
                response.result.titlesLoop ?? []

            tracks =
                rawTracks.sorted {

                    let number1 =
                        Int($0.tracknum ?? "") ?? 0

                    let number2 =
                        Int($1.tracknum ?? "") ?? 0

                    return number1 < number2
                }

        } catch {

            errorMessage =
                error.localizedDescription

            print(
                "Error cargando canciones: \(error.localizedDescription)"
            )
        }
    }

    // MARK: - Current Track

    func fetchCurrentTrackInfo(
        targetPlayer: String
    ) async {

        guard !targetPlayer.isEmpty else {
            return
        }

        do {

            let data =
                try await api.request(
                    playerID: targetPlayer,
                    command: [
                        "status",
                        "-",
                        "1",
                        "tags:aYdj"
                    ]
                )

            let response =
                try JSONDecoder().decode(
                    LMSStatusResponse.self,
                    from: data
                )

            // -------------------------------------------------
            // Tiempo transcurrido
            //
            // El tiempo pertenece al resultado del status.
            // -------------------------------------------------

            playbackTime =
                response.result.time ?? 0

            // -------------------------------------------------
            // Canción actual
            // -------------------------------------------------

            guard var track =
                response.result.playlistLoop?.first
            else {

                currentTrack = nil
                playbackDuration = 0

                return
            }

            track.year =
                response.result.year

            currentTrack =
                track

            // -------------------------------------------------
            // Duración
            //
            // La duración pertenece a LMSCurrentTrack.
            // -------------------------------------------------

            playbackDuration =
                track.duration ?? 0

        } catch {

            errorMessage =
                error.localizedDescription

            print(
                "Error obteniendo el track actual: \(error.localizedDescription)"
            )
        }
    }

    // MARK: - Commands

    func sendCommand(
        targetPlayer: String,
        command: [String]
    ) async {

        guard !targetPlayer.isEmpty else {
            return
        }

        do {

            _ = try await api.request(
                playerID: targetPlayer,
                command: command
            )

            print(
                "Comando ejecutado en [\(targetPlayer)]: \(command)"
            )

        } catch {

            errorMessage =
                error.localizedDescription

            print(
                "Error ejecutando comando: \(error.localizedDescription)"
            )
        }
    }

    // MARK: - Apps

    func fetchApps(
        targetPlayer: String = ""
    ) async {

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        guard let url =
            api.pluginsURL
        else {

            errorMessage =
                DaphileError.invalidURL.localizedDescription

            return
        }

        var request =
            URLRequest(
                url: url
            )

        request.httpMethod =
            "GET"

        request.setValue(
            "application/json",
            forHTTPHeaderField:
                "Accept"
        )

        request.setValue(
            "Mozilla/5.0 (Apple TV)",
            forHTTPHeaderField:
                "User-Agent"
        )

        let configuration =
            URLSessionConfiguration.ephemeral

        configuration.timeoutIntervalForRequest =
            6.0

        let session =
            URLSession(
                configuration:
                    configuration
            )

        do {

            let (
                data,
                response
            ) =
                try await session.data(
                    for: request
                )

            guard
                let httpResponse =
                    response as? HTTPURLResponse,
                200..<300 ~=
                    httpResponse.statusCode
            else {

                throw DaphileError.invalidResponse
            }

            let decodedResponse =
                try JSONDecoder().decode(
                    LMSAppsResponse.self,
                    from: data
                )

            installedApps =
                decodedResponse.result.appsLoop ?? []

        } catch {

            errorMessage =
                error.localizedDescription

            print(
                "Error obteniendo plugins: \(error.localizedDescription)"
            )

            if installedApps.isEmpty {

                installedApps = [

                    LMSAppItem(
                        name: "TIDAL",
                        cmd: "tidal",
                        icon:
                            "plugins/Tidal/html/images/icon.png"
                    )
                ]
            }
        }
    }

    // MARK: - Local Filtering

    func getFilteredAlbums(
        for artistName: String
    ) -> [LMSAlbum] {

        let normalizedArtist =
            artistName.folding(
                options: [
                    .diacriticInsensitive,
                    .caseInsensitive
                ],
                locale: .current
            )

        return albums.filter {
            album in

            let albumArtist =
                album.artist.folding(
                    options: [
                        .diacriticInsensitive,
                        .caseInsensitive
                    ],
                    locale: .current
                )

            return albumArtist ==
                normalizedArtist
        }
    }
}
