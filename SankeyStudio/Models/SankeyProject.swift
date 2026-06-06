import Foundation
import SwiftUI

struct Income: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var value: Double
}

struct ExpenseItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var value: Double
}

struct ExpenseGroup: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var colorHex: String
    var value: Double
    var children: [ExpenseItem]

    var total: Double {
        children.isEmpty ? max(value, 0) : children.reduce(0) { $0 + max($1.value, 0) }
    }

    var color: Color {
        Color(hex: colorHex)
    }
}

struct SankeyProject: Codable, Equatable {
    var title: String
    var incomes: [Income]
    var expenses: [ExpenseGroup]

    var totalIncome: Double {
        incomes.reduce(0) { $0 + max($1.value, 0) }
    }

    var totalExpense: Double {
        expenses.reduce(0) { $0 + $1.total }
    }

    var balance: Double {
        totalIncome - totalExpense
    }

    static let empty = SankeyProject(title: "Mein Finanzfluss", incomes: [], expenses: [])

    static let example = SankeyProject(
        title: "Monatlicher Finanzfluss",
        incomes: [
            Income(name: "Gehalt", value: 3_200),
            Income(name: "Nebenjob", value: 400)
        ],
        expenses: [
            ExpenseGroup(
                name: "Wohnen",
                colorHex: "#3568DD",
                value: 0,
                children: [
                    ExpenseItem(name: "Miete", value: 1_050),
                    ExpenseItem(name: "Strom & Internet", value: 120)
                ]
            ),
            ExpenseGroup(
                name: "Alltag",
                colorHex: "#8B5CF6",
                value: 0,
                children: [
                    ExpenseItem(name: "Lebensmittel", value: 430),
                    ExpenseItem(name: "Freizeit", value: 260)
                ]
            ),
            ExpenseGroup(name: "Mobilität", colorHex: "#F59E0B", value: 310, children: []),
            ExpenseGroup(name: "Sparen & Investieren", colorHex: "#10B981", value: 900, children: [])
        ]
    )
}

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        let valid = cleaned.count == 6

        self.init(
            .sRGB,
            red: valid ? Double(value >> 16) / 255 : 0.21,
            green: valid ? Double(value >> 8 & 0xFF) / 255 : 0.41,
            blue: valid ? Double(value & 0xFF) / 255 : 0.87,
            opacity: 1
        )
    }
}
