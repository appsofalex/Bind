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
                    .foregroundColor(.primary.opacity(0.2))
                    .padding(.bottom, 10)
                
                Text("No Cards Yet")
                    .font(.system(size: 24, weight: .bold))
                    .fontWeight(.bold)
                    .foregroundColor(.primary.opacity(0.8))
                
                Text("Add your first document or booking by clicking the '+' button.")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.secondary)
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
                        .foregroundColor(.primary.opacity(0.6))
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

// PRO BADGE VIEW
struct ProBadgeView: View {
    @ObservedObject var subscriptionManager = SubscriptionManager.shared
    @AppStorage("isHapticsEnabled") private var isHapticsEnabled = true
    @State private var gradientProgress: CGFloat = 0
    @State private var glowScale: CGFloat = 0.0
    @State private var isAnimating = false
    
    // Hatch/Pop animation states
    @State private var cardScale: CGFloat = 0.0
    @State private var cardOpacity: Double = 0.0
    @State private var cardRotation: Double = 0.0
    @State private var cardYOffset: CGFloat = 0.0
    
    var body: some View {
        ZStack {
            // "Hatching" Card
            if isAnimating {
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.primary.opacity(0.8))
                    .scaleEffect(cardScale)
                    .opacity(cardOpacity)
                    .rotationEffect(.degrees(cardRotation))
                    .offset(y: cardYOffset)
            }
            
            // The PRO Badge
            if isAnimating || subscriptionManager.isPro {
                Text("PRO")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        ZStack {
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue, Color.purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .opacity(gradientProgress)
                            
                            Capsule()
                                .stroke(Color.white.opacity(0.4), lineWidth: 1)
                                .opacity(gradientProgress)
                        }
                    )
                    .shadow(color: Color.purple.opacity(0.5 * gradientProgress), radius: 8, x: 0, y: 0)
                    .scaleEffect(glowScale)
            }
        }
        .onAppear {
            if subscriptionManager.showUpgradeAnimation {
                runUpgradeAnimation()
            } else if subscriptionManager.isPro {
                gradientProgress = 1.0
                glowScale = 1.0
            }
        }
        .onChange(of: subscriptionManager.showUpgradeAnimation) { newValue in
            if newValue {
                runUpgradeAnimation()
            }
        }
    }
    
    private func runUpgradeAnimation() {
        isAnimating = true
        gradientProgress = 0
        glowScale = 0
        cardScale = 0
        cardOpacity = 0
        cardRotation = 0
        cardYOffset = 0
        
        let initialDelay = 0.6 // 600ms delay
        
        // 1. Card pops in
        DispatchQueue.main.asyncAfter(deadline: .now() + initialDelay) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                cardScale = 1.2
                cardOpacity = 1.0
            }
            
            // 2. Card "hatches" / reveals PRO
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                // Haptic for the "pop"
                if isHapticsEnabled {
                    HapticManager.shared.triggerImpact(style: .heavy)
                }
                
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    cardScale = 1.5
                    cardRotation = 15
                    cardYOffset = -20
                    cardOpacity = 0
                    
                    glowScale = 1.1
                    gradientProgress = 1.0
                }
                
                // 3. Settle into place
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        glowScale = 1.0
                    }
                    
                    // Final cleanup
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        subscriptionManager.showUpgradeAnimation = false
                        isAnimating = false
                    }
                }
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
    @State private var showSettingsSheet = false
    @State private var showQuickScanSheet = false
    @State private var showUpgradeSheet = false // Direct upgrade sheet (e.g. from Settings)
    @State private var selectedTypeToAdd: TravelDocument.DocumentType? = nil
    
    // PREFERENCES
    @AppStorage("isHapticsEnabled") private var isHapticsEnabled = true
    
    // EDIT STATE
    @State private var documentToEdit: TravelDocument? = nil
    
    // ALL CARDS PREVIEW (card opened from list, returns to list on exit)
    @State private var allCardsPreviewDocument: TravelDocument? = nil
    
    // SHARE STATE (zoomed card snapshot)
    @State private var showShareSheet = false
    @State private var shareImage: UIImage? = nil
    @State private var shareFileURL: URL? = nil
    
    // TUTORIAL STATE (first-time prompts)
    @AppStorage("hasSeenFirstCardTutorial") private var hasSeenFirstCardTutorial = false
    @AppStorage("hasSeenSixthCardTutorial") private var hasSeenSixthCardTutorial = false
    @AppStorage("hasSeenAllCardsTutorial") private var hasSeenAllCardsTutorial = false
    @AppStorage("hasSeenSettingsTutorial") private var hasSeenSettingsTutorial = false
    @AppStorage("hasSeenMaxStackTutorial") private var hasSeenMaxStackTutorial = false
    @AppStorage("hasSeenQuickScanTutorial") private var hasSeenQuickScanTutorial = false
    @AppStorage("hasSeenReorderTutorial") private var hasSeenReorderTutorial = false
    @State private var showFirstCardTutorial = false
    @State private var showSixthCardTutorial = false
    @State private var showSettingsTutorial = false
    @State private var showAllCardsListTutorial = false
    @State private var showMaxStackTutorial = false
    @State private var showQuickScanTutorial = false
    @State private var showReorderTutorial = false
    @State private var allCardsButtonFrame: CGRect = .zero
    @State private var settingsButtonFrame: CGRect = .zero
    @State private var quickScanButtonFrame: CGRect = .zero
    @State private var topCardFrame: CGRect = .zero
    
    // Scroll/Drag State
    @AppStorage("walletScrollOffset") private var baseScrollOffset: Double = 0
    @State private var dragOffset: CGFloat = 0
    /// When set (e.g. right after adding a card), forces the stack to show this offset so the newest card is at front. Cleared when user drags.
    @State private var scrollOffsetForNewCard: Double? = nil
    
    // Reorder stack sheet (long-press on card opens exposé-style reorder)
    @State private var showReorderStackSheet = false
    @State private var longPressedDocumentID: UUID? = nil
    @State private var reorderStackInitialOrder: [UUID] = []
    /// Tracks active count so we only re-center when it changes (add/remove/toggle), not on every documents change.
    @State private var lastAppliedActiveCount: Int = -1
    
    // Configuration
    private let cardSpacing: CGFloat = 65
    private let maxCardsOnStack: Int = 6
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    @Environment(\.colorScheme) var colorScheme
    
    // MARK: - Stack: only active cards, max 6 on stack (overflow bumped to All Cards, switch off)
    var activeDocuments: [TravelDocument] {
        documents.filter { $0.isActive }
    }
    
    /// Stack order: NEWEST FIRST (index 0 = front). Uses explicit stackOrderIndex (higher = newer); legacy docs use array index.
    private var stackOrderedDocuments: [TravelDocument] {
        let active = activeDocuments
        let orderById = Dictionary(uniqueKeysWithValues: documents.enumerated().map { ($0.element.id, $0.offset) })
        return active.sorted { a, b in
            let oa = a.stackOrderIndex ?? (orderById[a.id] ?? 0)
            let ob = b.stackOrderIndex ?? (orderById[b.id] ?? 0)
            return oa > ob
        }
    }
    
    /// Scroll value used for layout; when we just added a card we force the offset so index 0 (newest) is at front.
    private var effectiveBaseScrollOffset: Double {
        scrollOffsetForNewCard ?? baseScrollOffset
    }
    
    /// Single source of truth for keeping the stack centered: scroll offset so the front card (index 0) is at visual center.
    private func centeredScrollOffset(for activeCount: Int) -> Double {
        guard activeCount > 1 else { return 0 }
        return Double(activeCount - 1) * Double(cardSpacing) / 2
    }
    
    /// Fixed adjustment to centre the stack on screen (midpoint of positions at centred scroll). Depends only on count so dragging stays smooth.
    private var stackCenterAdjustmentForCount: CGFloat {
        let count = activeDocuments.count
        guard count > 0, totalScrollHeight > 0 else { return 0 }
        let scroll = CGFloat(centeredScrollOffset(for: count))
        var minP: CGFloat = .greatestFiniteMagnitude
        var maxP: CGFloat = -.greatestFiniteMagnitude
        for i in 0..<count {
            let raw = CGFloat(i) * cardSpacing + scroll
            var p = raw.truncatingRemainder(dividingBy: totalScrollHeight)
            if p < 0 { p += totalScrollHeight }
            minP = min(minP, p)
            maxP = max(maxP, p)
        }
        return (minP + maxP) / 2
    }
    
    private var totalScrollHeight: CGFloat {
        CGFloat(activeDocuments.count) * cardSpacing
    }
    
    // MARK: - HELPER VIEW FOR SMOOTH WRAPPING
    struct PositionSmoother<Content: View>: View {
        var target: CGFloat
        var totalHeight: CGFloat
        @ViewBuilder var content: (CGFloat) -> Content
        
        @State private var currentVisualPosition: CGFloat?
        
        var body: some View {
            content(currentVisualPosition ?? target)
                .onAppear {
                    currentVisualPosition = target
                }
                .onChange(of: target) { newValue in
                    guard let oldVal = currentVisualPosition else {
                        currentVisualPosition = newValue
                        return
                    }
                    
                    let delta = newValue - oldVal
                    
                    // Detect Wrap: If change is larger than half the loop
                    if abs(delta) > (totalHeight * 0.5) {
                        // Animate the snap (wrap around)
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            currentVisualPosition = newValue
                        }
                    } else {
                        // Instant update for drag/scroll
                        currentVisualPosition = newValue
                    }
                }
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            Group {
                if colorScheme == .dark {
                    Color(red: 0.11, green: 0.11, blue: 0.12)
                } else {
                    Color(red: 0.96, green: 0.96, blue: 0.97)
                }
            }.ignoresSafeArea()
            
            // MARK: - NEW: EMPTY STATE
            if documents.isEmpty {
                EmptyWalletView()
                    .transition(.opacity)
                    .zIndex(0)
            }
            
            // MARK: - 1. MAIN CARD AREA (Now Full Screen Background)
            GeometryReader { geo in
                ZStack(alignment: .center) {
                    ForEach(Array(stackOrderedDocuments.enumerated()), id: \.element.id) { index, doc in
                        
                        // 1. CALCULATE DYNAMIC POSITION
                        let targetPos = getCircularPosition(for: index)
                        let isPassport = (doc.type == .passport)
                        // CHANGED: Group generic ID types together for the flip animation
                        let isIDCard = (doc.type == .idCard || doc.type == .driversLicense || doc.type == .studentID || doc.type == .nationalInsurance)
                        let isBoardingPass = (doc.type == .boardingPass)
                        let isVisa = (doc.type == .visa)
                        let isRewardsCard = (doc.type == .rewardsCard)
                        let isCarRental = (doc.type == .carRental)
                        let isMedicalAlert = (doc.type == .medicalAlert)
                        let isSelected = (selectedID == doc.id)
                        
                        PositionSmoother(target: targetPos, totalHeight: totalScrollHeight) { currentPos in
                            Group {
                                if isPassport {
                                    PassportFlipCard(
                                        document: doc,
                                        isSelected: isSelected,
                                        onTap: { toggleSelection(for: doc.id) }
                                    )
                                } else if isVisa {
                                    VisaFlipCard(
                                        document: doc,
                                        isSelected: isSelected,
                                        onTap: { toggleSelection(for: doc.id) }
                                    )
                                } else if isMedicalAlert {
                                    MedicalFlipCard(
                                        document: doc,
                                        isSelected: isSelected,
                                        onTap: { toggleSelection(for: doc.id) }
                                    )
                                } else if doc.type == .vaccineRecord {
                                    VaccinationFlipCard(
                                        document: doc,
                                        isSelected: isSelected,
                                        onTap: { toggleSelection(for: doc.id) }
                                    )
                                } else if doc.type == .prescription {
                                    PrescriptionFlipCard(
                                        document: doc,
                                        isSelected: isSelected,
                                        onTap: { toggleSelection(for: doc.id) }
                                    )
                                } else if doc.type == .birthCertificate {
                                    BirthCertificateFlipCard(
                                        document: doc,
                                        isSelected: isSelected,
                                        onTap: { toggleSelection(for: doc.id) }
                                    )
                                } else if doc.type == .marriageCertificate {
                                    MarriageCertificateFlipCard(
                                        document: doc,
                                        isSelected: isSelected,
                                        onTap: { toggleSelection(for: doc.id) }
                                    )
                                } else if isIDCard {
                                    IDFlipCard(
                                        document: doc,
                                        isSelected: isSelected,
                                        onTap: { toggleSelection(for: doc.id) },
                                        titleOverride: doc.type == .nationalInsurance ? "NI Number" : (doc.type == .studentID ? "Student ID" : nil),
                                        subtitleOverride: doc.type == .nationalInsurance ? "NI Number" : (doc.type == .studentID ? "Student ID" : nil)
                                    )
                                } else if isBoardingPass {
                                    BoardingPassAnimatedCard(
                                        document: doc,
                                        isSelected: isSelected,
                                        onTap: { toggleSelection(for: doc.id) }
                                    )
                                } else if isRewardsCard {
                                    RewardsAnimatedCard(
                                        document: doc,
                                        isSelected: isSelected,
                                        onTap: { toggleSelection(for: doc.id) }
                                    )
                                } else if isCarRental {
                                    CarRentalAnimatedCard(
                                        document: doc,
                                        isSelected: isSelected,
                                        onTap: { toggleSelection(for: doc.id) }
                                    )
                                } else if doc.type == .hotelKeyCard {
                                    HotelKeyAnimatedCard(
                                        document: doc,
                                        isSelected: isSelected,
                                        onTap: { toggleSelection(for: doc.id) }
                                    )
                                } else if doc.type == .event {
                                    EventAnimatedCard(
                                        document: doc,
                                        isSelected: isSelected,
                                        onTap: { toggleSelection(for: doc.id) }
                                    )
                                } else if [.petInsurance, .petVaccineRecord, .petPassport, .petID].contains(doc.type) {
                                    PetAnimatedCard(
                                        document: doc,
                                        isSelected: isSelected,
                                        onTap: { toggleSelection(for: doc.id) }
                                    )
                                } else if doc.type == .insurance {
                                    InsuranceFlipCard(
                                        document: doc,
                                        isSelected: isSelected,
                                        onTap: { toggleSelection(for: doc.id) }
                                    )
                                } else {
                                    DocumentCardView(document: doc)
                                        .onTapGesture { toggleSelection(for: doc.id) }
                                }
                            }
                            .frame(width: geo.size.width - 40)
                            .onLongPressGesture(minimumDuration: 0.5) {
                                guard activeDocuments.count > 1, selectedID == nil else { return }
                                if isHapticsEnabled {
                                    HapticManager.shared.triggerImpact(style: .medium)
                                }
                                longPressedDocumentID = doc.id
                                reorderStackInitialOrder = visualOrderForReorderSheet()
                                showReorderStackSheet = true
                            }
                            
                            // 2. POSITIONING & DEPTH
                            .scaleEffect(getScale(for: currentPos, docID: doc.id))
                            .rotation3DEffect(
                                .degrees(getRotation(for: currentPos, docID: doc.id)),
                                axis: (x: 1, y: 0, z: 0)
                            )
                            .offset(y: getOffset(for: currentPos, docID: doc.id))
                            .shadow(
                                color: colorScheme == .dark ? .clear : .black.opacity(0.3),
                                radius: colorScheme == .dark ? 0 : 15,
                                x: 0,
                                y: colorScheme == .dark ? 0 : 10
                            )
                            
                            // 3. STACK ORDER (Z-Index)
                            .zIndex(getZIndex(for: currentPos, docID: doc.id))
                            
                            // DELETE ANIMATION (Fly off to right)
                            .transition(
                                .asymmetric(
                                    insertion: .identity,
                                    removal: .move(edge: .trailing).combined(with: .opacity)
                                )
                            )
                            .background(
                                GeometryReader { g in
                                    Color.clear.preference(key: TutorialTargetFrameKey.self, value: index == 0 ? [4: g.frame(in: .named("tutorialSpace"))] : [:])
                                }
                            )
                        }
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
                
                // 5. DRAG GESTURE (THE ROLODEX)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            guard selectedID == nil else { return }
                            scrollOffsetForNewCard = nil
                            dragOffset = value.translation.height
                        }
                        .onEnded { value in
                            guard selectedID == nil else { return }
                            
                            let totalDrag = CGFloat(baseScrollOffset) + value.translation.height
                            
                            // Calculate pure velocity impact for inertial scrolling
                            let velocity = (value.predictedEndTranslation.height - value.translation.height)
                            let friction: CGFloat = 0.5
                            let projectedTotal = totalDrag + (velocity * friction)
                            
                            // Snap to steps aligned with the centred scroll so stack stays vertically centred
                            let center = CGFloat(centeredScrollOffset(for: activeDocuments.count))
                            var nearestStep = center + (round((projectedTotal - center) / cardSpacing) * cardSpacing)
                            nearestStep = nearestStep.truncatingRemainder(dividingBy: totalScrollHeight)
                            if nearestStep < 0 { nearestStep += totalScrollHeight }
                            
                            withAnimation(.spring(response: 0.55, dampingFraction: 0.825)) {
                                baseScrollOffset = Double(nearestStep)
                                scrollOffsetForNewCard = nil
                                dragOffset = 0
                            }
                        }
                )
            }
            
            // PERSISTENT HEADER (Overlay)
            // Sits on top of cards so it doesn't push them down
            VStack {
                HStack {
                    // Share button (top left when card is expanded)
                    if selectedID != nil {
                        Button(action: shareExpandedCard) {
                            Image(systemName: "square.and.arrow.up.circle.fill")
                                .font(.system(size: 32))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.white)
                                .background(Color.black.opacity(0.5).clipShape(Circle()))
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    HStack(alignment: .center, spacing: 10) {
                        Text("Bind")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        ProBadgeView()
                    }
                    .opacity(selectedID == nil ? 1 : 0)
                    .transition(.opacity)
                    
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
                                Button(action: { startAdd(.nationalInsurance) }) { Label("National Insurance", systemImage: "number.square.fill") }
                            }
                            
                            Section("Health") {
                                Button(action: { startAdd(.prescription) }) { Label("Prescription", systemImage: "pills") }
                                Button(action: { startAdd(.vaccineRecord) }) { Label("Vaccination", systemImage: "syringe") }
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
            
            // MARK: - BOTTOM CONTROLS
            // Changed logic: Always show buttons if no card is selected
            if selectedID == nil {
                VStack {
                    Spacer()
                    
                    ZStack {
                        if !documents.isEmpty {
                            HStack {
                                Spacer()
                                
                                // Quick Scan Button
                                Button(action: {
                                    showQuickScanSheet = true
                                }) {
                                    Image(systemName: "bolt.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.primary)
                                        .frame(width: 44, height: 44)
                                        .background(.ultraThinMaterial)
                                        .clipShape(Circle())
                                        .shadow(radius: 5)
                                }
                                .reportTutorialFrame(tag: 3)
                                
                                Spacer()
                                
                                // All Cards Button
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
                                    .foregroundColor(.primary)
                                    .shadow(radius: 5)
                                }
                                .reportTutorialFrame(tag: 1)
                                
                                Spacer()
                                
                                // Settings Button
                                Button(action: {
                                    showSettingsSheet = true
                                }) {
                                    Image(systemName: "gearshape.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.primary)
                                        .frame(width: 44, height: 44)
                                        .background(.ultraThinMaterial)
                                        .clipShape(Circle())
                                        .shadow(radius: 5)
                                }
                                .reportTutorialFrame(tag: 2)
                                
                                Spacer()
                            }
                        } else {
                            HStack {
                                Spacer()
                                Button(action: {
                                    showSettingsSheet = true
                                }) {
                                    Image(systemName: "gearshape.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.primary)
                                        .frame(width: 44, height: 44)
                                        .background(.ultraThinMaterial)
                                        .clipShape(Circle())
                                        .shadow(radius: 5)
                                }
                                .reportTutorialFrame(tag: 2)
                                .padding(.trailing, 20)
                            }
                        }
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
                            .foregroundStyle(.white)
                            .background(Color.black.opacity(0.5).clipShape(Circle()))
                    }
                    .padding(.bottom, 50)
                }
                .transition(.opacity)
                .zIndex(200)
            }
            
            // MARK: - TUTORIAL BUBBLES (first-time prompts)
            if showFirstCardTutorial {
                TutorialBubbleOverlay(
                    message: "This is your card stack. Up to 6 cards show here - add more to see them stack!",
                    targetFrame: .zero,
                    pointerEdge: .bottom,
                    onDismiss: {
                        hasSeenFirstCardTutorial = true
                        showFirstCardTutorial = false
                        if documents.count >= 2 && !hasSeenSettingsTutorial {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                showSettingsTutorial = true
                            }
                        }
                    }
                )
                .zIndex(300)
            }
            if showSixthCardTutorial {
                TutorialBubbleOverlay(
                    message: "As you add more cards, they'll all appear in the \"All Cards\" menu.",
                    targetFrame: allCardsButtonFrame,
                    pointerEdge: .top,
                    onDismiss: {
                        hasSeenSixthCardTutorial = true
                        showSixthCardTutorial = false
                    }
                )
                .zIndex(300)
            }
            if showSettingsTutorial {
                TutorialBubbleOverlay(
                    message: "Tap the cog for settings and other useful options.",
                    targetFrame: settingsButtonFrame,
                    pointerEdge: .leading,
                    onDismiss: {
                        hasSeenSettingsTutorial = true
                        showSettingsTutorial = false
                    }
                )
                .zIndex(300)
            }
            if showQuickScanTutorial {
                TutorialBubbleOverlay(
                    message: "Tap the bolt to add a card by scanning a barcode or ticket - quick and easy.",
                    targetFrame: quickScanButtonFrame,
                    pointerEdge: .trailing,
                    onDismiss: {
                        hasSeenQuickScanTutorial = true
                        showQuickScanTutorial = false
                    }
                )
                .zIndex(300)
            }
            if showReorderTutorial {
                TutorialBubbleOverlay(
                    message: "Long-press any card to reorder the stack - then drag to change the order.",
                    targetFrame: topCardFrame,
                    pointerEdge: .top,
                    onDismiss: {
                        hasSeenReorderTutorial = true
                        showReorderTutorial = false
                    }
                )
                .zIndex(300)
            }
        }
        .coordinateSpace(name: "tutorialSpace")
        .onPreferenceChange(TutorialTargetFrameKey.self) { dict in
            if let r = dict[1] { allCardsButtonFrame = r }
            if let r = dict[2] { settingsButtonFrame = r }
            if let r = dict[3] { quickScanButtonFrame = r }
            if let r = dict[4] { topCardFrame = r }
        }
        .onAppear {
            backfillStackOrderIndexIfNeeded()
            lastAppliedActiveCount = activeDocuments.count
        }
        // AUTOMATIC SAVING: Whenever documents array changes, save to disk
        .onChange(of: documents) { newValue in
            TravelDocumentStore.shared.save(newValue)
            if let preview = allCardsPreviewDocument,
               let updated = newValue.first(where: { $0.id == preview.id }) {
                allCardsPreviewDocument = updated
            }
            // Re-center the stack when the number of active cards changes (add/remove/toggle) so it never drifts.
            let activeCount = newValue.filter(\.isActive).count
            guard activeCount != lastAppliedActiveCount else { return }
            lastAppliedActiveCount = activeCount
            let offset = centeredScrollOffset(for: activeCount)
            baseScrollOffset = offset
            scrollOffsetForNewCard = offset
        }
        // TUTORIAL TRIGGERS
        .onChange(of: documents.count) { count in
            if count == 1 && !hasSeenFirstCardTutorial {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    showFirstCardTutorial = true
                }
            }
            if count >= 6 && !hasSeenSixthCardTutorial {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showSixthCardTutorial = true
                }
            }
            if count >= 2 && hasSeenFirstCardTutorial && !hasSeenSettingsTutorial {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    showSettingsTutorial = true
                }
            }
            if count == 3 && !hasSeenQuickScanTutorial {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    showQuickScanTutorial = true
                }
            }
            if count == 4 && !hasSeenReorderTutorial {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    showReorderTutorial = true
                }
            }
        }
        .onChange(of: showAllCardsSheet) { isOpen in
            if isOpen && !hasSeenAllCardsTutorial {
                showAllCardsListTutorial = true
            }
        }
        // ADD SHEET: Triggers when the user selects an item from the Menu
        .sheet(item: $selectedTypeToAdd) { type in
            DocumentFormView(type: type) { newDoc in
                withAnimation {
                    var docToAdd = newDoc
                    docToAdd.stackOrderIndex = (documents.flatMap { $0.stackOrderIndex }.max() ?? -1) + 1
                    documents.append(docToAdd)
                    bumpLeastRecentActiveIfOverLimit()
                    dragOffset = 0
                    let count = documents.filter(\.isActive).count
                    let offset = centeredScrollOffset(for: count)
                    baseScrollOffset = offset
                    scrollOffsetForNewCard = offset
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
        // MARK: - SHARE SHEET (card snapshot)
        .sheet(isPresented: $showShareSheet, onDismiss: {
            shareImage = nil
            if let url = shareFileURL {
                try? FileManager.default.removeItem(at: url)
            }
            shareFileURL = nil
        }) {
            ShareSheet(fileURL: shareFileURL, image: shareImage)
        }
        // MARK: - SETTINGS SHEET
        .sheet(isPresented: $showSettingsSheet) {
            SettingsView(documents: $documents)
        }
        // MARK: - QUICK SCAN SHEET
        .sheet(isPresented: $showQuickScanSheet) {
            QuickScanView(documents: $documents)
        }
        // MARK: - REORDER STACK SHEET (exposé-style grid)
        .sheet(isPresented: $showReorderStackSheet) {
            ReorderStackView(
                documents: $documents,
                highlightedDocumentID: longPressedDocumentID,
                initialOrder: reorderStackInitialOrder,
                onDismiss: {
                    let count = documents.filter(\.isActive).count
                    let offset = centeredScrollOffset(for: count)
                    baseScrollOffset = offset
                    scrollOffsetForNewCard = offset
                    showReorderStackSheet = false
                }
            )
            .presentationDetents([.large])
            .presentationCornerRadius(24)
        }
        // MARK: - ALL CARDS SHEET WITH TOGGLES
        .sheet(isPresented: $showAllCardsSheet) {
            ZStack {
                NavigationView {
                    List {
                        ForEach(TravelDocument.DocumentType.categoryOrder, id: \.self) { category in
                            let docsInCategory = documents.filter { $0.type.category == category }
                            if !docsInCategory.isEmpty {
                                Section(header: Text(category)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)) {
                                    ForEach(docsInCategory) { doc in
                                        HStack(spacing: 15) {
                                            Button(action: { allCardsPreviewDocument = doc }) {
                                                HStack(spacing: 15) {
                                                    Image(systemName: doc.iconName)
                                                        .font(.title2)
                                                        .foregroundColor(doc.primaryColor)
                                                        .frame(width: 30)
                                                    VStack(alignment: .leading) {
                                                        Text(doc.displayTitle.displayCapitalized)
                                                            .font(.headline)
                                                        Text(doc.subtitle.displayCapitalized)
                                                            .font(.caption)
                                                            .foregroundColor(.gray)
                                                    }
                                                }
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .contentShape(Rectangle())
                                            }
                                            .buttonStyle(.plain)
                                            
                                            // Native Switch (max 6 on stack; at 6, show tutorial and prevent 7th)
                                            Toggle("", isOn: Binding(
                                                get: { doc.isActive },
                                                set: { newValue in
                                                    guard let index = documents.firstIndex(where: { $0.id == doc.id }) else { return }
                                                    if newValue {
                                                        let activeCount = documents.filter(\.isActive).count
                                                        if activeCount >= maxCardsOnStack {
                                                            if !hasSeenMaxStackTutorial {
                                                                showMaxStackTutorial = true
                                                            }
                                                            return
                                                        }
                                                    }
                                                    documents[index].isActive = newValue
                                                    if newValue {
                                                        bumpLeastRecentActiveIfOverLimit()
                                                    }
                                                }
                                            ))
                                                .labelsHidden()
                                                .tint(.green)
                                        }
                                        .padding(.vertical, 4)
                                    }
                                    .onDelete { indexSet in
                                        for i in indexSet.sorted(by: >) {
                                            let doc = docsInCategory[i]
                                            if let idx = documents.firstIndex(where: { $0.id == doc.id }) {
                                                documents.remove(at: idx)
                                            }
                                        }
                                    }
                                    .onMove { fromOffsets, toOffset in
                                        let sectionDocs = docsInCategory
                                        guard let from = fromOffsets.first, from < sectionDocs.count else { return }
                                        let docToMove = sectionDocs[from]
                                        guard let fromGlobal = documents.firstIndex(where: { $0.id == docToMove.id }) else { return }
                                        let toGlobal: Int
                                        if toOffset >= sectionDocs.count {
                                            let lastInSection = sectionDocs[sectionDocs.count - 1]
                                            guard let lastGlobal = documents.firstIndex(where: { $0.id == lastInSection.id }) else { return }
                                            toGlobal = lastGlobal + 1
                                        } else {
                                            let destDoc = sectionDocs[toOffset]
                                            guard let d = documents.firstIndex(where: { $0.id == destDoc.id }) else { return }
                                            toGlobal = d
                                        }
                                        documents.move(fromOffsets: IndexSet(integer: fromGlobal), toOffset: toGlobal)
                                    }
                                }
                            }
                        }
                    }
                    .navigationTitle("All Cards")
                    .navigationBarItems(
                        leading: EditButton(),
                        trailing: Button("Done") { showAllCardsSheet = false }
                    )
                }
                // MARK: - Card preview overlay (tap row to open, exit returns to list)
                if let doc = allCardsPreviewDocument {
                    AllCardsPreviewOverlay(
                        document: doc,
                        onDismiss: { withAnimation(.easeOut(duration: 0.2)) { allCardsPreviewDocument = nil } },
                        onEdit: { documentToEdit = doc },
                        onDelete: {
                            deleteDocument(doc)
                            allCardsPreviewDocument = nil
                        },
                        onShare: { shareDocument(doc) }
                    )
                    .transition(.opacity)
                    .zIndex(100)
                }
                if showAllCardsListTutorial {
                    TutorialBubbleOverlay(
                        message: "Switch cards on or off to show them on the stack. Tap any card to quick view it.",
                        targetFrame: .zero,
                        pointerEdge: .bottom,
                        preferredPointerEdge: .bottom,
                        listItemCount: documents.count,
                        listBubbleAboveFirstRow: true,
                        onDismiss: {
                            hasSeenAllCardsTutorial = true
                            showAllCardsListTutorial = false
                        }
                    )
                }
                if showMaxStackTutorial {
                    TutorialBubbleOverlay(
                        message: "The stack is full - only 6 cards at a time. Turn one off to add this card.",
                        targetFrame: .zero,
                        pointerEdge: .bottom,
                        preferredPointerEdge: .bottom,
                        listItemCount: documents.count,
                        listBubbleAboveFirstRow: true,
                        onDismiss: {
                            hasSeenMaxStackTutorial = true
                            showMaxStackTutorial = false
                        }
                    )
                }
            }
        }
        // MARK: - UPGRADE SHEET (Direct Access)
        .sheet(isPresented: $showUpgradeSheet) {
            ProUpgradeView()
        }
        .onChange(of: subscriptionManager.showUpgradeAnimation) { newValue in
            if newValue {
                // Return to home screen immediately
                showAllCardsSheet = false
                showSettingsSheet = false
                showQuickScanSheet = false
                showUpgradeSheet = false
                selectedTypeToAdd = nil
                documentToEdit = nil
                selectedID = nil
            }
        }
    }
    
    // MARK: - LOGIC
    
    /// Backfill stackOrderIndex for legacy docs (nil) so stack order is deterministic. Uses current array index (higher = newer).
    private func backfillStackOrderIndexIfNeeded() {
        guard documents.contains(where: { $0.stackOrderIndex == nil }) else { return }
        var updated = documents
        for i in updated.indices where updated[i].stackOrderIndex == nil {
            updated[i].stackOrderIndex = i
        }
        documents = updated
    }
    
    /// Keeps at most 6 cards on the main stack. Only when a 7th card is active, the oldest (lowest stackOrderIndex) is turned off.
    private func bumpLeastRecentActiveIfOverLimit() {
        let activeWithOrder = documents.enumerated()
            .filter(\.element.isActive)
            .map { (offset: $0.offset, order: $0.element.stackOrderIndex ?? $0.offset) }
        guard activeWithOrder.count > maxCardsOnStack else { return }
        let leastRecent = activeWithOrder.min(by: { $0.order < $1.order })!
        documents[leastRecent.offset].isActive = false
    }
    
    func deleteDocument(_ doc: TravelDocument) {
            
            
            withAnimation(.timingCurve(0.25, 0.1, 0.25, 1, duration: 0.35)) {
                if let index = documents.firstIndex(where: { $0.id == doc.id }) {
                    documents.remove(at: index)
                }
                
                selectedID = nil
        }
    }
    
    func startAdd(_ type: TravelDocument.DocumentType) {
        // Changed Check: Count total documents instead of just active ones
        selectedTypeToAdd = type
    }
    
    private func shareExpandedCard() {
        guard let doc = documents.first(where: { $0.id == selectedID }) else { return }
        shareDocument(doc)
    }
    
    private func shareDocument(_ doc: TravelDocument) {
        let image = renderCardSnapshot(document: doc)
        let fileURL = renderCardSnapshotToFile(document: doc)
        guard image != nil || fileURL != nil else { return }
        shareImage = image
        shareFileURL = fileURL
        showShareSheet = true
    }
    
    func toggleSelection(for id: UUID?) {
        if isHapticsEnabled {
            HapticManager.shared.triggerSelection()
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            if let id = id, selectedID == id {
                selectedID = nil
            } else {
                selectedID = id
            }
        }
    }
    
    // --- ROLODEX MATHS ---
    
    // Calculates where the card is in the loop (0 to totalScrollHeight)
    func getCircularPosition(for index: Int) -> CGFloat {
        // SAFETY: Avoid crash if all documents are deleted
        if totalScrollHeight == 0 { return 0 }
        
        let initialOffset = CGFloat(index) * cardSpacing
        let currentScroll = CGFloat(effectiveBaseScrollOffset) + dragOffset
        
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
        // Use fixed adjustment (from centred scroll only) so re-centring is correct and drag stays smooth.
        return position - stackCenterAdjustmentForCount
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
    
    /// Order of active card ids as they appear on the stack (newest first) for the reorder sheet.
    private func visualOrderForReorderSheet() -> [UUID] {
        stackOrderedDocuments.map(\.id)
    }
}

// MARK: - Reorder Stack (horizontal strips + shake, long-press on card opens this sheet)
private struct ReorderStackView: View {
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
        // Only update the stack order if the user actually reordered (don’t touch order on “Done” with no changes)
        guard orderedIDs != initialOrder else {
            onDismiss()
            return
        }
        let inactive = documents.filter { !$0.isActive }
        let count = orderedIDs.count
        let newActive = orderedIDs.enumerated().compactMap { (i, id) -> TravelDocument? in
            guard var doc = documents.first(where: { $0.id == id }) else { return nil }
            doc.stackOrderIndex = count - 1 - i
            return doc
        }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            documents = newActive + inactive
        }
        onDismiss()
    }
}

// Horizontal strip row with card colour + jiggle (iOS home screen–style edit shake)
private struct ReorderStripRow: View {
    let doc: TravelDocument
    let isHighlighted: Bool
    var minHeight: CGFloat = 56
    
    // Phase offset so rows don’t all shake in sync (derived from doc id)
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

// MARK: - All Cards Preview Overlay (opens card from list with full controls, returns to list on exit)
private struct AllCardsPreviewOverlay: View {
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
    
    @ViewBuilder
    private func cardView(isSelected: Bool) -> some View {
        let isPassport = (document.type == .passport)
        let isIDCard = (document.type == .idCard || document.type == .driversLicense || document.type == .studentID || document.type == .nationalInsurance)
        let isBoardingPass = (document.type == .boardingPass)
        let isVisa = (document.type == .visa)
        let isRewardsCard = (document.type == .rewardsCard)
        let isCarRental = (document.type == .carRental)
        let isMedicalAlert = (document.type == .medicalAlert)
        
        Group {
            if isPassport {
                PassportFlipCard(document: document, isSelected: isSelected, onTap: dismissCard)
            } else if isVisa {
                VisaFlipCard(document: document, isSelected: isSelected, onTap: dismissCard)
            } else if isMedicalAlert {
                MedicalFlipCard(document: document, isSelected: isSelected, onTap: dismissCard)
            } else if document.type == .vaccineRecord {
                VaccinationFlipCard(document: document, isSelected: isSelected, onTap: dismissCard)
            } else if document.type == .prescription {
                PrescriptionFlipCard(document: document, isSelected: isSelected, onTap: dismissCard)
            } else if document.type == .birthCertificate {
                BirthCertificateFlipCard(document: document, isSelected: isSelected, onTap: dismissCard)
            } else if document.type == .marriageCertificate {
                MarriageCertificateFlipCard(document: document, isSelected: isSelected, onTap: dismissCard)
            } else if isIDCard {
                IDFlipCard(document: document, isSelected: isSelected, onTap: dismissCard)
            } else if isBoardingPass {
                BoardingPassAnimatedCard(document: document, isSelected: isSelected, onTap: dismissCard)
            } else if isRewardsCard {
                RewardsAnimatedCard(document: document, isSelected: isSelected, onTap: dismissCard)
            } else if isCarRental {
                CarRentalAnimatedCard(document: document, isSelected: isSelected, onTap: dismissCard)
            } else if document.type == .hotelKeyCard {
                HotelKeyAnimatedCard(document: document, isSelected: isSelected, onTap: dismissCard)
            } else if document.type == .event {
                EventAnimatedCard(document: document, isSelected: isSelected, onTap: dismissCard)
            } else if [.petInsurance, .petVaccineRecord, .petPassport, .petID].contains(document.type) {
                PetAnimatedCard(document: document, isSelected: isSelected, onTap: dismissCard)
            } else if document.type == .insurance {
                InsuranceFlipCard(document: document, isSelected: isSelected, onTap: dismissCard)
            } else {
                DocumentCardView(document: document)
                    .onTapGesture { dismissCard() }
            }
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
                
                cardView(isSelected: isCardExpanded)
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

struct Bind_Previews: PreviewProvider {
    static var previews: some View {
        TravelDocsWalletView()
            // .preferredColorScheme(.dark)
    }
}