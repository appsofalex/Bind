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
                    .font(.system(size: 24, weight: .bold))
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.8))
                
                Text("Add your first document or booking by clicking the '+' button.")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 50)
                
                Spacer()
                    .frame(height: 30)
                
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
                        
                        .timingCurve(0.25, 0.1, 0.25, 1, duration: 1.0)
                        .repeatForever(autoreverses: true)
                    ) {
                        animateArrow = true
            }
        }
    }
}

// 3. MAIN WALLET VIEW
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
                        let isPassport = (doc.type == .passport)
                        // CHANGED: Group generic ID types together for the flip animation
                        let isIDCard = (doc.type == .idCard || doc.type == .driversLicense || doc.type == .studentID)
                        let isBoardingPass = (doc.type == .boardingPass)
                        let isRewardsCard = (doc.type == .rewardsCard)
                        let isCarRental = (doc.type == .carRental)
                        let isSelected = (selectedID == doc.id)
                        
                        Group {
                            if isPassport {
                                // Use the specialized flip card for Passport
                                PassportFlipCard(
                                    document: doc,
                                    isSelected: isSelected,
                                    onTap: { toggleSelection(for: doc.id) }
                                )
                            } else if isIDCard {
                                // Use specialized flip card for ID
                                IDFlipCard(
                                    document: doc,
                                    isSelected: isSelected,
                                    onTap: { toggleSelection(for: doc.id) }
                                )
                            } else if isBoardingPass {
                                // Use specialized animation for Boarding Pass
                                BoardingPassAnimatedCard(
                                    document: doc,
                                    isSelected: isSelected,
                                    onTap: { toggleSelection(for: doc.id) }
                                )
                            } else if isRewardsCard {
                                // Use new Rewards animation
                                RewardsAnimatedCard(
                                    document: doc,
                                    isSelected: isSelected,
                                    onTap: { toggleSelection(for: doc.id) }
                                )
                            } else if isCarRental {
                                // Use new Car Rental animation
                                CarRentalAnimatedCard(
                                    document: doc,
                                    isSelected: isSelected,
                                    onTap: { toggleSelection(for: doc.id) }
                                )
                            } else {
                                // Standard cards for new types
                                DocumentCardView(document: doc)
                                    .onTapGesture { toggleSelection(for: doc.id) }
                            }
                        }
                        .frame(width: geo.size.width - 40)
                        
                        // 2. POSITIONING & DEPTH
                        .scaleEffect(getScale(for: currentPos, docID: doc.id))
                        .rotation3DEffect(
                            .degrees(getRotation(for: currentPos, docID: doc.id)),
                            axis: (x: 1, y: 0, z: 0)
                        )
                        .offset(y: getOffset(for: currentPos, docID: doc.id))
                        
                        // 3. STACK ORDER (Z-Index)
                        .zIndex(getZIndex(for: currentPos, docID: doc.id))
                        
                        // Animation value
                        .animation(.spring(response: 0.5, dampingFraction: 0.75), value: selectedID)
                        
                        // DELETE ANIMATION (Fly off to right)
                        .transition(
                            .asymmetric(
                                insertion: .identity,
                                removal: .move(edge: .trailing).combined(with: .opacity)
                            )
                        )
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
                            guard selectedID == nil else { return }
                            
                            let totalDrag = CGFloat(baseScrollOffset) + value.translation.height
                            
                            // Calculate pure velocity impact for inertial scrolling
                            // Subtract translation to isolate the momentum
                            let velocity = (value.predictedEndTranslation.height - value.translation.height)
                            
                            // Apply friction to the slide (adjustable for feel, 0.5 is balanced)
                            let friction: CGFloat = 0.5 
                            let projectedTotal = totalDrag + (velocity * friction)
                            
                            let snapStep = cardSpacing
                            let nearestStep = (projectedTotal / snapStep).rounded() * snapStep
                            
                            // "Slider.js" style smoothness: Slightly slower response, higher damping for a 'gliding' stop
                            withAnimation(.spring(response: 0.55, dampingFraction: 0.825)) {
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
                                Button(action: { startAdd(.carRental) }) { Label("Car Rental", systemImage: "car.2.fill") }
                                Button(action: { startAdd(.hotelKeyCard) }) { Label("Hotel Key Card", systemImage: "key.fill") }
                                Button(action: { startAdd(.visa) }) { Label("Visa", systemImage: "checkmark.seal") }
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
                                Button(action: { startAdd(.insurance) }) { Label("Insurance", systemImage: "cross.case") }
                            }
                            
                            Section("Pets") {
                                Button(action: { startAdd(.petInsurance) }) { Label("Pet Insurance", systemImage: "cross.case.fill") }
                                Button(action: { startAdd(.petVaccineRecord) }) { Label("Pet Vaccination", systemImage: "syringe.fill") }
                                Button(action: { startAdd(.petPassport) }) { Label("Pet Passport", systemImage: "pawprint.fill") }
                                Button(action: { startAdd(.petID) }) { Label("Pet ID", systemImage: "pawprint.fill") }
                            }

                            Section("Other") {
                                Button(action: { startAdd(.birthCertificate) }) { Label("Birth Certificate", systemImage: "stroller.fill") }
                                Button(action: { startAdd(.marriageCertificate) }) { Label("Marriage Certificate", systemImage: "figure.and.child.holdinghands") }
                                Button(action: { startAdd(.rewardsCard) }) { Label("Rewards Card", systemImage: "star.fill") }
                                Button(action: { startAdd(.event) }) { Label("Event", systemImage: "ticket.fill") }
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
                withAnimation {
                    // 1. If we are at max capacity (6), deactivate the last active card to make room
                    if activeDocuments.count >= maxCardsOnScreen {
                        // Find the index of the last active card
                        if let lastActiveIndex = documents.lastIndex(where: { $0.isActive }) {
                            documents[lastActiveIndex].isActive = false
                        }
                    }
                    
                    // 2. Add new card at the end so it appears at the front of the stack
                    documents.append(newDoc)
                    
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
                            Toggle("", isOn: Binding(
                                get: { doc.isActive },
                                set: { newValue in
                                    if let index = documents.firstIndex(where: { $0.id == doc.id }) {
                                        documents[index].isActive = newValue
                                    }
                                }
                            ))
                                .labelsHidden()
                                .tint(.green)
                                // Disable turning ON if we are already at 6
                                .disabled(!doc.isActive && activeDocuments.count >= maxCardsOnScreen)
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete { indexSet in
                        documents.remove(atOffsets: indexSet)
                    }
                    .onMove { indices, newOffset in
                        documents.move(fromOffsets: indices, toOffset: newOffset)
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
    
    func deleteDocument(_ doc: TravelDocument) {
            
            
            withAnimation(.timingCurve(0.25, 0.1, 0.25, 1, duration: 0.35)) {
                if let index = documents.firstIndex(where: { $0.id == doc.id }) {
                    documents.remove(at: index)
                }
                
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
    
    func getOffset(for position: CGFloat, docID: UUID) -> CGFloat {
        if let selected = selectedID {
            // Return to 0 for true center
            return selected == docID ? 0 : 1000 
        }
        
        // FIX: Center the stack based on the number of actual cards, not the scroll loop.
        // We calculate the midpoint of the card distribution: ((Count - 1) * Spacing) / 2
        let count = CGFloat(activeDocuments.count)
        let stackCenterAdjustment = count > 1 ? ((count - 1) * cardSpacing) / 2 : 0
        
        return position - stackCenterAdjustment
    }
    
    func getScale(for position: CGFloat, docID: UUID) -> CGFloat {
        if let selected = selectedID {
            return selected == docID ? 1.0 : 0.8
        }
        let progress = position / totalScrollHeight
        return 0.85 + (0.15 * progress)
    }
    
    func getRotation(for position: CGFloat, docID: UUID) -> Double {
        if selectedID != nil { return 0 }
        let progress = position / totalScrollHeight
        return -10 * (1 - progress)
    }
    
    func getZIndex(for position: CGFloat, docID: UUID) -> Double {
        if let selected = selectedID, selected == docID {
            return Double(totalScrollHeight) + 100 // Ensure selected card is always on top
        }
        return Double(position)
    }
}

struct Bind_Previews: PreviewProvider {
    static var previews: some View {
        TravelDocsWalletView()
            .preferredColorScheme(.dark)
    }
}

