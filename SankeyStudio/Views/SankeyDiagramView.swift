import SwiftUI

struct SankeyDiagramView: View {
    let project: SankeyProject
    var showsSummary = true

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(project.title.isEmpty ? "Mein Finanzfluss" : project.title)
                        .font(.title2.bold())
                    Text("Die Breite der Ströme entspricht dem jeweiligen Betrag.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(balanceText)
                    .font(.caption.bold())
                    .foregroundStyle(project.balance >= 0 ? Color.green : Color.red)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background((project.balance >= 0 ? Color.green : Color.red).opacity(0.1), in: Capsule())
            }

            GeometryReader { proxy in
                let layout = SankeyLayout.calculate(project: project, size: proxy.size)

                ZStack {
                    Color.white

                    ForEach(layout.links) { link in
                        linkPath(link)
                            .stroke(
                                link.color.opacity(0.36),
                                style: StrokeStyle(lineWidth: link.width, lineCap: .butt)
                            )
                    }

                    ForEach(layout.nodes) { node in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(node.color)
                            .frame(width: node.rect.width, height: node.rect.height)
                            .position(x: node.rect.midX, y: node.rect.midY)

                        nodeLabel(node)
                            .frame(width: 118, alignment: node.column == 0 ? .trailing : .leading)
                            .position(x: labelX(node), y: node.rect.midY)
                    }

                    if project.incomes.isEmpty && project.expenses.isEmpty {
                        ContentUnavailableView(
                            "Noch keine Daten",
                            systemImage: "chart.bar.xaxis",
                            description: Text("Füge Einnahmen und Ausgaben hinzu.")
                        )
                    }
                }
                .clipped()
            }

            if showsSummary {
                HStack(spacing: 0) {
                    summaryValue("Einnahmen", project.totalIncome, color: .primary)
                    Divider()
                    summaryValue("Ausgaben", project.totalExpense, color: .primary)
                    Divider()
                    summaryValue("Übrig", project.balance, color: project.balance >= 0 ? .green : .red)
                }
                .frame(height: 52)
                .padding(.vertical, 4)
                .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(Color.white)
    }

    private var balanceText: String {
        let value = abs(project.balance).formatted(.currency(code: "EUR").precision(.fractionLength(0)))
        return project.balance >= 0 ? "\(value) übrig" : "\(value) fehlen"
    }

    private func nodeLabel(_ node: SankeyNodeFrame) -> some View {
        VStack(alignment: node.column == 0 ? .trailing : .leading, spacing: 1) {
            Text(node.name)
                .font(.caption.bold())
                .lineLimit(1)
            Text("\(node.value.formatted(.currency(code: "EUR").precision(.fractionLength(0)))) · \(percentage(node.value))%")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private func percentage(_ value: Double) -> Int {
        guard project.totalIncome > 0 else { return 0 }
        return Int((value / project.totalIncome * 100).rounded())
    }

    private func labelX(_ node: SankeyNodeFrame) -> CGFloat {
        node.column == 0 ? node.rect.minX - 66 : node.rect.maxX + 66
    }

    private func summaryValue(_ title: String, _ value: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value, format: .currency(code: "EUR").precision(.fractionLength(0)))
                .font(.subheadline.bold())
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
    }

    private func linkPath(_ link: SankeyLinkShape) -> Path {
        Path { path in
            let distance = max((link.target.x - link.source.x) * 0.48, 30)
            path.move(to: link.source)
            path.addCurve(
                to: link.target,
                control1: CGPoint(x: link.source.x + distance, y: link.source.y),
                control2: CGPoint(x: link.target.x - distance, y: link.target.y)
            )
        }
    }
}
