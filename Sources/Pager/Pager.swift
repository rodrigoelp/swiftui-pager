import SwiftUI

/// Helper view with not much use for now, but allows me to delay rendering the page as the pager is built.
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

    /// Initializes the style to follow on each element contained by the pager.
    /// - Parameter interPagePadding: spacing between pages.
    /// - Parameter maxPage: Used to calculate the maximum page boundary, allows you to indicate how far do you want
    /// pages when these are not rendered or prepared to be visible.
    ///  Basically, an optimization parameter.
    /// - Parameter focusedScale: scale of focused/selected/active pages.
    /// - Parameter unfocusedScale: scale of unfocused/unselected/inactive pages.
    /// - Parameter animation: Animation used transitioning between pages (applied when the page snaps in place, to its
    /// scale and its visual importance).
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

/// Visual indicator type
public enum PageIndicatorType {
    /// I think the page indicator looks awful... don't show it.
    case none
    /// This is the default that matches iOS/watchOS
    case dot
    /// I want to be different. Square different. Like bobsponge.
    case square
}

private extension PageIndicatorType {
    func asView(size: CGSize) -> AnyView {
        switch self {
        case .none:
            return AnyView(EmptyView())
        case .dot:
            return AnyView(Circle().size(size))
        case .square:
            return AnyView(Rectangle().size(size))
        }
    }
}

/// Allows you to style the page indicator.
public struct PageIndicatorStyle {
    public static var `default` = PageIndicatorStyle()
    let type: PageIndicatorType
    let activeOpacity: Double
    let inactiveOpacity: Double
    let foreground: Color?
    let size: CGSize

    /// Initializes a new style for the page indicator.
    /// - Parameter activeOpacity: opacity of the active/selected page.
    /// - Parameter inactiveOpacity: opacity of the inactive/unselected page.
    /// - Parameter foreground: color of each element in the indicator.
    /// - Parameter size: size of the each indicator.
    /// - Parameter type: visual type of the indicator. Choose between .none, dot (circle), or square.
    /// If you choose .none the entire indicator and every single element within won't be rendered.
    public init(activeOpacity: Double = 1,
                inactiveOpacity: Double = 0.4,
                foreground: Color? = .white,
                size: CGSize = CGSize(width: 8, height: 8),
                type: PageIndicatorType = .dot
    ) {
        self.activeOpacity = activeOpacity
        self.inactiveOpacity = inactiveOpacity
        self.foreground = foreground
        self.size = size
        self.type = type
    }
}

private struct PageIndicator: View {
    private let indexes: Range<Int>
    private let active: Int?
    private let style: PageIndicatorStyle
    private let shapeBuilder: () -> AnyView

    init(style: PageIndicatorStyle,
         indexes: Range<Int>,
         active: Int?
    ) {
        self.indexes = indexes
        self.active = active
        self.style = style
        self.shapeBuilder = { style.type.asView(size: style.size) }
    }

    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                HStack(alignment: .center) {
                    Spacer()
                    ForEach(self.indexes) { index in
                        self.shapeBuilder()
                            .foregroundColor(self.style.foreground)
                            .opacity(self.active == index ? self.style.activeOpacity: self.style.inactiveOpacity)
                    }
                    Spacer()
                }.frame(height: self.style.size.height + 8, alignment: .top)
            }.frame(maxWidth: geometry.size.width * 0.6)
        }
    }
}

/// Provides a mechanism to display pages/views.
public struct Pager<Content>: View where Content: View {
    private let views: [Page<Content>]
    private let style: PagerStyle
    private let indicatorStyle: PageIndicatorStyle
    @State private var activeWindow: ActiveWindow?
    @GestureState private var dragState = DragState.inactive

    /// Initialises a pager with as many styled pages as indicated.
    /// - Parameter style: General style used by the pager. Allows you to set visual appearance of
    /// pages, spacing between pages, animation, etc.
    /// - Parameter indicatorStyle: General style used by the selected page indicator. It can be used to turn it off
    /// change color and size of the indicator.
    /// - Parameter pages: List of views used to populate the pager.
    /// - Remark:
    /// An example of how to use the pager would be
    /// ```swift
    ///  struct ContentView: View {
    ///      var body: some View {
    ///          GeometryReader { geometry in
    ///              Pager(indicatorStyle: PageIndicatorStyle(type: .dot)) {
    ///                  [
    ///                      AnyView(Text("Page 1"))
    ///                          .frame(width: geometry.size.width, height: geometry.size.height)
    ///                          .background(.blue),
    ///                      AnyView(Text("Page 2") )
    ///                          .frame(width: geometry.size.width, height: geometry.size.height)
    ///                          .background(.green),
    ///                      AnyView(Text("Page 3") )
    ///                          .frame(width: geometry.size.width, height: geometry.size.height)
    ///                          .background(.orange),
    ///                      AnyView(Text("Page 4") )
    ///                          .frame(width: geometry.size.width, height: geometry.size.height)
    ///                          .background(.yellow),
    ///                  ]
    ///              }
    ///          }
    ///      }
    ///  }
    /// ```
    public init(
        style: PagerStyle = PagerStyle.default,
        indicatorStyle: PageIndicatorStyle = PageIndicatorStyle.default,
        @ViewBuilder pages: @escaping () -> [Content]
    ) {
        views = pages().map { view in Page { view } }
        self.style = style
        self.indicatorStyle = indicatorStyle
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
            Group {
                if self.indicatorStyle.type != .none {
                    PageIndicator(style: self.indicatorStyle,
                                  indexes: 0..<self.views.count,
                                  active: self.activeWindow?.active)
                } else {
                    EmptyView()
                }
            }
            .zIndex(3)
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
