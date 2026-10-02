import SwiftUI

/// Columns of cards where each card goes into the currently shortest column,
/// so cards of different heights pack without row gaps.
struct MasonryLayout: Layout {
    var minColumnWidth: CGFloat = 260
    var spacing: CGFloat = 14

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? minColumnWidth
        let placement = arrange(subviews, width: width)
        return CGSize(width: width, height: placement.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let placement = arrange(subviews, width: bounds.width)
        for (index, frame) in placement.frames.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(width: frame.width, height: frame.height)
            )
        }
    }

    private func arrange(_ subviews: Subviews, width: CGFloat) -> (frames: [CGRect], height: CGFloat) {
        let columns = max(1, Int((width + spacing) / (minColumnWidth + spacing)))
        let columnWidth = (width - spacing * CGFloat(columns - 1)) / CGFloat(columns)
        var heights = Array(repeating: CGFloat(0), count: columns)
        var frames: [CGRect] = []
        for subview in subviews {
            let column = heights.indices.min { heights[$0] < heights[$1] } ?? 0
            let height = subview.sizeThatFits(ProposedViewSize(width: columnWidth, height: nil)).height
            let y = heights[column] == 0 ? 0 : heights[column] + spacing
            frames.append(CGRect(x: CGFloat(column) * (columnWidth + spacing), y: y, width: columnWidth, height: height))
            heights[column] = y + height
        }
        return (frames, heights.max() ?? 0)
    }
}
