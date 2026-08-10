import Foundation
import Combine

@MainActor
final class AppState: ObservableObject {

    // MARK: - Configuration

    @Published var serverIP: String
    @Published var selectedPlayerID: String
    @Published var selectedPlayerName: String

    // MARK: - Client

    let daphileClient: DaphileClient

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init() {

        let savedServerIP = UserDefaults.standard.string(
            forKey: "daphile_server_ip"
        ) ?? "192.168.1.90"

        let savedPlayerID = UserDefaults.standard.string(
            forKey: "daphile_player_mac"
        ) ?? ""

        let savedPlayerName = UserDefaults.standard.string(
            forKey: "daphile_player_name"
        ) ?? "Ninguno"

        self.serverIP = savedServerIP
        self.selectedPlayerID = savedPlayerID
        self.selectedPlayerName = savedPlayerName

        self.daphileClient = DaphileClient(
            serverIP: savedServerIP
        )

        daphileClient.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        Task {
            await daphileClient.fetchAlbums()
        }
    }

    // MARK: - Persistence

    func saveConfiguration() {

        UserDefaults.standard.set(
            serverIP,
            forKey: "daphile_server_ip"
        )

        UserDefaults.standard.set(
            selectedPlayerID,
            forKey: "daphile_player_mac"
        )

        UserDefaults.standard.set(
            selectedPlayerName,
            forKey: "daphile_player_name"
        )
    }
}
