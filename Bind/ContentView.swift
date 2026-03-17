import SwiftUI

// MARK: - MAIN WALLET VIEW
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
    @State private var sharePayload: SharePayload? = nil
    
    // TUTORIAL STATE (first-time prompts)
    @AppStorage("hasSeenFirstCardTutorial") private var hasSeenFirstCardTutorial = false
    @AppStorage("hasSeenSixthCardTutorial") private var hasSeenSixthCardTutorial = false
    @AppStorage("hasSeenAllCardsTutorial") private var hasSeenAllCardsTutorial = false
    @AppStorage("hasSeenSettingsTutorial") private var hasSeenSettingsTutorial = false
    @AppStorage("hasSeenMaxStackTutorial") private var hasSeenMaxStackTutorial = false
    @AppStorage("hasSeenQuickScanTutorial") private var hasSeenQuickScanTutorial = false
    @AppStorage("hasSeenReorderTutorial") private var hasSeenReorderTutorial = false
    @AppStorage("hasSeenAddMenuTutorial") private var hasSeenAddMenuTutorial = false
    @State private var showFirstCardTutorial = false
    @State private var showSixthCardTutorial = false
    @State private var showSettingsTutorial = false
    @State private var showAllCardsListTutorial = false
    @State private var showMaxStackTutorial = false
    @State private var showQuickScanTutorial = false
    @State private var showReorderTutorial = false
    @State private var showAddMenuTutorial = false
    @State private var allCardsButtonFrame: CGRect = .zero
    @State private var settingsButtonFrame: CGRect = .zero
    @State private var quickScanButtonFrame: CGRect = .zero
    @State private var topCardFrame: CGRect = .zero
    @State private var addMenuButtonFrame: CGRect = .zero
    
    // Scroll/Drag State
    @AppStorage("walletScrollOffset") private var baseScrollOffset: Double = 0
    @State private var dragOffset: CGFloat = 0
    /// When set (e.g. right after adding a card), forces the stack to show this offset so the newest card is at front. Cleared when user drags.
    @State private var scrollOffsetForNewCard: Double? = nil
    
    // Reorder stack sheet (long-press on card opens exposé-style reorder)
    @State private var showReorderStackSheet = false
    @State private var longPressedDocumentID: UUID? = nil
    @State private var reorderStackInitialOrder: [UUID] = []
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
    
    private var stackOrderedDocuments: [TravelDocument] {
        let active = activeDocuments
        let orderById = Dictionary(uniqueKeysWithValues: documents.enumerated().map { ($0.element.id, $0.offset) })
        return active.sorted { (orderById[$0.id] ?? 0) > (orderById[$1.id] ?? 0) }
    }
    
    private var effectiveBaseScrollOffset: Double {
        scrollOffsetForNewCard ?? baseScrollOffset
    }
    
    private func centeredScrollOffset(for activeCount: Int) -> Double {
        guard activeCount > 0 else { return 0 }
        let total = Double(activeCount) * Double(cardSpacing)
        return total - Double(cardSpacing) / 2
    }
    
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
    
    // Split complex body into smaller, focused subviews to help the type-checker.
    @ViewBuilder
    private var backgroundLayer: some View {
        Group {
            if colorScheme == .dark {
                Color(red: 0.11, green: 0.11, blue: 0.12)
            } else {
                Color(red: 0.96, green: 0.96, blue: 0.97)
            }
        }
        .ignoresSafeArea()
    }
    
    @ViewBuilder
    private var emptyStateLayer: some View {
        if documents.isEmpty {
            EmptyWalletView()
                .transition(.opacity)
                .zIndex(0)
        }
    }
    
    @ViewBuilder
    private var mainCardAndOverlaysLayer: some View {
        // MARK: - 1. MAIN CARD AREA (Now Full Screen Background)
        GeometryReader { geo in
            ZStack(alignment: .center) {
                ForEach(Array(stackOrderedDocuments.enumerated()), id: \.element.id) { index, doc in
                    
                    // 1. CALCULATE DYNAMIC POSITION
                    let targetPos = getCircularPosition(for: index)
                    let isSelected = (selectedID == doc.id)
                    
                    WalletPositionSmoother(target: targetPos, totalHeight: totalScrollHeight) { currentPos in
                        WalletCardView(
                            document: doc,
                            isSelected: isSelected,
                            onTap: { toggleSelection(for: doc.id) }
                        )
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
                    // Native Plus Menu with dropdown sections; style headers a bit bolder
                    Menu {
                        Section {
                            Button(action: { startAdd(.passport) }) { Label("Passport", systemImage: "globe") }
                            Button(action: { startAdd(.boardingPass) }) { Label("Boarding Pass", systemImage: "airplane") }
                            Button(action: { startAdd(.carRental) }) { Label("Car Rental", systemImage: "car.2.fill") }
                            Button(action: { startAdd(.hotelKeyCard) }) { Label("Hotel Key Card", systemImage: "key.fill") }
                            Button(action: { startAdd(.visa) }) { Label("Visa", systemImage: "checkmark.seal") }
                        } header: {
                            Text("Travel")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .textCase(nil)
                        }
                        Section {
                            Button(action: { startAdd(.driversLicense) }) { Label("Driver's License", systemImage: "car") }
                            Button(action: { startAdd(.studentID) }) { Label("Student ID", systemImage: "graduationcap") }
                            Button(action: { startAdd(.idCard) }) { Label("National ID", systemImage: "person.text.rectangle") }
                            Button(action: { startAdd(.nationalInsurance) }) { Label("National ID Number", systemImage: "number.square.fill") }
                        } header: {
                            Text("Identity")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .textCase(nil)
                        }
                        
                        Section {
                            Button(action: { startAdd(.prescription) }) { Label("Prescription", systemImage: "pills") }
                            Button(action: { startAdd(.vaccineRecord) }) { Label("Vaccination", systemImage: "syringe") }
                            Button(action: { startAdd(.medicalAlert) }) { Label("Blood & Allergies", systemImage: "staroflife") }
                            Button(action: { startAdd(.insurance) }) { Label("Insurance", systemImage: "cross.case") }
                        } header: {
                            Text("Health")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .textCase(nil)
                        }
                        
                        Section {
                            Button(action: { startAdd(.petInsurance) }) { Label("Pet Insurance", systemImage: "cross.case.fill") }
                            Button(action: { startAdd(.petVaccineRecord) }) { Label("Pet Vaccination", systemImage: "syringe.fill") }
                            Button(action: { startAdd(.petPassport) }) { Label("Pet Passport", systemImage: "pawprint.fill") }
                            Button(action: { startAdd(.petID) }) { Label("Pet ID", systemImage: "pawprint.fill") }
                        } header: {
                            Text("Pets")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .textCase(nil)
                        }
                        
                        Section {
                            Button(action: { startAdd(.birthCertificate) }) { Label("Birth Certificate", systemImage: "stroller.fill") }
                            Button(action: { startAdd(.marriageCertificate) }) { Label("Marriage Certificate", systemImage: "figure.and.child.holdinghands") }
                            Button(action: { startAdd(.rewardsCard) }) { Label("Rewards Card", systemImage: "star.fill") }
                            Button(action: { startAdd(.event) }) { Label("Event", systemImage: "ticket.fill") }
                        } header: {
                            Text("Other")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .textCase(nil)
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 32))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundColor(.white)
                            .background(Color.black.opacity(0.5).clipShape(Circle()))
                            .reportTutorialFrame(tag: 5)
                    }
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onEnded { _ in
                                if !hasSeenAddMenuTutorial && !showAddMenuTutorial {
                                    showAddMenuTutorial = true
                                }
                            }
                    )
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
                                Image(systemName: "camera.fill")
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
                message: "These are your cards. Add up to six and watch them stack up here.",
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
                message: "Tap the camera to quickly add a card by scanning a barcode or ticket.",
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
        if showAddMenuTutorial {
            TutorialBubbleOverlay(
                message: "Scroll to explore all the card categories!",
                targetFrame: .zero,
                preferredVerticalFraction: 0.80,
                preferredPointerEdge: .top,
                autoDismissAfter: 4.0,
                onDismiss: {
                    hasSeenAddMenuTutorial = true
                    showAddMenuTutorial = false
                }
            )
            .zIndex(300)
        }
    }
    
    var body: some View {
        ZStack {
            backgroundLayer
            emptyStateLayer
            mainCardAndOverlaysLayer
        }
        .coordinateSpace(name: "tutorialSpace")
        .onPreferenceChange(TutorialTargetFrameKey.self) { dict in
            if let r = dict[1] { allCardsButtonFrame = r }
            if let r = dict[2] { settingsButtonFrame = r }
            if let r = dict[3] { quickScanButtonFrame = r }
            if let r = dict[4] { topCardFrame = r }
            if let r = dict[5] { addMenuButtonFrame = r }
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
            // Backfill any nil stackOrderIndex so sort order is deterministic (newest = highest index).
            if newValue.contains(where: { $0.stackOrderIndex == nil }) {
                backfillStackOrderIndexIfNeeded()
            }
            // Re-center the stack when the number of active cards changes (add/remove/toggle) so newest is at front.
            let activeCount = newValue.filter(\.isActive).count
            let countChanged = (activeCount != lastAppliedActiveCount)
            if countChanged {
                lastAppliedActiveCount = activeCount
                let offset = centeredScrollOffset(for: activeCount)
                baseScrollOffset = offset
                scrollOffsetForNewCard = offset
            }
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
                    documents.append(newDoc)
                    bumpLeastRecentActiveIfOverLimit()
                    dragOffset = 0
                    let count = documents.filter(\.isActive).count
                    let offset = centeredScrollOffset(for: count)
                    baseScrollOffset = offset
                    scrollOffsetForNewCard = offset
                }
                // Apply scroll again after layout so the new card is guaranteed at front (fixes timing with stack re-render).
                DispatchQueue.main.async {
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
        .sheet(item: $sharePayload) { payload in
            ShareSheet(payload: payload)
                .onDisappear {
                    if let url = payload.fileURL {
                        try? FileManager.default.removeItem(at: url)
                    }
                }
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
    
    /// Keeps at most 6 cards on the main stack. When a 7th is active, turn off the one with the smallest array index (oldest in list = back of stack).
    private func bumpLeastRecentActiveIfOverLimit() {
        let activeIndices = documents.enumerated().filter(\.element.isActive)
        guard activeIndices.count > maxCardsOnStack else { return }
        let leastRecent = activeIndices.min(by: { $0.offset < $1.offset })!
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
        if showAddMenuTutorial {
            hasSeenAddMenuTutorial = true
            showAddMenuTutorial = false
        }
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
        sharePayload = SharePayload(fileURL: fileURL, image: image)
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
    
    /// Order of active card ids as they appear on the stack (newest/front first) for the reorder sheet.
    private func visualOrderForReorderSheet() -> [UUID] {
        stackOrderedDocuments.map(\.id)
    }
}


struct Bind_Previews: PreviewProvider {
    static var previews: some View {
        TravelDocsWalletView()
            // .preferredColorScheme(.dark)
    }
}
