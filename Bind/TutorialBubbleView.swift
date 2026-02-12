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
            let cx = rect.midX
            let tipX = min(max(cx, rect.minX + pointerInset), rect.maxX - pointerInset)
            tipRect = CGRect(x: tipX - pointerSize, y: rect.minY, width: pointerSize * 2, height: pointerSize)
        case .bottom:
            bodyRect = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height - pointerSize)
            let cx = rect.midX
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
    let onDismiss: () -> Void

    // Controls how strongly the background is dimmed.
    // Starts at 0 and animates up for a subtle fade-in.
    @State private var overlayOpacity: Double = 0.0
    // Fun entrance animation for the speech bubble itself
    @State private var bubbleScale: CGFloat = 0.8
    @State private var bubbleOpacity: Double = 0.0
    // Prevent dismissal for the first couple of seconds
    @State private var canDismiss: Bool = false

    private let bubblePadding: CGFloat = 20
    private let maxBubbleWidth: CGFloat = 280
    private let pointerSize: CGFloat = 12
    private let gapFromTarget: CGFloat = 8

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
                    onDismiss()
                }
            }
            .onAppear {
                // Smoothly fade in the dim background over a couple of seconds.
                withAnimation(.easeInOut(duration: 2.0)) {
                    overlayOpacity = 1.0
                }

                // Fun bubble pop-in: fade + gentle bounce
                bubbleScale = 0.8
                bubbleOpacity = 0.0
                withAnimation(.easeOut(duration: 0.35)) {
                    bubbleOpacity = 1.0
                    bubbleScale = 1.05
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        bubbleScale = 1.0
                    }
                }

                // Lock interaction for ~2.5 seconds before allowing dismiss.
                canDismiss = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    canDismiss = true
                }
            }
        }
    }

    @ViewBuilder
    private func bubbleView(safeSize: CGSize, targetMid: CGPoint) -> some View {
        let (bubbleRect, edge): (CGRect, Edge) = positionedBubble(safeSize: safeSize, targetMid: targetMid)
        Text(message)
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.primary)
            .multilineTextAlignment(.center)
            .padding(bubblePadding)
            .frame(width: min(maxBubbleWidth, bubbleRect.width), alignment: .center)
            .background(
                SpeechBubbleShape(pointerEdge: edge, cornerRadius: 16, pointerSize: pointerSize, pointerInset: 24)
                    .fill(Color(.secondarySystemBackground))
                    .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 4)
            )
            .scaleEffect(bubbleScale)
            .opacity(bubbleOpacity)
            .position(x: bubbleRect.midX, y: bubbleRect.midY)
    }

    private func positionedBubble(safeSize: CGSize, targetMid: CGPoint) -> (CGRect, Edge) {
        let hasTarget = targetFrame.size.width > 0 && targetFrame.size.height > 0
        let edge: Edge
        let bubbleW = min(maxBubbleWidth, safeSize.width - 40)
        let bubbleH: CGFloat = 80

        if !hasTarget {
            edge = .bottom
            let x = (safeSize.width - bubbleW) / 2
            let y = safeSize.height * 0.35 - bubbleH / 2
            return (CGRect(x: x, y: y, width: bubbleW, height: bubbleH), edge)
        }

        let gap = gapFromTarget + pointerSize
        let aboveY = targetMid.y - bubbleH - gap
        let belowY = targetMid.y + gap
        let leftX = targetMid.x - bubbleW - gap
        let rightX = targetMid.x + gap

        if aboveY >= 20 {
            edge = .bottom
            let x = max(20, min(targetMid.x - bubbleW / 2, safeSize.width - bubbleW - 20))
            let y = aboveY
            return (CGRect(x: x, y: y, width: bubbleW, height: bubbleH), edge)
        }
        if belowY + bubbleH <= safeSize.height - 40 {
            edge = .top
            let x = max(20, min(targetMid.x - bubbleW / 2, safeSize.width - bubbleW - 20))
            return (CGRect(x: x, y: belowY, width: bubbleW, height: bubbleH), edge)
        }
        if rightX + bubbleW <= safeSize.width - 20 {
            edge = .leading
            let y = max(20, min(targetMid.y - bubbleH / 2, safeSize.height - bubbleH - 40))
            return (CGRect(x: rightX, y: y, width: bubbleW, height: bubbleH), edge)
        }
        edge = .trailing
        let y = max(20, min(targetMid.y - bubbleH / 2, safeSize.height - bubbleH - 40))
        return (CGRect(x: leftX, y: y, width: bubbleW, height: bubbleH), edge)
    }
}
