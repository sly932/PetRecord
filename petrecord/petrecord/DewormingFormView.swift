// DewormingFormView.swift
// 驱虫新增表单：日期 + 药品 + 剂量/备注(可选)

import SwiftUI

struct DewormingFormView: View {
    let petId: UUID
    var onSaved: () -> Void
    var onCancel: () -> Void

    @State private var date: Date = Date()
    @State private var medicineName: String = ""
    @State private var notes: String = ""
    @State private var error: String? = nil

    var body: some View {
        Form {
            DatePicker("日期", selection: $date, displayedComponents: .date)
            TextField("药品（必填）", text: $medicineName)
            TextField("剂量/备注（可选）", text: $notes)
            if let err = error { Text(err).foregroundStyle(.red).font(.footnote) }
        }
        .navigationTitle("新增驱虫")
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
        let trimmed = medicineName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            error = "药品为必填项"
            return
        }
        NotificationCenter.default.post(name: .dewormingFormSaved, object: nil, userInfo: [
            "petId": petId, "date": date, "medicineName": trimmed, "notes": notes.isEmpty ? nil : notes
        ])
        onSaved()
    }
}

extension Notification.Name { static let dewormingFormSaved = Notification.Name("dewormingFormSaved") }

#Preview {
    NavigationStack { DewormingFormView(petId: UUID(), onSaved: {}, onCancel: {}) }
}
