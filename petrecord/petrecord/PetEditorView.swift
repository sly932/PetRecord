// PetEditorView.swift
// 新增/编辑宠物档案
// 方案：整页编辑（方案A），右上角保存/取消

import SwiftUI

struct PetEditorView: View {
    enum Mode { case create, edit(existing: Pet) }

    let mode: Mode
    var onSave: (Pet) -> Void
    var onCancel: () -> Void

    @State private var name: String = ""
    @State private var gender: Gender = .unknown
    @State private var breed: String = ""
    @State private var birthday: Date = Date()
    @State private var hasBirthday: Bool = false
    @State private var notes: String = ""

    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    init(mode: Mode, onSave: @escaping (Pet) -> Void, onCancel: @escaping () -> Void) {
        self.mode = mode
        self.onSave = onSave
        self.onCancel = onCancel
        // 初始值将在 body.appeared 时根据 mode 设置
    }

    var body: some View {
        Form {
            Section("基本信息") {
                TextField("姓名（必填）", text: $name)
                Picker("性别", selection: $gender) {
                    ForEach(Gender.allCases) { g in
                        Text(g.rawValue).tag(g)
                    }
                }
                TextField("品种", text: $breed)
                Toggle("有生日信息", isOn: $hasBirthday)
                if hasBirthday {
                    DatePicker("生日", selection: $birthday, displayedComponents: .date)
                }
                TextField("备注", text: $notes, axis: .vertical)
            }
        }
        .navigationTitle(modeTitle)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") { onCancel() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") { save() }
            }
        }
        .onAppear { applyInitialValues() }
        .alert("提示", isPresented: $showAlert) {
            Button("好的", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    private var modeTitle: String {
        switch mode {
        case .create: return "新增档案"
        case .edit: return "编辑档案"
        }
    }

    private func applyInitialValues() {
        if case .edit(let existing) = mode {
            name = existing.name
            gender = existing.gender
            breed = existing.breed
            if let b = existing.birthday { birthday = b; hasBirthday = true } else { hasBirthday = false }
            notes = existing.notes ?? ""
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { alertMessage = "姓名为必填项"; showAlert = true; return }
        let pet = Pet(
            name: trimmed,
            gender: gender,
            breed: breed,
            birthday: hasBirthday ? birthday : nil,
            notes: notes.isEmpty ? nil : notes
        )
        if case .edit(let existing) = mode {
            // 保持 id 与既有子记录
            let updated = Pet(
                id: existing.id,
                name: pet.name,
                gender: pet.gender,
                breed: pet.breed,
                birthday: pet.birthday,
                notes: pet.notes,
                weights: existing.weights,
                dewormings: existing.dewormings
            )
            onSave(updated)
        } else {
            onSave(pet)
        }
    }
}

#Preview {
    NavigationStack {
        PetEditorView(mode: .create, onSave: { _ in }, onCancel: {})
    }
}
