import SwiftUI

struct PlayerPickerView: View {

    @EnvironmentObject private var appState:
        AppState

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 30
        ) {

            // MARK: - Título

            Text("Seleccionar player")
                .font(
                    .system(
                        size: 32,
                        weight: .semibold
                    )
                )
                .foregroundStyle(.primary)

            // MARK: - Players

            ScrollView(
                .vertical,
                showsIndicators: false
            ) {

                LazyVStack(
                    alignment: .leading,
                    spacing: 16
                ) {

                    ForEach(
                        appState
                            .daphileClient
                            .availablePlayers
                    ) { player in

                        Button {

                            appState.selectedPlayerID =
                                player.playerid

                            appState.selectedPlayerName =
                                player.name

                            appState.saveConfiguration()

                        } label: {

                            HStack(
                                spacing: 20
                            ) {

                                Image(
                                    systemName:
                                        player.playerid ==
                                        appState.selectedPlayerID
                                        ? "checkmark.circle.fill"
                                        : "speaker.wave.2.fill"
                                )
                                .font(
                                    .system(
                                        size: 28
                                    )
                                )

                                Text(player.name)
                                    .font(
                                        .system(
                                            size: 26,
                                            weight: .medium
                                        )
                                    )

                                Spacer()

                                if player.playerid ==
                                    appState.selectedPlayerID {

                                    Image(
                                        systemName:
                                            "checkmark"
                                    )
                                    .font(
                                        .system(
                                            size: 24,
                                            weight: .bold
                                        )
                                    )
                                }
                            }
                            .foregroundStyle(
                                .primary
                            )
                            .padding(
                                .horizontal,
                                24
                            )
                            .padding(
                                .vertical,
                                20
                            )
                            .frame(
                                maxWidth: .infinity,
                                alignment: .leading
                            )
                            .background {

                                RoundedRectangle(
                                    cornerRadius: 16
                                )
                                .fill(
                                    Color.white
                                        .opacity(
                                            player.playerid ==
                                            appState.selectedPlayerID
                                            ? 0.14
                                            : 0.06
                                        )
                                )
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .topLeading
        )
        .padding(
            .horizontal,
            35
        )
        .padding(
            .top,
            20
        )
        .task {

            if appState
                .daphileClient
                .availablePlayers
                .isEmpty {

                _ = await appState
                    .daphileClient
                    .fetchAllPlayers()
            }
        }
    }
}
