import SwiftUI

// MARK: - Reorder Stack (horizontal strips + shake, long-press on card opens this sheet)
struct ReorderStackView: View {
    @Binding var documents: [TravelDocument]
    var highlightedDocumentID: UUID?
    /// Order as shown on the homescreen stack (top to bottom) so the list mirrors it.
    var initialOrder: [UUID]
    var onDismiss: () -> Void
    
    private var activeDocuments: [TravelDocument] {
        documents.filter { $0.isActive }
    }
    
    @State private var orderedIDs: [UUID] = []
    @State private var contentAppeared = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        GeometryReader { geo in
            let rowCount = max(orderedIDs.count, 1)
            let listAreaHeight = geo.size.height - 168
            let rowHeight = min(86, max(56, (listAreaHeight - CGFloat(rowCount - 1) * 8) / CGFloat(rowCount)))
            
            ZStack {
                (colorScheme == .dark ? Color(red: 0.11, green: 0.11, blue: 0.12) : Color(red: 0.96, green: 0.96, blue: 0.97))
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Text("Stack order")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .padding(.top, 20)
                        .padding(.bottom, 8)
                    
                    Text("Drag to reorder")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 16)
                    
                    List {
                        ForEach(orderedIDs, id: \.self) { id in
                            if let doc = documents.first(where: { $0.id == id }) {
                                ReorderStripRow(
                                    doc: doc,
                                    isHighlighted: id == highlightedDocumentID,
                                    minHeight: rowHeight
                                )
                                .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                            }
                        }
                        .onMove { fromOffsets, toOffset in
                            orderedIDs.move(fromOffsets: fromOffsets, toOffset: toOffset)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .environment(\.editMode, .constant(.active))
                    .opacity(contentAppeared ? 1 : 0)
                    .scaleEffect(contentAppeared ? 1 : 0.98)
                    
                    Button(action: applyAndDismiss) {
                        Text("Done")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.primary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 34)
                }
            }
        }
        .onAppear {
            // Mirror the visible stack order (top-to-bottom) from the homescreen
            if !initialOrder.isEmpty && Set(initialOrder) == Set(activeDocuments.map(\.id)) {
                orderedIDs = initialOrder
            } else {
                orderedIDs = activeDocuments.map(\.id)
            }
            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                contentAppeared = true
            }
        }
    }
    
    private func applyAndDismiss() {
        // Only update the stack order if the user actually reordered (don't touch order on "Done" with no changes)
        guard orderedIDs != initialOrder else {
            onDismiss()
            return
        }
        let inactive = documents.filter { !$0.isActive }
        // orderedIDs is [front, ..., back] (first row = front). Array order must be [back, ..., front] so sort-by-index-desc puts front first.
        let newActive = orderedIDs.reversed().compactMap { id in documents.first(where: { $0.id == id }) }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            documents = newActive + inactive
        }
        onDismiss()
    }
}

// Horizontal strip row with card colour + jiggle (iOS home screen–style edit shake)
struct ReorderStripRow: View {
    let doc: TravelDocument
    let isHighlighted: Bool
    var minHeight: CGFloat = 56
    
    // Phase offset so rows don't all shake in sync (derived from doc id)
    private var phase: Double {
        Double(doc.id.hashValue % 100) / 100.0 * .pi * 2
    }
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let jiggleAmount = sin(t * 20 + phase) * 0.65
            
            HStack(spacing: 14) {
                Image(systemName: doc.iconName)
                    .font(.system(size: 22))
                    .foregroundStyle(.white.opacity(0.95))
                    .frame(width: 32, alignment: .center)
                
                Text(doc.type.displayName)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(doc.primaryColor.opacity(0.92))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isHighlighted ? Color.accentColor : Color.clear, lineWidth: 2)
                    )
            )
            .rotationEffect(.degrees(jiggleAmount))
            .offset(x: jiggleAmount / 2, y: -jiggleAmount / 2)
        }
    }
}
