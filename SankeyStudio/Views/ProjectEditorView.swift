import SwiftUI

struct ProjectEditorView: View {
    @Binding var project: SankeyProject

    private let palette = ["#3568DD", "#8B5CF6", "#EC4899", "#F59E0B", "#10B981", "#06B6D4", "#EF4444", "#64748B"]

    var body: some View {
        Form {
            Section("Diagramm") {
                TextField("Titel", text: $project.title)
            }

            Section {
                ForEach($project.incomes) { $income in
                    ValueRow(name: $income.name, value: $income.value, color: Color(hex: "#14213D")) {
                        project.incomes.removeAll { $0.id == income.id }
                    }
                }
                .onDelete { project.incomes.remove(atOffsets: $0) }

                Button("Einnahme hinzufügen", systemImage: "plus") {
                    project.incomes.append(Income(name: "Neue Einnahme", value: 0))
                }
            } header: {
                sectionHeader("Einnahmen", value: project.totalIncome)
            }

            Section {
                ForEach($project.expenses) { $expense in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Menu {
                                ForEach(palette, id: \.self) { hex in
                                    Button {
                                        expense.colorHex = hex
                                    } label: {
                                        Label(hex, systemImage: expense.colorHex == hex ? "checkmark.circle.fill" : "circle.fill")
                                    }
                                }
                            } label: {
                                Circle()
                                    .fill(expense.color)
                                    .frame(width: 24, height: 24)
                            }

                            TextField("Ausgabengruppe", text: $expense.name)
                            Spacer()
                            Text(expense.total, format: .currency(code: "EUR").precision(.fractionLength(0)))
                                .fontWeight(.semibold)
                        }

                        if expense.children.isEmpty {
                            CurrencyField(value: $expense.value)
                        } else {
                            ForEach($expense.children) { $child in
                                ValueRow(name: $child.name, value: $child.value, color: expense.color) {
                                    expense.children.removeAll { $0.id == child.id }
                                }
                            }
                            .onDelete { expense.children.remove(atOffsets: $0) }
                        }

                        Button("Unterkategorie hinzufügen", systemImage: "plus") {
                            if expense.children.isEmpty, expense.value > 0 {
                                expense.children.append(ExpenseItem(name: expense.name, value: expense.value))
                                expense.value = 0
                            }
                            expense.children.append(ExpenseItem(name: "Neue Unterkategorie", value: 0))
                        }
                        .font(.caption)

                        Button(role: .destructive) {
                            project.expenses.removeAll { $0.id == expense.id }
                        } label: {
                            Label("Ausgabengruppe löschen", systemImage: "trash")
                        }
                        .font(.caption)
                    }
                    .padding(.vertical, 4)
                }
                .onDelete { project.expenses.remove(atOffsets: $0) }

                Button("Ausgabengruppe hinzufügen", systemImage: "plus") {
                    let color = palette[project.expenses.count % palette.count]
                    project.expenses.append(ExpenseGroup(
                        name: "Neue Ausgabengruppe",
                        colorHex: color,
                        value: 0,
                        children: []
                    ))
                }
            } header: {
                sectionHeader("Ausgaben", value: project.totalExpense)
            }

            if project.balance < 0 {
                Section {
                    Label(
                        "Deine Ausgaben übersteigen die Einnahmen um \((-project.balance).formatted(.currency(code: "EUR").precision(.fractionLength(0)))).",
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .foregroundStyle(.orange)
                }
            }
        }
        .navigationTitle("Finanzfluss")
    }

    private func sectionHeader(_ title: String, value: Double) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value, format: .currency(code: "EUR").precision(.fractionLength(0)))
        }
    }
}

private struct ValueRow: View {
    @Binding var name: String
    @Binding var value: Double
    let color: Color
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Capsule()
                .fill(color)
                .frame(width: 7, height: 32)
            TextField("Name", text: $name)
            CurrencyField(value: $value)
                .frame(maxWidth: 120)
            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
        }
    }
}

private struct CurrencyField: View {
    @Binding var value: Double

    var body: some View {
        TextField("Betrag", value: $value, format: .number)
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.trailing)
            .textFieldStyle(.roundedBorder)
    }
}
