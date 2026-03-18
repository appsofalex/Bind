//
//  TutorialBubbleView.swift
//  Bind
//
//  First-time tutorial speech bubbles with blurred background.
//

import SwiftUI

// MARK: - Frame preference for positioning bubble relative to target view
struct TutorialTargetFrameKey: PreferenceKey {
    static var defaultValue: [Int: CGRect] = [:]
    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, b in b })
    }
}

extension View {
    /// Report this view's frame in the "tutorialSpace" coordinate space for tutorial bubble positioning.
    func reportTutorialFrame(tag: Int) -> some View {
        background(
            GeometryReader { geo in
                Color.clear
                    .preference(key: TutorialTargetFrameKey.self, value: [tag: geo.frame(in: .named("tutorialSpace"))])
            }
        )
    }
}

// MARK: - Speech bubble shape with pointer
struct SpeechBubbleShape: Shape {
    var pointerEdge: Edge
    /// When set, the pointer tip is drawn at this x (in shape local coords) so it can align with a target. Nil = center.
    var pointerTipX: CGFloat? = nil
    var cornerRadius: CGFloat = 16
    var pointerSize: CGFloat = 12
    var pointerInset: CGFloat = 24

    func path(in rect: CGRect) -> Path {
        let cr = min(cornerRadius, rect.width / 4, rect.height / 4)
        let bodyRect: CGRect
        let tipRect: CGRect

        switch pointerEdge {
        case .top:
            bodyRect = CGRect(x: rect.minX, y: rect.minY + pointerSize, width: rect.width, height: rect.height - pointerSize)
            let cx = pointerTipX ?? rect.midX
            let tipX = min(max(cx, rect.minX + pointerInset), rect.maxX - pointerInset)
            tipRect = CGRect(x: tipX - pointerSize, y: rect.minY, width: pointerSize * 2, height: pointerSize)
        case .bottom:
            bodyRect = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height - pointerSize)
            let cx = pointerTipX ?? rect.midX
            let tipX = min(max(cx, rect.minX + pointerInset), rect.maxX - pointerInset)
            tipRect = CGRect(x: tipX - pointerSize, y: rect.maxY - pointerSize, width: pointerSize * 2, height: pointerSize)
        case .leading:
            bodyRect = CGRect(x: rect.minX + pointerSize, y: rect.minY, width: rect.width - pointerSize, height: rect.height)
            let cy = rect.midY
            let tipY = min(max(cy, rect.minY + pointerInset), rect.maxY - pointerInset)
            tipRect = CGRect(x: rect.minX, y: tipY - pointerSize, width: pointerSize, height: pointerSize * 2)
        case .trailing:
            bodyRect = CGRect(x: rect.minX, y: rect.minY, width: rect.width - pointerSize, height: rect.height)
            let cy = rect.midY
            let tipY = min(max(cy, rect.minY + pointerInset), rect.maxY - pointerInset)
            tipRect = CGRect(x: rect.maxX - pointerSize, y: tipY - pointerSize, width: pointerSize, height: pointerSize * 2)
        }

        var path = Path()
        let bodyPath = RoundedRectangle(cornerRadius: cr).path(in: bodyRect)
        path.addPath(bodyPath)

        switch pointerEdge {
        case .top:
            path.move(to: CGPoint(x: tipRect.midX - pointerSize, y: tipRect.maxY))
            path.addLine(to: CGPoint(x: tipRect.midX, y: tipRect.minY))
            path.addLine(to: CGPoint(x: tipRect.midX + pointerSize, y: tipRect.maxY))
        case .bottom:
            path.move(to: CGPoint(x: tipRect.midX - pointerSize, y: tipRect.minY))
            path.addLine(to: CGPoint(x: tipRect.midX, y: tipRect.maxY))
            path.addLine(to: CGPoint(x: tipRect.midX + pointerSize, y: tipRect.minY))
        case .leading:
            path.move(to: CGPoint(x: tipRect.maxX, y: tipRect.midY - pointerSize))
            path.addLine(to: CGPoint(x: tipRect.minX, y: tipRect.midY))
            path.addLine(to: CGPoint(x: tipRect.maxX, y: tipRect.midY + pointerSize))
        case .trailing:
            path.move(to: CGPoint(x: tipRect.minX, y: tipRect.midY - pointerSize))
            path.addLine(to: CGPoint(x: tipRect.maxX, y: tipRect.midY))
            path.addLine(to: CGPoint(x: tipRect.minX, y: tipRect.midY + pointerSize))
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Tutorial bubble overlay
struct TutorialBubbleOverlay: View {
    let message: String
    var targetFrame: CGRect = .zero
    var pointerEdge: Edge = .bottom
    /// When false, renders as a simple rounded rectangle (no spike).
    var showsPointer: Bool = true
    /// When no target: 0 = top, 0.5 = center, 1 = bottom. Default 0.28 for card stack; use ~0.45 for sheet.
    var preferredVerticalFraction: Double = 0.28
    /// When no target: which edge the spike is on. Default .bottom (spike points down). Use .top for spike on top pointing up.
    var preferredPointerEdge: Edge = .bottom
    /// When set (e.g. All Cards list), position bubble just below that many list rows so it sits under the content.
    var listItemCount: Int? = nil
    /// When true with listItemCount set, position bubble above the first list row with spike pointing down.
    var listBubbleAboveFirstRow: Bool = false
    /// Optional nudge for the pointer tip (e.g. +10 to shift spike right, -10 to shift left).
    var pointerTipOffsetX: CGFloat = 0
    /// Optional automatic dismiss timer; when set, bubble will dismiss after this many seconds.
    var autoDismissAfter: TimeInterval? = nil
    let onDismiss: () -> Void

    // Background dim
    @State private var overlayOpacity: Double = 0.0
    // Energetic bounce pop-in (start small, overshoot slightly, settle)
    @State private var bubbleScale: CGFloat = 0.72
    @State private var bubbleOpacity: Double = 0.0
    @State private var bubbleOffsetY: CGFloat = 14
    // Lock tap-to-dismiss for first couple of seconds
    @State private var canDismiss: Bool = false
    @State private var isDismissing: Bool = false

    private let bubblePadding: CGFloat = 20
    private let maxBubbleWidth: CGFloat = 280
    private let pointerSize: CGFloat = 12
    private let gapFromTarget: CGFloat = 12
    private let bubbleMinHeight: CGFloat = 72

    var body: some View {
        GeometryReader { geo in
            let safeSize = geo.size
            let targetMid = targetFrame.size.width > 0
                ? CGPoint(x: targetFrame.midX, y: targetFrame.midY)
                : CGPoint(x: safeSize.width / 2, y: safeSize.height / 2)

            ZStack {
                Rectangle()
                    .fill(Color.black.opacity(0.18 * overlayOpacity))
                    .ignoresSafeArea()

                bubbleView(safeSize: safeSize, targetMid: targetMid)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if canDismiss {
                    triggerDismiss()
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 0.55)) {
                    overlayOpacity = 1.0
                }
                bubbleScale = 0.72
                bubbleOpacity = 0.0
                bubbleOffsetY = 14
                // Single energetic bounce: small + float-up → slight overshoot → settle (playful, noticeable)
                withAnimation(.spring(response: 0.38, dampingFraction: 0.62)) {
                    bubbleOpacity = 1.0
                    bubbleScale = 1.0
                    bubbleOffsetY = 0
                }
                canDismiss = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    canDismiss = true
                }
                if let delay = autoDismissAfter {
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        triggerDismiss()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func bubbleView(safeSize: CGSize, targetMid: CGPoint) -> some View {
        let (bubbleRect, edge): (CGRect, Edge) = positionedBubble(safeSize: safeSize, targetMid: targetMid)
        let pointerTipXLocal: CGFloat? = (showsPointer && targetFrame.size.width > 0 && (edge == .bottom || edge == .top))
            ? (targetMid.x - bubbleRect.minX + pointerTipOffsetX)
            : nil
        let textVerticalOffset: CGFloat = showsPointer
            ? (edge == .bottom ? -pointerSize / 2 : (edge == .top ? pointerSize / 2 : 0))
            : 0

        Text(message)
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.primary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: min(maxBubbleWidth, bubbleRect.width), alignment: .center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(bubblePadding)
            .offset(y: textVerticalOffset)
            .frame(width: bubbleRect.width, height: bubbleRect.height)
            .background {
                if showsPointer {
                    SpeechBubbleShape(pointerEdge: edge, pointerTipX: pointerTipXLocal, cornerRadius: 16, pointerSize: pointerSize, pointerInset: 24)
                        .fill(Color(.secondarySystemBackground))
                        .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 3)
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemBackground))
                        .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 3)
                }
            }
            .scaleEffect(bubbleScale)
            .opacity(bubbleOpacity)
            .offset(y: bubbleOffsetY)
            .position(x: bubbleRect.midX, y: bubbleRect.midY)
    }

    private func triggerDismiss() {
        guard !isDismissing else { return }
        isDismissing = true
        canDismiss = false

        withAnimation(.easeOut(duration: 0.22)) {
            overlayOpacity = 0.0
        }
        withAnimation(.spring(response: 0.30, dampingFraction: 0.88)) {
            bubbleOpacity = 0.0
            bubbleScale = 0.84
            bubbleOffsetY = 12
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
            onDismiss()
        }
    }

    private func positionedBubble(safeSize: CGSize, targetMid: CGPoint) -> (CGRect, Edge) {
        let hasTarget = targetFrame.size.width > 0 && targetFrame.size.height > 0
        let edge: Edge
        let bubbleW = min(maxBubbleWidth, safeSize.width - 48)
        let bubbleH: CGFloat = max(bubbleMinHeight, 88)
        let effectivePointerSize: CGFloat = showsPointer ? pointerSize : 0

        if !hasTarget {
            let x = (safeSize.width - bubbleW) / 2
            let y: CGFloat
            if let count = listItemCount, count > 0 {
                let listTop: CGFloat = 100
                let listRowHeight: CGFloat = 52
                let gap = gapFromTarget + effectivePointerSize
                if listBubbleAboveFirstRow {
                    edge = .bottom
                    y = listTop - gap - bubbleH / 2
                    let minY = bubbleH / 2 + 24
                    let clampedY = max(y, minY)
                    return (CGRect(x: x, y: clampedY, width: bubbleW, height: bubbleH), edge)
                } else {
                    edge = preferredPointerEdge
                    let listContentBottom = listTop + CGFloat(count) * listRowHeight
                    y = listContentBottom + gap + bubbleH / 2
                    let maxY = safeSize.height - bubbleH / 2 - 24
                    let clampedY = min(y, maxY)
                    return (CGRect(x: x, y: clampedY, width: bubbleW, height: bubbleH), edge)
                }
            } else {
                edge = preferredPointerEdge
                y = safeSize.height * preferredVerticalFraction - bubbleH / 2
                return (CGRect(x: x, y: y, width: bubbleW, height: bubbleH), edge)
            }
        }

        let gap = gapFromTarget + effectivePointerSize
        let inBottomBar = targetMid.y > safeSize.height * 0.72

        if inBottomBar {
            edge = .bottom
            let aboveY = targetMid.y - bubbleH - gap
            let y = max(24, aboveY)
            let x = max(24, min(targetMid.x - bubbleW / 2, safeSize.width - bubbleW - 24))
            return (CGRect(x: x, y: y, width: bubbleW, height: bubbleH), edge)
        }

        let aboveY = targetMid.y - bubbleH - gap
        let belowY = targetMid.y + gap
        let leftX = targetMid.x - bubbleW - gap
        let rightX = targetMid.x + gap

        if aboveY >= 24 {
            edge = .bottom
            let x = max(24, min(targetMid.x - bubbleW / 2, safeSize.width - bubbleW - 24))
            return (CGRect(x: x, y: aboveY, width: bubbleW, height: bubbleH), edge)
        }
        if belowY + bubbleH <= safeSize.height - 40 {
            edge = .top
            let x = max(24, min(targetMid.x - bubbleW / 2, safeSize.width - bubbleW - 24))
            return (CGRect(x: x, y: belowY, width: bubbleW, height: bubbleH), edge)
        }
        if rightX + bubbleW <= safeSize.width - 24 {
            edge = .leading
            let y = max(24, min(targetMid.y - bubbleH / 2, safeSize.height - bubbleH - 40))
            return (CGRect(x: rightX, y: y, width: bubbleW, height: bubbleH), edge)
        }
        edge = .trailing
        let y = max(24, min(targetMid.y - bubbleH / 2, safeSize.height - bubbleH - 40))
        return (CGRect(x: leftX, y: y, width: bubbleW, height: bubbleH), edge)
    }
}
