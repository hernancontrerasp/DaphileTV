import SwiftUI

struct PlayerPickerView: View {

    @EnvironmentObject private var appState:
        AppState

    @Environment(\.dismiss)
    private var dismiss

    var body: some View {

        List {

            ForEach(
                appState.daphileClient
                    .availablePlayers
            ) { player in

                Button {

                    appState.selectedPlayerID =
                        player.playerid

                    appState.selectedPlayerName =
                        player.name

                    appState.saveConfiguration()

                    dismiss()

                } label: {

                    HStack(spacing: 20) {

                        Image(
                            systemName:
                                player.playerid ==
                                appState.selectedPlayerID
                                ? "checkmark.circle.fill"
                                : "speaker.wave.2.fill"
                        )
                        .font(.title2)

                        Text(player.name)
                            .font(.title3)

                        Spacer()
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle(
            "Seleccionar player"
        )
        .task {

            if appState.daphileClient
                .availablePlayers.isEmpty {

                _ = await appState
                    .daphileClient
                    .fetchAllPlayers()
            }
        }
    }
}
