import SwiftUI

struct ArtistCardView: View {
    let artist: LMSArtistItem
    let serverIP: String
    let isFocused: Bool
    
    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            
            AsyncImage(url: artist.pictureURL(serverIP: serverIP)) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                        ProgressView()
                    }
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                        Image(systemName: "person.fill")
                            .font(.system(size: 55))
                            .foregroundStyle(.secondary)
                    }
                @unknown default:
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                }
            }
            .aspectRatio(1.0, contentMode: .fit)
            .clipShape(Circle())
            // Efecto de borde luminoso (halo) cuando está en foco
            .overlay(
                Circle()
                    .stroke(isFocused ? Color.white.opacity(0.9) : Color.clear, lineWidth: 5)
            )
            // Sombra profunda y difuminada que acentúa la sensación de iluminación en los bordes
            .shadow(color: isFocused ? Color.white.opacity(0.4) : Color.black.opacity(0.3),
                    radius: isFocused ? 25 : 5,
                    x: 0,
                    y: isFocused ? 12 : 4)
            .hoverEffectDisabled()
            
            MarqueeArtistText(
                text: artist.name,
                font: .system(size: 30, weight: isFocused ? .bold : .medium),
                color: isFocused ? Color.accentColor : Color.primary,
                isAnimating: isFocused
            )
            .frame(maxWidth: .infinity)
        }
        // Incrementamos la escala de enfoque a 1.16 para que el crecimiento sea mucho más notorio
        .scaleEffect(isFocused ? 1.16 : 1.0)
        .animation(.easeOut(duration: 0.2), value: isFocused)
    }
}

// MARK: - Marquesina Específica para Nombres de Artistas
struct MarqueeArtistText: View {
    let text: String
    let font: Font
    let color: Color
    let isAnimating: Bool
    
    @State private var textWidth: CGFloat = 0
    @State private var offset: CGFloat = 0
    
    var body: some View {
        GeometryReader { containerProxy in
            let availableWidth = containerProxy.size.width
            let isLongText = textWidth > availableWidth
            
            ZStack(alignment: .leading) {
                Text(text)
                    .font(font)
                    .fixedSize(horizontal: true, vertical: false)
                    .background(
                        GeometryReader { textProxy in
                            Color.clear
                                .onAppear { textWidth = textProxy.size.width }
                                .onChange(of: text) { _, _ in
                                    textWidth = textProxy.size.width
                                }
                        }
                    )
                    .hidden()
                
                Group {
                    if isLongText && isAnimating {
                        HStack(spacing: 40) {
                            Text(text)
                                .fixedSize(horizontal: true, vertical: false)
                            Text(text)
                                .fixedSize(horizontal: true, vertical: false)
                        }
                        .offset(x: offset)
                        .onAppear {
                            startAnimation(contentWidth: textWidth)
                        }
                        .onChange(of: isAnimating) { _, focusing in
                            if focusing {
                                startAnimation(contentWidth: textWidth)
                            } else {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    offset = 0
                                }
                            }
                        }
                    } else {
                        Text(text)
                            .font(font)
                            .foregroundStyle(color)
                            .lineLimit(1)
                            .frame(width: availableWidth, alignment: isLongText ? .leading : .center)
                    }
                }
            }
            .frame(width: availableWidth, alignment: isLongText && isAnimating ? .leading : (isLongText ? .leading : .center))
        }
        .frame(height: 40)
        .font(font)
        .foregroundStyle(color)
        .clipped()
    }
    
    private func startAnimation(contentWidth: CGFloat) {
        offset = 0
        let distance = contentWidth + 40
        let speed: Double = 55.0
        let duration = Double(distance) / speed
        
        withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
            offset = -distance
        }
    }
}
