import SwiftUI

/// Helper view with not much use for now.
private struct Page<Content>: View where Content: View {
    private let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        VStack {
            content()
        }
    }
}

@_functionBuilder
public struct PageBuilder {
    public static func buildBlock<T: View>(_ children: T...) -> [T] {
        children
    }
}

/// Describes styling used to position elements/pages or alter
/// visual aspects of the pager (such as the animation used to
/// smooth out positioning, scale, etc).
public struct PagerStyle {
    public static let `default` = PagerStyle()

    let interPagePadding: CGFloat
    let pageSize: CGSize
    let maxPageNumber: Int
    let focusedScale: CGFloat
    let unfocusedScale: CGFloat

    let animation: Animation

    public init(interPagePadding: CGFloat = 20,
         pageSize: CGSize = .init(width: 300, height: 500),
         maxPage: Int = 20,
         focusedScale: CGFloat = 1,
         unfocusedScale: CGFloat = 0.85,
         animation: Animation = .interpolatingSpring(stiffness: 300, damping: 300, initialVelocity: 20)) {
        self.interPagePadding = interPagePadding
        self.pageSize = pageSize
        self.maxPageNumber = maxPage
        self.focusedScale = focusedScale
        self.unfocusedScale = unfocusedScale
        self.animation = animation
    }
}

private extension PagerStyle {
    var pageOffset: CGFloat { self.pageSize.width + self.interPagePadding }
    var largePageOffset: CGFloat { self.pageOffset * CGFloat(self.maxPageNumber + 1)  }
}

private extension View {
    func visibility(visible: Bool) -> some View {
        Group {
            if visible {
                self
            } else {
                self.hidden()
            }
        }
    }
}

public struct Pager<Content>: View where Content: View {
    private let views: [Page<Content>]
    private let style: PagerStyle
    @State private var activeWindow: ActiveWindow?
    @GestureState private var dragState = DragState.inactive

    public init(
        style: PagerStyle = PagerStyle.default,
        @PageBuilder pages: @escaping () -> [Content]
    ) {
        views = pages().map { view in Page { view } }
        self.style = style
    }

    public var body: some View {
        ZStack {
            ForEach(Array(self.views.enumerated()), id: \.offset) { pair in
                AnyView(pair.element)
                    .offset(x: self.elementOffset(pair.offset))
                    .animation(self.style.animation)
                    .scaleEffect(self.elementScale(pair.offset))
                    .animation(self.style.animation)
                    .zIndex(self.elementZIndex(pair.offset))
                    .animation(self.style.animation)
                    .visibility(visible: self.elementVisibility(pair.offset))
            }
        }.gesture(
            DragGesture()
                .updating(self.$dragState) { drag, state, _ in
                    state = .active(translation: drag.translation)
            }.onEnded(self.dragEnded)
        ).onAppear { self.loadPages() }
    }

    private func loadPages() {
        activeWindow = ActiveWindow(activeIndex: 0, upperBound: views.count)
    }

    private func dragEnded(value: DragGesture.Value) {
        guard let window = activeWindow else { return }
        let halfway = style.pageSize.width * 0.51
        var active = window.active
        if value.predictedEndTranslation.width > halfway
            || value.translation.width > halfway {
            if active - 1 >= 0 {
                active = active - 1
            }
        } else if value.predictedEndTranslation.width < -halfway
            || value.translation.width < -halfway {
            if active + 1 < window.upperBound {
                active = active + 1
            }
        }
        activeWindow = activeWindow?.update(active: active)
    }

    private func elementOffset(_ index: Int) -> CGFloat {
        let currentTrans = dragState.translation.width
        if index == activeWindow?.active { return currentTrans }
        if index == activeWindow?.lower { return currentTrans - style.pageOffset }
        if index == activeWindow?.lowest { return currentTrans - 2 * style.pageOffset }
        if index == activeWindow?.higher { return currentTrans + style.pageOffset }
        if index == activeWindow?.highest { return currentTrans + 2 * style.pageOffset }
        return style.largePageOffset
    }

    private func elementScale(_ index: Int) -> CGFloat {
        if index == activeWindow?.active { return style.focusedScale }
        if (activeWindow?.neighbors ?? []).contains(index) { return style.unfocusedScale }
        return 0
    }

    private func elementZIndex(_ index: Int) -> Double {
        if index == activeWindow?.active { return 2 }
        if index == activeWindow?.lower || index == activeWindow?.higher { return 1 }
        return 0
    }

    private func elementVisibility(_ index: Int) -> Bool {
        return activeWindow?.all.contains(index) ?? false
    }
}
