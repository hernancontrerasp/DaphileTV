import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var appState: AppState
    
    // Categoría seleccionada en el menú lateral
    @State private var selectedCategory: LibraryCategory = .artists
    
    // Control de enfoque principal (Sidebar vs Contenido)
    @FocusState private var focusedArea: LibraryFocusArea?
    
    enum LibraryCategory: String, Hashable, CaseIterable {
        case recent = "Agregados recién"
        case playlists = "Playlists"
        case artists = "Artistas"
        case albums = "Álbumes"
        case tracks = "Canciones"
        case composers = "Compositores"
        case compilations = "Recopilaciones"
    }
    
    enum LibraryFocusArea: Hashable {
        case sidebar(LibraryCategory)
        case content
        case actionButton(String) // Reproducir, Aleatorio, etc.
    }

    var body: some View {
        HStack(alignment: .top, spacing: 40) {
            
            // MARK: - 1. SIDEBAR LATERAL IZQUIERDO
            VStack(alignment: .leading, spacing: 25) {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 10) {
                        
                        // Sección Principal
                        ForEach(LibraryCategory.allCases, id: \.self) { category in
                            Button {
                                selectedCategory = category
                            } label: {
                                HStack(spacing: 15) {
                                    Image(systemName: icon(for: category))
                                        .font(.system(size: 20))
                                        .frame(width: 30)
                                    
                                    Text(category.rawValue)
                                        .font(.system(size: 22, weight: selectedCategory == category ? .bold : .medium))
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedCategory == category ? Color.secondary.opacity(0.25) : Color.clear)
                                )
                            }
                            .buttonStyle(CardButtonStyle()) // Usamos nuestro estilo limpio sin bordes blancos
                            .focused($focusedArea, equals: .sidebar(category))
                        }
                        
                        Divider()
                            .padding(.vertical, 15)
                        
                        // Sección Géneros (Ejemplo visual como en la foto)
                        Text("Géneros")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 20)
                        
                        ForEach(["Adult Alternative", "Alternative", "Rock", "Jazz"], id: \.self) { genre in
                            Button {
                                // Acción para filtrar por género
                            } label: {
                                Text(genre)
                                    .font(.system(size: 20))
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(CardButtonStyle())
                        }
                    }
                }
            }
            .frame(width: 380)
            .padding(.top, 20)
            .focusSection()
            
            // MARK: - 2. PANEL PRINCIPAL DERECHO (CONTENIDO)
            VStack(alignment: .leading, spacing: 30) {
                
                // Cabecera y Botones de Acción (Reproducir / Aleatorio)
                HStack(alignment: .center, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(selectedCategory.rawValue)
                            .font(.system(size: 40, weight: .bold))
                            .foregroundStyle(.primary)
                        
                        Text(subtitle(for: selectedCategory))
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    // Botones de acción rápida superior
                    HStack(spacing: 16) {
                        Button {
                            // Acción Reproducir Todo
                        } label: {
                            Label("Reproducir", systemImage: "play.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(CardButtonStyle())
                        
                        Button {
                            // Acción Aleatorio
                        } label: {
                            Label("Aleatorio", systemImage: "shuffle")
                                .font(.system(size: 20, weight: .semibold))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(CardButtonStyle())
                    }
                }
                .padding(.trailing, 60)
                
                // Contenido dinámico según la categoría seleccionada
                Group {
                    switch selectedCategory {
                    case .artists:
                        // Reutilizamos nuestra vista de artistas adaptada al panel derecho
                        ArtistsListView()
                    case .albums:
                        Text("Vista de Álbumes en construcción...")
                            .foregroundStyle(.secondary)
                    case .playlists:
                        Text("Vista de Playlists en construcción...")
                            .foregroundStyle(.secondary)
                    default:
                        Text("Contenido de \(selectedCategory.rawValue)")
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .frame(maxWidth: .infinity)
            .focusSection()
        }
        .padding(.horizontal, 50)
    }
    
    // Helper para los íconos del sidebar
    private func icon(for category: LibraryCategory) -> String {
        switch category {
        case .recent: return "clock"
        case .playlists: return "music.note.list"
        case .artists: return "mic.fill"
        case .albums: return "square.stack"
        case .tracks: return "music.note"
        case .composers: return "music.quarternote.3"
        case .compilations: return "square.grid.2x2"
        }
    }
    
    // Subtítulo dinámico para mostrar contadores reales
    private func subtitle(for category: LibraryCategory) -> String {
        switch category {
        case .artists:
            return "\(appState.daphileClient.artistsList.count) artistas"
        case .albums:
            return "\(appState.daphileClient.albums.count) álbumes"
        default:
            return "Biblioteca local"
        }
    }
}
