import SwiftUI

struct MyMusicView: View {
    @EnvironmentObject private var appState: AppState
    
    let columns = [
        GridItem(.adaptive(minimum: 260, maximum: 300), spacing: 40)
    ]
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 50) {
                
                Text("Mi Música")
                    .font(.system(size: 45, weight: .bold))
                    // CLAVE: Usar .primary en lugar de .white
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 60)
                    .padding(.top, 40)
                
                // MARK: - SECCIÓN 1: BY ARTIST
                MenuSectionView(title: "By Artist", icon: "person.2.crop.square.stack.fill", columns: columns) {
                    NavigationLink {
                        // Conectamos la vista de artistas usando el estado global
                        ArtistsListView()
                            .environmentObject(appState)
                    } label: {
                        MaterialMenuCard(title: "Artistas", icon: "person.circle.fill")
                    }
                    .buttonStyle(CardButtonStyle()) // Mantiene nuestra animación limpia sin bordes blancos
                }
                
                // MARK: - SECCIÓN 2: BY ALBUM
                MenuSectionView(title: "By Album", icon: "opticaldisc", columns: columns) {
                    NavigationLink {
                        Text("Vista de Álbumes")
                    } label: {
                        MaterialMenuCard(title: "Álbumes", icon: "record.circle")
                    }
                    .buttonStyle(CardButtonStyle())
                    
                    NavigationLink {
                        Text("Vista Aleatoria")
                    } label: {
                        MaterialMenuCard(title: "Álbumes aleatorios", icon: "dice.fill")
                    }
                    .buttonStyle(CardButtonStyle())
                    
                    NavigationLink {
                        Text("Vista Works")
                    } label: {
                        MaterialMenuCard(title: "Works", icon: "tuningfork")
                    }
                    .buttonStyle(CardButtonStyle())
                    
                    NavigationLink {
                        Text("Vista Música Nueva")
                    } label: {
                        MaterialMenuCard(title: "Música nueva", icon: "star.square.fill")
                    }
                    .buttonStyle(CardButtonStyle())
                }
                
                // MARK: - SECCIÓN 3: OTRO
                MenuSectionView(title: "Otro", icon: "music.note", columns: columns) {
                    NavigationLink {
                        Text("Vista Géneros")
                    } label: {
                        MaterialMenuCard(title: "Géneros", icon: "guitars.fill")
                    }
                    .buttonStyle(CardButtonStyle())
                    
                    NavigationLink {
                        Text("Vista Años")
                    } label: {
                        MaterialMenuCard(title: "Años", icon: "calendar")
                    }
                    .buttonStyle(CardButtonStyle())
                    
                    NavigationLink {
                        Text("Vista Listas")
                    } label: {
                        MaterialMenuCard(title: "Listas de Reproducción", icon: "music.note.list")
                    }
                    .buttonStyle(CardButtonStyle())
                }
            }
            .padding(.bottom, 60)
        }
        // Eliminado el .background(Color.black) para respetar el tema del usuario
    }
}

// MARK: - Componentes de la vista

struct MenuSectionView<Content: View>: View {
    let title: String
    let icon: String
    let columns: [GridItem]
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(.blue)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 60)
            
            LazyVGrid(columns: columns, spacing: 30) {
                content()
            }
            .padding(.horizontal, 60)
        }
    }
}
