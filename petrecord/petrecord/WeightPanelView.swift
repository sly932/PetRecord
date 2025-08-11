// WeightPanelView.swift
// 体重功能面板：单宠体重曲线 + 列表 + 新增入口（表单）

import SwiftUI
import Charts

struct WeightPanelView: View {
    @EnvironmentObject var store: PetStore
    let petId: UUID

    @State private var showForm: Bool = false

    private var pet: Pet? { store.pets.first(where: { $0.id == petId }) }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let pet = pet {
                GroupBox("体重趋势（kg）") {
                    Chart(pet.weights.sorted { $0.date < $1.date }) { item in
                        LineMark(
                            x: .value("日期", item.date),
                            y: .value("体重(kg)", item.weightKg)
                        )
                        PointMark(
                            x: .value("日期", item.date),
                            y: .value("体重(kg)", item.weightKg)
                        )
                    }
                    .frame(height: 220)
                }
                List {
                    Section("历史记录") {
                        ForEach(pet.weights.sorted { $0.date > $1.date }) { w in
                            HStack {
                                Text(w.date.formatted(date: .abbreviated, time: .omitted))
                                Spacer()
                                Text(String(format: "%.1f kg", w.weightKg))
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .safeAreaInset(edge: .bottom) {
                    Button {
                        showForm = true
                    } label: {
                        Text("新增体重").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                    .background(.ultraThinMaterial)
                }
            } else {
                Text("未找到该宠物")
            }
        }
        .padding([.horizontal])
        .navigationTitle("体重面板")
        .sheet(isPresented: $showForm) {
            NavigationStack {
                WeightFormView(petId: petId) {
                    showForm = false
                } onCancel: {
                    showForm = false
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .weightFormSaved)) { note in
            guard
                let info = note.userInfo,
                let id = info["petId"] as? UUID,
                id == petId,
                let date = info["date"] as? Date,
                let weightKg = info["weightKg"] as? Double
            else { return }
            store.addWeight(for: petId, date: date, weightKg: weightKg)
        }
    }
}

#Preview {
    NavigationStack { WeightPanelView(petId: PetStore.previewStore().pets[0].id) }
        .environmentObject(PetStore.previewStore())
}
