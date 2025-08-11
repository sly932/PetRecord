// HomeView.swift
// 主页（档案列表）：展示宠物与“新增档案”
// 调整：移除“体重总览”入口；新增右上角“新增档案”按钮

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: PetStore
    @State private var showEditor: Bool = false

    var body: some View {
        NavigationStack {
            List {
                Section("我的宠物") {
                    ForEach(store.pets) { pet in
                        NavigationLink(value: pet.id) {
                            HStack {
                                Circle().fill(Color.blue.opacity(0.2)).frame(width: 40, height: 40)
                                VStack(alignment: .leading) {
                                    Text(pet.name).font(.headline)
                                    Text(pet.breed).font(.subheadline).foregroundStyle(.secondary)
                                }
                                Spacer()
                                if let w = pet.currentWeightKg {
                                    Text(String(format: "%.1f kg", w)).font(.footnote).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("档案")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showEditor = true
                    } label: {
                        Label("新增档案", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showEditor) {
                NavigationStack {
                    PetEditorView(mode: .create) { newPet in
                        store.addPet(newPet)
                        showEditor = false
                    } onCancel: {
                        showEditor = false
                    }
                }
            }
            .navigationDestination(for: UUID.self) { value in
                if let pet = store.pets.first(where: { $0.id == value }) {
                    PetDetailView(pet: pet)
                } else {
                    Text("未找到宠物")
                }
            }
        }
    }
}

#Preview {
    HomeView().environmentObject(PetStore.previewStore())
}
