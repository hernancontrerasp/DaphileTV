import SwiftUI

struct MaterialMenuCard: View {
    let title: String
    let icon: String
    var backgroundColor: Color = Color.secondary.opacity(0.2)
    
    var body: some View {
        VStack(spacing: 18) { // Un poco más de espacio entre imagen y texto
            ZStack {
                backgroundColor
                    // CLAVE: Subimos el tamaño de la tarjeta de 160 a 200
                    .frame(width: 200, height: 200)
                    .cornerRadius(24) // Suavizamos un poco más los bordes para el nuevo tamaño
                
                Image(systemName: icon)
                    // CLAVE: Subimos el tamaño del ícono proporcionalmente
                    .font(.system(size: 75))
                    .foregroundStyle(.primary)
            }
            .hoverEffectDisabled()
            
            Text(title)
                // Ajustamos ligeramente el tamaño de fuente y el ancho del contenedor de texto
                .font(.system(size: 24, weight: .regular))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(width: 220)
        }
        .padding(.vertical, 12)
    }
}
