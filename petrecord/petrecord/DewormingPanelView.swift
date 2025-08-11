// DewormingPanelView.swift
// 驱虫功能面板：时间轴列表 + 新增入口（表单）

import SwiftUI

struct DewormingPanelView: View {
    @EnvironmentObject var store: PetStore
    let petId: UUID

    @State private var showForm: Bool = false

    private var pet: Pet? { store.pets.first(where: { $0.id == petId }) }

    var body: some View {
        List {
            if let pet = pet {
                Section("历史驱虫") {
                    ForEach(pet.dewormings.sorted { $0.date > $1.date }) { r in
                        VStack(alignment: .leading) {
                            Text(r.medicineName).font(.headline)
                            Text(r.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.footnote).foregroundStyle(.secondary)
                            if let notes = r.notes, !notes.isEmpty {
                                Text(notes).font(.subheadline)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            } else {
                Text("未找到该宠物")
            }
        }
        .navigationTitle("驱虫面板")
        .safeAreaInset(edge: .bottom) {
            Button {
                showForm = true
            } label: {
                Text("新增驱虫记录").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding()
            .background(.ultraThinMaterial)
        }
        .sheet(isPresented: $showForm) {
            NavigationStack {
                DewormingFormView(petId: petId) {
                    showForm = false
                } onCancel: {
                    showForm = false
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .dewormingFormSaved)) { note in
            guard
                let info = note.userInfo,
                let id = info["petId"] as? UUID,
                id == petId,
                let date = info["date"] as? Date,
                let medicineName = info["medicineName"] as? String
            else { return }
            let notes = info["notes"] as? String
            store.addDeworming(for: petId, date: date, medicineName: medicineName, notes: notes)
        }
    }
}

#Preview {
    NavigationStack { DewormingPanelView(petId: PetStore.previewStore().pets[0].id) }
        .environmentObject(PetStore.previewStore())
}
