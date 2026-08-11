import SwiftUI

struct MainNavigationBar: View {

    enum Destination: Hashable {
        case home
        case nowPlaying
        case search
        case queue
        case player
        case library
    }

    @Binding var selection:
        Destination

    @Binding var focusDestinationRequest:
        Destination?

    let onDestinationFocused:
        (Destination) -> Void

    @FocusState private var focusedDestination:
        Destination?

    @State private var focusTask:
        Task<Void, Never>?

    private let focusDelay:
        UInt64 = 500_000_000

    private let items: [
        (
            destination: Destination,
            title: String
        )
    ] = [

        (.home, "Inicio"),

        (.nowPlaying, "En reproducción"),

        (.search, "Buscar"),
        
        (.library, "Biblioteca"),

        (.queue, "Cola de reproducción"),

        (.player, "Reproductor")
    ]
    
    // Nueva propiedad para saber si el menú está restringido a una sola opción
    var restrictedDestination: Destination? = nil

    var body: some View {

        HStack(spacing: 8) {

            ForEach(
                items,
                id: \.destination
            ) { item in
                let isEnabled = restrictedDestination == nil || restrictedDestination == item.destination

                Button {
                    guard isEnabled else { return }
                    selection = item.destination
                    scheduleDestinationAction(item.destination)
                } label: {
                    Text(item.title)
                        .font(
                            .system(
                                size: 29,
                                weight: .semibold
                            )
                        )
                        .foregroundStyle(

                            focusedDestination ==
                            item.destination

                            ? Color.black
                            : Color.white
                        )
                        .padding(
                            .horizontal,
                            26
                        )
                        .padding(
                            .vertical,
                            14
                        )
                        .frame(
                            minHeight: 62
                        )
                        .background {

                            Capsule()
                                .fill(

                                    focusedDestination ==
                                    item.destination

                                    ? Color.white
                                        .opacity(0.95)

                                    : Color.clear
                                )
                        }
                }
                .buttonStyle(.plain)
                .focusEffectDisabled()
                .focused(
                    $focusedDestination,
                    equals:
                        item.destination
                )
                // CLAVE: Si hay restricción y no es la opción activa, deshabilitamos el foco en este botón
                .disabled(!isEnabled)
                .opacity(isEnabled ? 1.0 : 0.4) // Opcional: Atenuar visualmente las opciones bloqueadas
            }
        }
        .padding(
            .horizontal,
            14
        )
        .padding(
            .vertical,
            8
        )
        .background {

            Capsule()
                .fill(
                    Color.white.opacity(0.12)
                )
        }
        .overlay {

            Capsule()
                .stroke(
                    Color.white.opacity(0.18),
                    lineWidth: 1
                )
        }
        .padding(.top, 0)
        .padding(.bottom, 24)

        .onAppear {

            focusedDestination =
                .home

            selection =
                .home
        }

        // MARK: - Cambio de foco

        .onChange(
            of: focusedDestination
        ) { _, newDestination in

            guard let newDestination else {

                cancelFocusTask()

                return
            }

            scheduleDestinationAction(
                newDestination
            )
        }

        // MARK: - Solicitud de foco

        .onChange(
            of: focusDestinationRequest
        ) { _, requestedDestination in

            guard
                let requestedDestination
            else {
                return
            }

            cancelFocusTask()

            focusedDestination =
                requestedDestination

            selection =
                requestedDestination

            focusDestinationRequest =
                nil
        }

        .onDisappear {

            cancelFocusTask()
        }
    }

    // MARK: - Focus Delay

    private func scheduleDestinationAction(
        _ destination: Destination
    ) {

        cancelFocusTask()

        focusTask = Task {

            do {

                try await Task.sleep(
                    nanoseconds:
                        focusDelay
                )

            } catch {

                return
            }

            guard
                !Task.isCancelled
            else {
                return
            }

            await MainActor.run {

                guard
                    focusedDestination ==
                        destination
                else {
                    return
                }

                onDestinationFocused(
                    destination
                )
            }
        }
    }

    private func cancelFocusTask() {

        focusTask?.cancel()
        focusTask = nil
    }
}
