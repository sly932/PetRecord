// PetDetailView.swift
// 宠物档案详情：展示基础信息 + 进入体重/驱虫功能面板
// 调整：右上角添加“编辑”按钮，进入编辑模式

import SwiftUI

struct PetDetailView: View {
    @EnvironmentObject var store: PetStore
    let pet: Pet

    @State private var showEditor: Bool = false

    var body: some View {
        List {
            Section("基本信息") {
                LabeledContent("姓名", value: pet.name)
                LabeledContent("性别", value: pet.gender.rawValue)
                LabeledContent("品种", value: pet.breed)
                if let birthday = pet.birthday {
                    LabeledContent("生日", value: birthday.formatted(date: .abbreviated, time: .omitted))
                }
            }
            Section("健康概览") {
                LabeledContent("当前体重", value: pet.currentWeightKg.map { String(format: "%.1f kg", $0) } ?? "—")
                LabeledContent("驱虫记录数", value: "\(pet.dewormings.count)")
            }
            Section {
                NavigationLink("体重面板（单宠）") { WeightPanelView(petId: pet.id) }
                NavigationLink("驱虫面板（单宠）") { DewormingPanelView(petId: pet.id) }
            }
        }
        .navigationTitle(pet.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("编辑") { showEditor = true }
            }
        }
        .sheet(isPresented: $showEditor) {
            NavigationStack {
                PetEditorView(mode: .edit(existing: pet)) { updated in
                    store.updatePet(updated)
                    showEditor = false
                } onCancel: {
                    showEditor = false
                }
            }
        }
    }
}

#Preview {
    NavigationStack { PetDetailView(pet: PetStore.previewStore().pets[0]) }
        .environmentObject(PetStore.previewStore())
}
