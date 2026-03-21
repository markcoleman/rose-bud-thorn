import SwiftUI
import Foundation

public struct OnboardingFlowView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var controller: OnboardingFlowController
    @State private var slideTransitionEdge: Edge = .trailing
    @State private var timerTask: Task<Void, Never>?

    private let slides: [OnboardingSlide]
    private let analyticsStore: LocalAnalyticsStore
    private let onDismiss: (OnboardingDismissReason) -> Void

    public init(
        slides: [OnboardingSlide] = OnboardingSlide.defaultSlides,
        countdownSeconds: Int = OnboardingFlowController.defaultCountdownSeconds,
        analyticsStore: LocalAnalyticsStore,
        onDismiss: @escaping (OnboardingDismissReason) -> Void
    ) {
        self.slides = slides
        self.analyticsStore = analyticsStore
        self.onDismiss = onDismiss
        _controller = State(initialValue: OnboardingFlowController(
            slideCount: slides.count,
            countdownDuration: countdownSeconds
        ))
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                if slides.isEmpty {
                    Color.clear
                        .ignoresSafeArea()
                } else {
                    slideBackground(currentSlide)
                        .id(currentSlide.id)
                        .transition(slideTransition)
                        .animation(
                            reduceMotion ? .easeInOut(duration: 0.14) : MotionTokens.tabSwitch,
                            value: controller.selectedIndex
                        )
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .ignoresSafeArea()

                    VStack(spacing: 0) {
                        topBar
                        Spacer(minLength: 0)
                        bottomPanel
                    }
                    .frame(
                        maxWidth: contentContainerWidth(for: geometry.size.width),
                        maxHeight: .infinity,
                        alignment: .top
                    )
                    .padding(.horizontal, contentHorizontalPadding(for: geometry.size.width))
                    .padding(.top, contentTopPadding(for: geometry.size.width))
                    .padding(.bottom, contentBottomPadding(for: geometry.size.width))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .contentShape(Rectangle())
        .gesture(swipeGesture)
        .onAppear {
            guard !slides.isEmpty else {
                onDismiss(.completed)
                return
            }
            record(.onboardingStarted)
            recordCurrentSlideView()
            controller.resetCountdown()
            startTimer()
        }
        .onDisappear {
            cancelTimer()
        }
        .onChange(of: scenePhase) { _, phase in
            handleScenePhaseChange(phase)
        }
        .onChange(of: controller.selectedIndex) { _, _ in
            recordCurrentSlideView()
        }
    }

    private var currentSlide: OnboardingSlide {
        slides[controller.selectedIndex]
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            if controller.isOnLastSlide {
                Color.clear
                    .frame(width: 70, height: ControlTokens.minTouchTarget)
            } else {
                Button("Skip") {
                    controller.registerInteraction()
                    dismiss(.skipped)
                }
                .touchTargetMinSize(ControlTokens.minTouchTarget)
                .buttonStyle(.bordered)
                .tint(.white.opacity(0.9))
                .foregroundStyle(.white)
                .accessibilityIdentifier("onboarding-skip")
                .accessibilityLabel("Skip onboarding")
            }

            Spacer(minLength: 0)

            HStack(spacing: 10) {
                countdownBadge
                if controller.isOnLastSlide {
                    Button {
                        controller.registerInteraction()
                        dismiss(.closed)
                    } label: {
                        Image(systemName: AppIcon.close.systemName)
                            .font(.headline.weight(.semibold))
                            .frame(width: 28, height: 28)
                    }
                    .touchTargetMinSize(ControlTokens.minTouchTarget)
                    .buttonStyle(.bordered)
                    .tint(.white.opacity(0.92))
                    .foregroundStyle(.black.opacity(0.7))
                    .accessibilityIdentifier("onboarding-close")
                    .accessibilityLabel("Close onboarding")
                }
            }
        }
    }

    private var countdownBadge: some View {
        Text("\(max(controller.countdown, 1))s")
            .font(.subheadline.weight(.semibold))
            .monospacedDigit()
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial, in: Capsule())
            .accessibilityIdentifier("onboarding-countdown")
            .accessibilityLabel("Auto-advance in \(max(controller.countdown, 1)) seconds")
    }

    private var bottomPanel: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 12) {
                Text(currentSlide.headline)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(DesignTokens.textPrimaryOnSurface)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .minimumScaleFactor(0.8)

                Text(currentSlide.body)
                    .font(.body)
                    .foregroundStyle(DesignTokens.textSecondaryOnSurface)
                    .multilineTextAlignment(.leading)
                    .lineLimit(4)
                    .minimumScaleFactor(0.85)

                Button(actionTitle) {
                    controller.registerInteraction()
                    if controller.isOnLastSlide {
                        dismiss(.completed)
                    } else {
                        moveToAdjacentSlide(step: 1)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(currentSlide.themeColor)
                .touchTargetMinSize(ControlTokens.minTouchTarget)
                .frame(maxWidth: .infinity, alignment: .center)
                .accessibilityIdentifier(controller.isOnLastSlide ? "onboarding-start" : "onboarding-next")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(DesignTokens.surfaceElevated.opacity(0.98))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(currentSlide.themeColor.opacity(0.22), lineWidth: 1)
            )

            pageIndicator
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<slides.count, id: \.self) { index in
                Circle()
                    .fill(index == controller.selectedIndex ? currentSlide.themeColor : Color.white.opacity(0.6))
                    .frame(width: index == controller.selectedIndex ? 9 : 7, height: index == controller.selectedIndex ? 9 : 7)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Page \(controller.selectedIndex + 1) of \(slides.count)")
        .accessibilityIdentifier("onboarding-page-indicator")
    }

    private var actionTitle: String {
        controller.isOnLastSlide ? "Start Reflecting" : "Next"
    }

    private func contentContainerWidth(for width: CGFloat) -> CGFloat {
        switch width {
        case ..<760:
            return .infinity
        case ..<1024:
            return 620
        default:
            return 700
        }
    }

    private func contentHorizontalPadding(for width: CGFloat) -> CGFloat {
        switch width {
        case ..<500:
            return 20
        case ..<900:
            return 24
        default:
            return 32
        }
    }

    private func contentTopPadding(for width: CGFloat) -> CGFloat {
        width >= 900 ? 18 : 12
    }

    private func contentBottomPadding(for width: CGFloat) -> CGFloat {
        width >= 900 ? 28 : 22
    }

    private func slideBackground(_ slide: OnboardingSlide) -> some View {
        ZStack {
            Image(slide.imageName)
                .resizable()
                .scaledToFill()
                .clipped()

            LinearGradient(
                colors: [
                    .black.opacity(0.22),
                    .black.opacity(0.05),
                    .black.opacity(0.38),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private func startTimer() {
        cancelTimer()
        timerTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled {
                    return
                }
                await MainActor.run {
                    handleTimerTick()
                }
            }
        }
    }

    private func cancelTimer() {
        timerTask?.cancel()
        timerTask = nil
    }

    private func handleTimerTick() {
        let outcome = controller.tick()
        switch outcome {
        case .none:
            break
        case .autoAdvanced:
            moveToAdjacentSlide(step: 1, isAutomatic: true)
        case .autoCompleted:
            dismiss(.autoCompleted)
        }
    }

    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            controller.resetCountdown()
            startTimer()
        case .inactive, .background:
            cancelTimer()
        @unknown default:
            cancelTimer()
        }
    }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 18, coordinateSpace: .local)
            .onEnded { value in
                handleSwipe(value)
            }
    }

    private var slideTransition: AnyTransition {
        if reduceMotion {
            return .opacity
        }

        return .asymmetric(
            insertion: .move(edge: slideTransitionEdge).combined(with: .opacity),
            removal: .move(edge: oppositeEdge(for: slideTransitionEdge)).combined(with: .opacity)
        )
    }

    private func oppositeEdge(for edge: Edge) -> Edge {
        switch edge {
        case .top: return .bottom
        case .bottom: return .top
        case .leading: return .trailing
        case .trailing: return .leading
        }
    }

    private func handleSwipe(_ value: DragGesture.Value) {
        let horizontal = value.translation.width
        let vertical = value.translation.height
        let horizontalDominant = abs(horizontal) > abs(vertical) * 1.2
        guard horizontalDominant, abs(horizontal) >= 50 else { return }

        controller.registerInteraction()
        if horizontal < 0 {
            moveToAdjacentSlide(step: 1)
        } else {
            moveToAdjacentSlide(step: -1)
        }
    }

    private func moveToAdjacentSlide(step: Int, isAutomatic: Bool = false) {
        let nextIndex = controller.selectedIndex + step
        guard slides.indices.contains(nextIndex) else { return }

        slideTransitionEdge = step > 0 ? .trailing : .leading
        withPageAnimation {
            controller.selectSlide(at: nextIndex)
        }

        if isAutomatic {
            record(.onboardingAutoAdvanced)
        }
    }

    private func dismiss(_ reason: OnboardingDismissReason) {
        cancelTimer()
        onDismiss(reason)
    }

    private func withPageAnimation(_ changes: () -> Void) {
        if reduceMotion {
            withAnimation(.easeInOut(duration: 0.14), changes)
        } else {
            withAnimation(MotionTokens.tabSwitch, changes)
        }
    }

    private func recordCurrentSlideView() {
        guard slides.indices.contains(controller.selectedIndex) else { return }
        let event: LocalAnalyticsEvent
        switch slides[controller.selectedIndex].id {
        case "rose":
            event = .onboardingRoseViewed
        case "bud":
            event = .onboardingBudViewed
        case "thorn":
            event = .onboardingThornViewed
        default:
            return
        }
        record(event)
    }

    private func record(_ event: LocalAnalyticsEvent) {
        Task {
            await analyticsStore.record(event)
        }
    }
}
