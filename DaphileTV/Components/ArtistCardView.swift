import SwiftUI

struct ArtistCardView: View {
    let artist: LMSArtistItem // Asegúrate de que el modelo coincida con tu LMSModels
    let serverIP: String
    let isFocused: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            AsyncImage(url: artist.pictureURL(serverIP: serverIP)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure, .empty:
                    ZStack {
                        Color.gray.opacity(0.15)
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 70))
                            .foregroundStyle(.secondary.opacity(0.4))
                    }
                @unknown default:
                    Color.gray.opacity(0.15)
                }
            }
            .frame(width: 230, height: 230)
            .clipShape(Circle())
            // Sombra suave que se ve genial en tvOS
            .shadow(color: .black.opacity(0.35), radius: 6, x: 0, y: 5)
            // CLAVE: Evita el halo del sistema sobre el círculo
            .hoverEffectDisabled()
            
            Text(artist.name)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 230, height: 55, alignment: .top)
        }
        // Tu animación de escala personalizada al enfocar
        .scaleEffect(isFocused ? 1.08 : 1.0)
        .animation(.easeOut(duration: 0.15), value: isFocused)
        .frame(width: 250, height: 320)
    }
}
