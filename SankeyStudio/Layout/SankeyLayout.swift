import CoreGraphics
import Foundation
import SwiftUI

struct SankeyNodeFrame: Identifiable {
    let id: UUID
    let name: String
    let value: Double
    let color: Color
    let column: Int
    let rect: CGRect
}

struct SankeyLinkShape: Identifiable {
    let id = UUID()
    let source: CGPoint
    let target: CGPoint
    let width: CGFloat
    let color: Color
}

struct SankeyLayoutResult {
    let nodes: [SankeyNodeFrame]
    let links: [SankeyLinkShape]
}

enum SankeyLayout {
    static func calculate(project: SankeyProject, size: CGSize) -> SankeyLayoutResult {
        guard size.width > 0, size.height > 0 else {
            return SankeyLayoutResult(nodes: [], links: [])
        }

        let nodeWidth: CGFloat = 18
        let horizontalInset: CGFloat = min(max(size.width * 0.16, 115), 190)
        let verticalInset: CGFloat = 48
        let usableHeight = max(size.height - verticalInset * 2, 1)
        let maximumTotal = max(project.totalIncome, project.totalExpense, 1)
        let scale = usableHeight * 0.82 / CGFloat(maximumTotal)
        let xPositions = [
            horizontalInset,
            size.width * 0.5 - nodeWidth / 2,
            size.width - horizontalInset - nodeWidth
        ]

        var nodes: [SankeyNodeFrame] = []
        var frames: [UUID: CGRect] = [:]

        func addColumn(_ values: [(UUID, String, Double, Color)], column: Int) {
            let positiveValues = values.filter { $0.2 > 0 }
            let gap = positiveValues.count > 1 ? min(18, usableHeight * 0.12 / CGFloat(positiveValues.count - 1)) : 0
            let contentHeight = positiveValues.reduce(0) { $0 + CGFloat($1.2) * scale } + gap * CGFloat(max(positiveValues.count - 1, 0))
            var y = verticalInset + max((usableHeight - contentHeight) / 2, 0)

            for value in positiveValues {
                let height = max(CGFloat(value.2) * scale, 2)
                let rect = CGRect(x: xPositions[column], y: y, width: nodeWidth, height: height)
                frames[value.0] = rect
                nodes.append(SankeyNodeFrame(
                    id: value.0,
                    name: value.1,
                    value: value.2,
                    color: value.3,
                    column: column,
                    rect: rect
                ))
                y += height + gap
            }
        }

        addColumn(project.incomes.map { ($0.id, $0.name, max($0.value, 0), Color(hex: "#14213D")) }, column: 0)
        addColumn(project.expenses.map { ($0.id, $0.name, $0.total, $0.color) }, column: 1)
        addColumn(project.expenses.flatMap { group in
            group.children.map { ($0.id, $0.name, max($0.value, 0), group.color) }
        }, column: 2)

        var links: [SankeyLinkShape] = []
        var incomeIndex = 0
        var incomeOffset: CGFloat = 0
        var expenseIncomingOffsets: [UUID: CGFloat] = [:]

        for expense in project.expenses where expense.total > 0 {
            guard let target = frames[expense.id] else { continue }
            var remaining = expense.total
            var targetOffset: CGFloat = 0

            while remaining > 0, incomeIndex < project.incomes.count {
                let income = project.incomes[incomeIndex]
                let incomeValue = max(income.value, 0)
                let usedValue = Double(incomeOffset / scale)
                let available = max(incomeValue - usedValue, 0)

                if available <= 0 {
                    incomeIndex += 1
                    incomeOffset = 0
                    continue
                }

                guard let source = frames[income.id] else {
                    incomeIndex += 1
                    incomeOffset = 0
                    continue
                }

                let flow = min(remaining, available)
                let width = max(CGFloat(flow) * scale, 1)
                links.append(SankeyLinkShape(
                    source: CGPoint(x: source.maxX, y: source.minY + incomeOffset + width / 2),
                    target: CGPoint(x: target.minX, y: target.minY + targetOffset + width / 2),
                    width: width,
                    color: expense.color
                ))
                incomeOffset += width
                targetOffset += width
                remaining -= flow

                if usedValue + flow >= incomeValue {
                    incomeIndex += 1
                    incomeOffset = 0
                }
            }
            expenseIncomingOffsets[expense.id] = 0
        }

        for expense in project.expenses {
            guard let source = frames[expense.id] else { continue }
            for child in expense.children where child.value > 0 {
                guard let target = frames[child.id] else { continue }
                let offset = expenseIncomingOffsets[expense.id, default: 0]
                let width = max(CGFloat(child.value) * scale, 1)
                links.append(SankeyLinkShape(
                    source: CGPoint(x: source.maxX, y: source.minY + offset + width / 2),
                    target: CGPoint(x: target.minX, y: target.midY),
                    width: width,
                    color: expense.color
                ))
                expenseIncomingOffsets[expense.id] = offset + width
            }
        }

        return SankeyLayoutResult(nodes: nodes, links: links)
    }
}
