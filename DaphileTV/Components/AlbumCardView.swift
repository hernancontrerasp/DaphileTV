import SwiftUI

struct AlbumCardView: View {
    let album: LMSAlbum
    let serverIP: String
    let isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            AsyncImage(url: album.artworkURL(serverIP: serverIP)) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.2))
                        ProgressView()
                    }
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.2))
                        Image(systemName: "music.note")
                            .font(.system(size: 45))
                            .foregroundStyle(.secondary)
                    }
                @unknown default:
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                }
            }
            .aspectRatio(1.0, contentMode: .fit)
            .cornerRadius(12)
            // Efecto de borde luminoso (halo) en la carátula cuando está en foco
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isFocused ? Color.white.opacity(0.9) : Color.clear, lineWidth: 5)
            )
            // Sombra con resplandor luminoso al enfocar
            .shadow(color: isFocused ? Color.white.opacity(0.4) : Color.black.opacity(0.35),
                    radius: isFocused ? 25 : 6,
                    x: 0,
                    y: isFocused ? 12 : 5)
            .hoverEffectDisabled()
            
            VStack(alignment: .center, spacing: 6) {
                MarqueeText(
                    text: album.title,
                    font: .system(size: 34, weight: isFocused ? .semibold : .regular),
                    color: isFocused ? Color.accentColor : Color.primary,
                    isAnimating: isFocused
                )
                
                if let year = album.year, year > 0 {
                    Text(String(year))
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(isFocused ? Color.primary : Color.secondary)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .scaleEffect(isFocused ? 1.14 : 1.0)
        .animation(.easeOut(duration: 0.2), value: isFocused)
    }
}

// MARK: - Marquesina Segura y Precisa para tvOS
struct MarqueeText: View {
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
                        HStack(spacing: 50) {
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
        .frame(height: 45)
        .font(font)
        .foregroundStyle(color)
        .clipped()
    }
    
    private func startAnimation(contentWidth: CGFloat) {
        offset = 0
        let distance = contentWidth + 50
        let speed: Double = 60.0
        let duration = Double(distance) / speed
        
        withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
            offset = -distance
        }
    }
}

struct NoBackgroundButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}
