import SwiftUI

struct AlbumCardView: View {

    let album: LMSAlbum
    let serverIP: String
    let isFocused: Bool

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            AsyncImage(
                url: album.artworkURL(
                    serverIP: serverIP
                )
            ) { phase in

                switch phase {

                case .empty:

                    ZStack {

                        RoundedRectangle(
                            cornerRadius: 10
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
                            cornerRadius: 10
                        )
                        .fill(
                            Color.gray.opacity(0.2)
                        )

                        Image(
                            systemName:
                                "music.note"
                        )
                        .font(
                            .system(
                                size: 45
                            )
                        )
                        .foregroundStyle(
                            .secondary
                        )
                    }

                @unknown default:

                    RoundedRectangle(
                        cornerRadius: 10
                    )
                    .fill(
                        Color.gray.opacity(0.2)
                    )
                }
            }
            .frame(
                width: 220,
                height: 220
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 10
                )
            )

            Text(album.title)
                .font(
                    .system(
                        size: 22,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    .white
                )
                .lineLimit(1)

            Text(album.artist)
                .font(
                    .system(
                        size: 18
                    )
                )
                .foregroundStyle(
                    .white.opacity(0.65)
                )
                .lineLimit(1)
        }
        .frame(
            width: 220,
            alignment: .leading
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
        .frame(
            width: 240,
            height: 310
        )
    }
}
