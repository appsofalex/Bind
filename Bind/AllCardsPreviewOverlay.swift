import SwiftUI

// MARK: - All Cards Preview Overlay (opens card from list with full controls, returns to list on exit)
struct AllCardsPreviewOverlay: View {
    let document: TravelDocument
    let onDismiss: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onShare: () -> Void
    
    @State private var isCardExpanded = false
    @State private var isDismissing = false
    @Environment(\.colorScheme) var colorScheme
    
    private func dismissCard() {
        guard !isDismissing else { return }
        isDismissing = true
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isCardExpanded = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            onDismiss()
        }
    }
    
    private var overlayBackground: some View {
        Group {
            if colorScheme == .dark {
                Color(red: 0.11, green: 0.11, blue: 0.12)
            } else {
                Color(red: 0.96, green: 0.96, blue: 0.97)
            }
        }
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                overlayBackground
                    .ignoresSafeArea()
                
                WalletCardView(document: document, isSelected: isCardExpanded, onTap: dismissCard)
                    .frame(width: geo.size.width - 40)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .scaleEffect(isCardExpanded ? 1.0 : 0.85)
                    .shadow(
                        color: colorScheme == .dark ? .clear : .black.opacity(0.3),
                        radius: colorScheme == .dark ? 0 : 15,
                        x: 0,
                        y: colorScheme == .dark ? 0 : 10
                    )
                
                VStack {
                    HStack {
                        Button(action: onShare) {
                            Image(systemName: "square.and.arrow.up.circle.fill")
                                .font(.system(size: 32))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.white)
                                .background(Color.black.opacity(0.5).clipShape(Circle()))
                        }
                        Spacer()
                        Menu {
                            Button { onEdit() } label: {
                                Label("Edit Card", systemImage: "pencil")
                            }
                            Button(role: .destructive) { onDelete() } label: {
                                Label("Remove Card", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle.fill")
                                .font(.system(size: 32))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.white)
                                .background(Color.black.opacity(0.5).clipShape(Circle()))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 50)
                    Spacer()
                }
                
                VStack {
                    Spacer()
                    Button(action: dismissCard) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 50))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.white)
                            .background(Color.black.opacity(0.5).clipShape(Circle()))
                    }
                    .padding(.bottom, 50)
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    isCardExpanded = true
                }
            }
        }
    }
}
