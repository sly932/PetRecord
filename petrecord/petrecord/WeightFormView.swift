// WeightFormView.swift
// 体重新增表单：日期 + 体重(kg) + 备注(预留)

import SwiftUI

struct WeightFormView: View {
    let petId: UUID
    var onSaved: () -> Void
    var onCancel: () -> Void

    @State private var date: Date = Date()
    @State private var weightText: String = ""
    @State private var error: String? = nil

    var body: some View {
        Form {
            DatePicker("日期", selection: $date, displayedComponents: .date)
            TextField("体重 (kg)", text: $weightText)
                .keyboardType(.decimalPad)
            if let err = error { Text(err).foregroundStyle(.red).font(.footnote) }
        }
        .navigationTitle("新增体重")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") { onCancel() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") { onSave() }
            }
        }
    }

    private func onSave() {
        let trimmed = weightText.trimmingCharacters(in: .whitespaces)
        guard let value = Double(trimmed), value > 0 else {
            error = "请输入有效的体重(>0)"
            return
        }
        NotificationCenter.default.post(name: .weightFormSaved, object: nil, userInfo: ["petId": petId, "date": date, "weightKg": value])
        onSaved()
    }
}

extension Notification.Name { static let weightFormSaved = Notification.Name("weightFormSaved") }

#Preview {
    NavigationStack { WeightFormView(petId: UUID(), onSaved: {}, onCancel: {}) }
}
