import SwiftUI

/// Drag gesture state, tracking when the user is providing input vs when they don't.
internal enum DragState {
    case inactive
    case active(translation: CGSize)

    var isDragging: Bool {
        if case .active = self { return true }
        return false
    }

    var translation: CGSize {
        if case let .active(translation) = self {
            return translation
        }
        return .zero
    }
}

private enum WindowHelper {
    static func lowerIndex(of index: Int, upperBound: Int) -> Int? {
        guard upperBound >= 1 && index > 0 else {
            return nil
        }
        return index - 1
    }

    static func higherIndex(of index: Int, upperBound: Int) -> Int? {
        guard upperBound >= 1 && index + 1 < upperBound else { return nil }
        return index + 1
    }
}

/// Struct to help us track the active element and its immediate neighbours.
/// - Note: Depending on the configuration, we might need to track up to
/// elements/items on screen, the reason for this is the user might be dragging
/// the cards/pages all the way to the point the elements to the right or left
/// are visible.
internal struct ActiveWindow {
    let active: Int
    let lower: Int?
    let lowest: Int?
    let higher: Int?
    let highest: Int?

    let upperBound: Int

    init(activeIndex: Int = 0, upperBound: Int) {
        active = activeIndex
        lower = WindowHelper.lowerIndex(of: activeIndex, upperBound: upperBound)
        lowest = lower.flatMap { WindowHelper.lowerIndex(of: $0, upperBound: upperBound) }
        higher = WindowHelper.higherIndex(of: activeIndex, upperBound: upperBound)
        highest = higher.flatMap { WindowHelper.higherIndex(of: $0, upperBound: upperBound) }
        self.upperBound = upperBound
    }
}

internal extension ActiveWindow {
    /// Nearest elements to the active index.
    var nearest: [Int] {
        [ lower, higher ].compactMap { $0 }
    }

    /// all the neighbors in the current window.
    var neighbors: [Int] {
        [ lowest, lower, higher, highest ].compactMap { $0 }
    }

    /// all elements in the window.
    var all: [Int] {
        [ lowest, lower, active, higher, highest ].compactMap { $0 }
    }

    /// gets a new window based on the new active index.
    func update(active: Int) -> ActiveWindow {
        return .init(activeIndex: active, upperBound: upperBound)
    }
}
