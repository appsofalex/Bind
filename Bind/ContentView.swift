import SwiftUI

// MARK: - EMPTY WALLET VIEW (Extracted for reliable animation reset)
struct EmptyWalletView: View {
    @State private var animateArrow = false
    
    var body: some View {
        ZStack {
            // Text Content
            VStack(spacing: 15) {
                Spacer()
                
                Image(systemName: "wallet.pass")
                    .font(.system(size: 70))
                    .foregroundColor(.white.opacity(0.2))
                    .padding(.bottom, 10)
                
                Text("No Cards Yet")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.8))
                
                Text("Add your first document or booking to get started.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 50)
                
                Spacer()
                    .frame(height: 100)
                
                Spacer()
            }
            .zIndex(0)
            
            // Animated Pointing Arrow
            GeometryReader { geo in
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "arrow.up.right") // Using the curved arrow
                        .font(.system(size: 35, weight: .light))
                        .foregroundColor(.white.opacity(0.6))
                        .rotationEffect(.degrees(45))
                        // Animate position: Move left to right horizontally
                        .offset(x: animateArrow ? 15 : -15, y: 0)
                        .position(x: geo.size.width - 95, y: 71)
                }
            }
            .zIndex(1)
        }
        .onAppear {
            animateArrow = false // Reset state
            withAnimation(
                // Custom cubic-bezier for the repeating arrow animation
                .timingCurve(0.25, 0.1, 0.25, 1, duration: 1.0)
                .repeatForever(autoreverses: true)
            ) {
                animateArrow = true
            }
        }
    }
}

// MARK: - NEW: WALLET CARD CONTAINER (Extracted to resolve compiler type-checking issue)
// This view encapsulates the logic for displaying a single document card
// including its type-specific rendering and all positioning/animation modifiers.
struct WalletCardContainerView: View {
    let document: TravelDocument
    let isSelected: Bool
    let position: CGFloat // The calculated circular position for this card
    let totalScrollHeight: CGFloat // Total height for scroll calculations
    let activeDocumentsCount: Int // Number of active documents for offset centering
    let cardSpacing: CGFloat // Spacing between cards for calculations
    let onTap: () -> Void

    var body: some View {
        Group {
            if document.type == .passport {
                PassportFlipCard(
                    document: document,
                    isSelected: isSelected,
                    onTap: onTap
                )
            } else if document.type == .idCard || document.type == .driversLicense || document.type == .studentID {
                IDFlipCard(
                    document: document,
                    isSelected: isSelected,
                    onTap: onTap
                )
            } else if document.type == .boardingPass {
                BoardingPassAnimatedCard(
                    document: document,
                    isSelected: isSelected,
                    onTap: onTap
                )
            } else {
                DocumentCardView(document: document)
                    .onTapGesture(perform: onTap)
            }
        }
        // 2. POSITIONING & DEPTH
        .scaleEffect(getScale())
        .rotation3DEffect(
            .degrees(getRotation()),
            axis: (x: 1, y: 0, z: 0)
        )
        .offset(y: getOffset())
        
        // 3. STACK ORDER (Z-Index)
        .zIndex(getZIndex())
        
        // Animation value
        .animation(.spring(response: 0.5, dampingFraction: 0.75), value: isSelected)
        
        // DELETE ANIMATION (Fly off to right)
        .transition(
            .asymmetric(
                insertion: .identity,
                removal: .move(edge: .trailing).combined(with: .opacity)
            )
        )
    }

    // MARK: - ROLODEX MATH (Moved from TravelDocsWalletView)
    
    // Calculates the vertical offset for the card
    func getOffset() -> CGFloat {
        if isSelected {
            // Return to 0 for true center if selected
            return 0
        }
        
        // Center the stack based on the number of active cards
        let count = CGFloat(activeDocumentsCount)
        let stackCenterAdjustment = count > 1 ? ((count - 1) * cardSpacing) / 2 : 0
        
        return position - stackCenterAdjustment
    }
    
    // Calculates the scale for the card based on its position
    func getScale() -> CGFloat {
        if isSelected {
            return 1.0
        }
        // SAFETY: Avoid division by zero if totalScrollHeight is 0
        guard totalScrollHeight > 0 else { return 0.85 } // Return a default reasonable scale
        let progress = position / totalScrollHeight
        return 0.85 + (0.15 * progress)
    }
    
    // Calculates the 3D rotation for the card based on its position
    func getRotation() -> Double {
        if isSelected { return 0 }
        // SAFETY: Avoid division by zero if totalScrollHeight is 0
        guard totalScrollHeight > 0 else { return -10 } // Return a default reasonable rotation
        let progress = position / totalScrollHeight
        return -10 * (1 - progress)
    }
    
    // Calculates the Z-index for the card to control stacking order
    func getZIndex() -> Double {
        if isSelected {
            return Double(totalScrollHeight) + 100 // Ensure selected card is always on top
        }
        return Double(position)
    }
}


// MARK: - 3. MAIN WALLET VIEW
struct TravelDocsWalletView: View {
    // Selection State
    @State private var selectedID: UUID? = nil
    
    // DATA STATE (Loads from disk on init)
    @State private var documents: [TravelDocument] = TravelDocumentStore.shared.load()
    
    // ADD MENU STATE
    @State private var showAllCardsSheet = false
    @State private var selectedTypeToAdd: TravelDocument.DocumentType? = nil
    
    // EDIT STATE
    @State private var documentToEdit: TravelDocument? = nil
    
    // Scroll/Drag State
    @AppStorage("walletScrollOffset") private var baseScrollOffset: Double = 0
    @State private var dragOffset: CGFloat = 0
    
    // Configuration
    private let cardSpacing: CGFloat = 65
    private let maxCardsOnScreen = 6
    
    // MARK: - NEW: ONLY SHOW ACTIVE CARDS (Max 6 handled by toggles)
    var activeDocuments: [TravelDocument] {
        documents.filter { $0.isActive }
    }
    
    private var totalScrollHeight: CGFloat {
        CGFloat(activeDocuments.count) * cardSpacing
    }
    
    var body: some View {
        ZStack {
            // Background
            Color(red: 0.11, green: 0.11, blue: 0.12).ignoresSafeArea()
            
            // MARK: - NEW: EMPTY STATE
            if documents.isEmpty {
                EmptyWalletView()
                    .transition(.opacity)
                    .zIndex(0)
            }
            
            // MARK: - 1. MAIN CARD AREA (Now Full Screen Background)
            GeometryReader { geo in
                ZStack(alignment: .center) {
                    ForEach(Array(activeDocuments.enumerated()), id: \.element.id) { index, doc in
                        
                        // 1. CALCULATE DYNAMIC POSITION
                        let currentPos = getCircularPosition(for: index)
                        let isSelected = (selectedID == doc.id)
                        
                        WalletCardContainerView(
                            document: doc,
                            isSelected: isSelected,
                            position: currentPos,
                            totalScrollHeight: totalScrollHeight,
                            activeDocumentsCount: activeDocuments.count,
                            cardSpacing: cardSpacing,
                            onTap: { toggleSelection(for: doc.id) }
                        )
                        .frame(width: geo.size.width - 40)
                        // Hide other cards when one is selected
                        .opacity(selectedID != nil && !isSelected ? 0 : 1)
                        .blur(radius: selectedID != nil && !isSelected ? 20 : 0)
                        // Use a faster animation for the background fade/blur
                        .animation(.easeOut(duration: 0.25), value: selectedID)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
                
                // 5. DRAG GESTURE (THE ROLODEX)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            guard selectedID == nil else { return }
                            dragOffset = value.translation.height
                        }
                        .onEnded { value in
                            // FIX: Corrected syntax for guard statement
                            guard selectedID == nil else { return }
                            
                            let totalDrag = CGFloat(baseScrollOffset) + value.translation.height
                            let velocity = value.predictedEndTranslation.height / 5
                            let projectedTotal = totalDrag + velocity
                            
                            let snapStep = cardSpacing
                            let nearestStep = (projectedTotal / snapStep).rounded() * snapStep
                            
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                baseScrollOffset = Double(nearestStep)
                                dragOffset = 0
                            }
                        }
                )
            }
            
            // MARK: - 2. PERSISTENT HEADER (Overlay)
            // Sits on top of cards so it doesn't push them down
            VStack {
                HStack {
                    if selectedID == nil {
                        Text("Bind")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .transition(.opacity)
                    } else {
                        // Invisible text to maintain height
                         Text("Bind")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .opacity(0)
                    }
                    
                    Spacer()
                    
                    if selectedID == nil {
                        // NEW: Native Plus Menu with Dropdown Options
                        Menu {
                            Section("Travel") {
                                Button(action: { startAdd(.passport) }) { Label("Passport", systemImage: "globe") }
                                Button(action: { startAdd(.boardingPass) }) { Label("Boarding Pass", systemImage: "airplane") }
                                Button(action: { startAdd(.visa) }) { Label("Visa", systemImage: "checkmark.seal") }
                                Button(action: { startAdd(.insurance) }) { Label("Insurance", systemImage: "cross.case") }
                            }
                            Section("Identity") {
                                Button(action: { startAdd(.driversLicense) }) { Label("Driver's License", systemImage: "car") }
                                Button(action: { startAdd(.studentID) }) { Label("Student ID", systemImage: "graduationcap") }
                                Button(action: { startAdd(.idCard) }) { Label("National ID", systemImage: "person.text.rectangle") }
                            }
                            
                            Section("Health") {
                                Button(action: { startAdd(.prescription) }) { Label("Prescription", systemImage: "pills") }
                                Button(action: { startAdd(.vaccineRecord) }) { Label("Vaccination Record", systemImage: "syringe") }
                                Button(action: { startAdd(.medicalAlert) }) { Label("Blood & Allergies", systemImage: "staroflife") }
                            }
                            
                            Section("Other") {
                                Button(action: { startAdd(.birthCertificate) }) { Label("Birth Certificate", systemImage: "stroller") }
                                Button(action: { startAdd(.marriageCertificate) }) { Label("Marriage Certificate", systemImage: "figure.and.child.holdinghands") }
                            }

                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 32)) // Slightly larger touch target
                                .symbolRenderingMode(.hierarchical)
                                .foregroundColor(.white)
                                .background(Color.black.opacity(0.5).clipShape(Circle())) // Match ellipsis style
                        }
                        .transition(.scale.combined(with: .opacity))
                    } else {
                        // MARK: - DELETE BUTTON (Ellipsis Menu)
                        // Shows when a card is selected
                        if let doc = documents.first(where: { $0.id == selectedID }) {
                            Menu {
                                // EDIT BUTTON
                                Button {
                                    documentToEdit = doc
                                } label: {
                                    Label("Edit Card", systemImage: "pencil")
                                }
                                
                                Button(role: .destructive) {
                                    deleteDocument(doc)
                                } label: {
                                    Label("Remove Card", systemImage: "trash")
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle.fill")
                                    .font(.system(size: 32))
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(.white)
                                    .background(Color.black.opacity(0.5).clipShape(Circle()))
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 50) // Adjust for notch
                
                Spacer() // Pushes header to top
            }
            // Ensure header doesn't block card touches in empty space
            .allowsHitTesting(true)
            
            // MARK: - NEW: OVERFLOW BUTTON (If > 6 cards OR user wants to edit)
            // Changed logic: Always show if there are documents
            if !documents.isEmpty && selectedID == nil {
                VStack {
                    Spacer()
                    Button(action: {
                        showAllCardsSheet = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "square.stack.3d.up.fill")
                            Text("All Cards")
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .foregroundColor(.white)
                        .shadow(radius: 5)
                    }
                    .padding(.bottom, 20)
                }
                .transition(.opacity)
                .zIndex(100)
            }
            
            // Close Button (Only visible when card selected)
            if selectedID != nil {
                VStack {
                    Spacer()
                    Button(action: {
                        toggleSelection(for: nil)
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 50))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundColor(.white)
                            .shadow(radius: 10)
                    }
                    .padding(.bottom, 50)
                }
                .transition(.opacity)
                .zIndex(200)
            }
        }
        // AUTOMATIC SAVING: Whenever documents array changes, save to disk
        .onChange(of: documents) { newValue in
            TravelDocumentStore.shared.save(newValue)
        }
        // ADD SHEET: Triggers when the user selects an item from the Menu
        .sheet(item: $selectedTypeToAdd) { type in
            DocumentFormView(type: type) { newDoc in
                // Cubic-bezier to document insertion and scroll reset
                withAnimation(.timingCurve(0.25, 0.1, 0.25, 1, duration: 0.4)) {
                    // 1. If at max capacity (6), deactivate the last active card to make room
                    if activeDocuments.count >= maxCardsOnScreen {
                        // Find the index of the last active card
                        if let lastActiveIndex = documents.lastIndex(where: { $0.isActive }) {
                            documents[lastActiveIndex].isActive = false
                        }
                    }
                    
                    // 2. Insert new card at top (it is active by default)
                    documents.insert(newDoc, at: 0)
                    
                    // 3. Reset scroll so the top (0th item) is front-and-center
                    baseScrollOffset = 0
                    dragOffset = 0
                }
            }
        }
        // EDIT SHEET: Triggers when user taps "Edit"
        .sheet(item: $documentToEdit) { doc in
            DocumentFormView(document: doc) { updatedDoc in
                // Update the document in place
                if let index = documents.firstIndex(where: { $0.id == updatedDoc.id }) {
                    documents[index] = updatedDoc
                }
            }
        }
        // MARK: - NEW: ALL CARDS SHEET WITH TOGGLES
        .sheet(isPresented: $showAllCardsSheet) {
            NavigationView {
                List {
                    ForEach(documents) { doc in
                        HStack(spacing: 15) {
                            Image(systemName: doc.iconName)
                                .font(.title2)
                                .foregroundColor(doc.primaryColor)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading) {
                                Text(doc.title)
                                    .font(.headline)
                                Text(doc.subtitle)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            
                            // Native Switch
                            // Safe Binding prevents crash on deletion
                            Toggle("", isOn: safeBinding(for: doc))
                                .labelsHidden()
                                .tint(.green)
                                // Disable turning ON if we are already at 6
                                .disabled(!doc.isActive && activeDocuments.count >= maxCardsOnScreen)
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete { indexSet in
                        print("DEBUG: onDelete triggered. Initial documents count: \(documents.count), indexSet: \(indexSet)")
                        
                        // Using remove(atOffsets:) directly, which is the idiomatic way for List deletion.
                        withAnimation(.timingCurve(0.25, 0.1, 0.25, 1, duration: 0.35)) {
                            documents.remove(atOffsets: indexSet)
                            // Reset scroll and selection if needed
                            baseScrollOffset = 0
                            dragOffset = 0
                            selectedID = nil
                        }
                        print("DEBUG: Deletion complete. New documents count: \(documents.count)")
                    }
                    .onMove { indices, newOffset in
                        withAnimation { // Animate the reordering for a smoother UX
                            documents.move(fromOffsets: indices, toOffset: newOffset)
                        }
                    }
                }
                .navigationTitle("All Cards (\(activeDocuments.count)/\(maxCardsOnScreen))")
                .navigationBarItems(
                    leading: EditButton(),
                    trailing: Button("Done") { showAllCardsSheet = false }
                )
            }
        }
    }
    
    // MARK: - LOGIC
    
    // Helper to create a safe binding for the toggle that won't crash if the item is deleted
    func safeBinding(for doc: TravelDocument) -> Binding<Bool> {
        Binding<Bool>(
            get: {
                if let index = documents.firstIndex(where: { $0.id == doc.id }) {
                    return documents[index].isActive
                }
                return false
            },
            set: { newValue in
                if let index = documents.firstIndex(where: { $0.id == doc.id }) {
                    documents[index].isActive = newValue
                }
            }
        )
    }
    
    func deleteDocument(_ doc: TravelDocument) {
        // Trigger Animation: Remove card from array
        // Custom cubic-bezier for document deletion
        withAnimation(.timingCurve(0.25, 0.1, 0.25, 1, duration: 0.35)) {
            if let index = documents.firstIndex(where: { $0.id == doc.id }) {
                documents.remove(at: index)
            }
            // Clear selection state after removal starts
            selectedID = nil
        }
    }
    
    func startAdd(_ type: TravelDocument.DocumentType) {
        selectedTypeToAdd = type
    }
    
    func toggleSelection(for id: UUID?) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            if let id = id, selectedID == id {
                selectedID = nil
            } else {
                selectedID = id
            }
        }
    }
    
    // --- ROLODEX MATH ---
    
    // Calculates where the card is in the loop (0 to totalScrollHeight)
    func getCircularPosition(for index: Int) -> CGFloat {
        // SAFETY: Avoid crash if all documents are deleted
        if totalScrollHeight == 0 { return 0 }
        
        let initialOffset = CGFloat(index) * cardSpacing
        let currentScroll = CGFloat(baseScrollOffset) + dragOffset
        
        // Combine index offset with scroll
        let rawPosition = initialOffset + currentScroll
        
        // Modulo arithmetic to wrap values
        let loopedPosition = rawPosition.truncatingRemainder(dividingBy: totalScrollHeight)
        
        if loopedPosition < 0 {
            return loopedPosition + totalScrollHeight
        } else {
            return loopedPosition
        }
    }
}
struct Bind_Previews: PreviewProvider {
    static var previews: some View {
        TravelDocsWalletView()
            .preferredColorScheme(.dark)
    }
}