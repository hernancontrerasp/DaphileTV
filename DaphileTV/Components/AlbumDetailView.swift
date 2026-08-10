import SwiftUI

struct AlbumDetailView: View {

    let album: LMSAlbum
    let serverIP: String
    let playerMAC: String

    @ObservedObject var networkClient: DaphileClient

    @FocusState private var focusedTrackIndex: Int?

    var body: some View {

        HStack(
            alignment: .top,
            spacing: 50
        ) {

            // MARK: - Carátula

            VStack {

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
                    width: 680,
                    height: 680
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 24
                    )
                )
                .shadow(
                    color: .black.opacity(0.5),
                    radius: 35,
                    x: 0,
                    y: 20
                )

                Spacer()
            }
            .frame(width: 680)

            // MARK: - Información y canciones

            VStack(
                alignment: .leading,
                spacing: 0
            ) {

                // MARK: Información del álbum

                Text(album.title)
                    .font(
                        .system(
                            size: 55,
                            weight: .bold
                        )
                    )
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .padding(.bottom, 8)

                Text(album.artist)
                    .font(
                        .system(
                            size: 34,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .padding(.bottom, 6)

                HStack(spacing: 12) {

                    if let year = album.year,
                       year > 0 {

                        Text(String(year))

                        Text("•")
                    }

                    Text("Lossless")
                }
                .font(
                    .system(
                        size: 26,
                        weight: .regular
                    )
                )
                .foregroundStyle(
                    .secondary.opacity(0.6)
                )
                .padding(.bottom, 35)

                // MARK: Controles

                HStack(spacing: 25) {

                    // MARK: - Reproducir

                    NavigationLink {

                        PlayerFullScreenView(
                            album: album,
                            serverIP: serverIP,
                            playerMAC: playerMAC,
                            startIndex: 0,
                            shuffle: false,
                            networkClient: networkClient
                        )

                    } label: {

                        Label(
                            "Reproducir",
                            systemImage: "play.fill"
                        )
                        .frame(
                            width: 180,
                            height: 50
                        )
                    }
                    .buttonStyle(
                        .borderedProminent
                    )

                    // MARK: - Aleatorio

                    NavigationLink {

                        PlayerFullScreenView(
                            album: album,
                            serverIP: serverIP,
                            playerMAC: playerMAC,
                            startIndex: 0,
                            shuffle: true,
                            networkClient: networkClient
                        )

                    } label: {

                        Label(
                            "Aleatorio",
                            systemImage: "shuffle"
                        )
                        .frame(
                            width: 180,
                            height: 50
                        )
                    }
                    .buttonStyle(
                        .bordered
                    )
                }
                .padding(.bottom, 40)

                // MARK: Lista de canciones

                ScrollView(
                    .vertical,
                    showsIndicators: true
                ) {

                    VStack(spacing: 12) {

                        ForEach(
                            Array(
                                networkClient.tracks.enumerated()
                            ),
                            id: \.offset
                        ) { index, track in

                            trackRow(
                                index: index,
                                track: track
                            )
                        }
                    }
                    .padding(.vertical, 10)
                }
            }
        }
        .padding(5)
        .task {

            await networkClient.fetchTracks(
                targetPlayer: playerMAC,
                albumID: album.id
            )
        }
    }

    // MARK: - Fila de canción

    @ViewBuilder
    private func trackRow(
        index: Int,
        track: LMSTrack
    ) -> some View {

        NavigationLink {

            PlayerFullScreenView(
                album: album,
                serverIP: serverIP,
                playerMAC: playerMAC,
                startIndex: index,
                shuffle: false,
                networkClient: networkClient
            )

        } label: {

            HStack(spacing: 25) {

                Text("\(index + 1)")
                    .font(
                        .system(
                            size: 28,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(.secondary)
                    .frame(
                        width: 50,
                        alignment: .leading
                    )

                VStack(
                    alignment: .leading,
                    spacing: 2
                ) {

                    AlbumTrackMarquee(
                        text: track.title,
                        isFocused:
                            focusedTrackIndex == index
                    )

                    let displayCodec: String? = {

                        guard let ext = track.fileType
                        else {
                            return nil
                        }

                        return ext.lowercased() == "flc"
                            ? "FLAC"
                            : ext.uppercased()
                    }()

                    let technicalInfo = [
                        displayCodec,
                        track.sampleSize,
                        track.sampleRate,
                        track.bitrate
                    ]
                    .compactMap { $0 }
                    .joined(separator: " • ")

                    if !technicalInfo.isEmpty {

                        Text(technicalInfo)
                            .font(
                                .system(
                                    size: 18,
                                    weight: .light
                                )
                            )
                            .foregroundStyle(
                                .secondary.opacity(0.8)
                            )
                            .lineLimit(1)
                    }
                }
                .padding(.trailing, 80)

                Spacer()

                if let seconds = track.duration {

                    Text(
                        formatTime(seconds)
                    )
                    .font(
                        .system(
                            size: 26,
                            weight: .regular
                        )
                    )
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 25)
            .frame(height: 65)
        }
        .buttonStyle(.bordered)
        .focused(
            $focusedTrackIndex,
            equals: index
        )
    }

    // MARK: - Tiempo

    private func formatTime(
        _ seconds: TimeInterval
    ) -> String {

        let minutes = Int(seconds) / 60
        let seconds = Int(seconds) % 60

        return String(
            format: "%d:%02d",
            minutes,
            seconds
        )
    }
}

// MARK: - Marquesina de canción

private struct AlbumTrackMarquee: View {

    let text: String
    let isFocused: Bool

    @State private var textWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0

    private let speed: CGFloat = 45

    var body: some View {

        GeometryReader { geometry in

            ZStack(alignment: .leading) {

                Text(text)
                    .font(
                        .system(
                            size: 34,
                            weight: .regular
                        )
                    )
                    .lineLimit(1)
                    .fixedSize(
                        horizontal: true,
                        vertical: false
                    )
                    .background(
                        GeometryReader { textGeometry in

                            Color.clear
                                .onAppear {

                                    textWidth =
                                        textGeometry.size.width
                                }
                        }
                    )
                    .opacity(0)

                if isFocused &&
                    textWidth > containerWidth {

                    TimelineView(.animation) { timeline in

                        let baseSpace: CGFloat = 80

                        let totalLoopWidth =
                            textWidth + baseSpace

                        let time =
                            timeline.date
                                .timeIntervalSinceReferenceDate

                        let currentOffset =
                            -CGFloat(
                                time * speed
                            )
                            .truncatingRemainder(
                                dividingBy:
                                    totalLoopWidth
                            )

                        HStack(
                            spacing: baseSpace
                        ) {

                            Text(text)
                                .font(
                                    .system(
                                        size: 34,
                                        weight: .regular
                                    )
                                )
                                .lineLimit(1)
                                .fixedSize(
                                    horizontal: true,
                                    vertical: false
                                )

                            Text(text)
                                .font(
                                    .system(
                                        size: 34,
                                        weight: .regular
                                    )
                                )
                                .lineLimit(1)
                                .fixedSize(
                                    horizontal: true,
                                    vertical: false
                                )
                        }
                        .offset(
                            x: currentOffset
                        )
                    }

                } else {

                    Text(text)
                        .font(
                            .system(
                                size: 34,
                                weight: .regular
                            )
                        )
                        .lineLimit(1)
                }
            }
            .onAppear {

                containerWidth =
                    geometry.size.width
            }
        }
        .frame(height: 40)
        .clipped()
    }
}
