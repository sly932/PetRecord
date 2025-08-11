// AllPetsWeightView.swift
// 所有宠物体重总览：便于横向浏览与跳转
// 知识点：列表中嵌入迷你趋势图（简化版）

import SwiftUI
import Charts

struct AllPetsWeightView: View {
    @EnvironmentObject var store: PetStore

    var body: some View {
        List {
            Section {
                Button {
                    // 进入称重会话
                    navigateToWeighingSession = true
                } label: {
                    Label("开始称重", systemImage: "scalemass")
                }
            }
            Section("体重总览") {
                ForEach(store.pets) { pet in
                    NavigationLink { WeightPanelView(petId: pet.id) } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(pet.name).font(.headline)
                                Spacer()
                                Text(pet.currentWeightKg.map { String(format: "%.1f kg", $0) } ?? "—")
                                    .font(.footnote).foregroundStyle(.secondary)
                            }
                            if pet.weights.count >= 2 {
                                Chart(pet.weights.sorted { $0.date < $1.date }.suffix(5)) { item in
                                    LineMark(x: .value("date", item.date), y: .value("kg", item.weightKg))
                                }
                                .frame(height: 80)
                            }
                        }
                    }
                }
            }
        }
        .background(
            NavigationLink(isActive: $navigateToWeighingSession) {
                WeighingSessionView(pets: store.pets)
            } label: { EmptyView() }
                .opacity(0)
        )
        .navigationTitle("体重总览")
    }

    // 利用隐式 NavigationLink 控制跳转
    @State private var navigateToWeighingSession: Bool = false
}

#Preview {
    NavigationStack { AllPetsWeightView() }
        .environmentObject(PetStore.previewStore())
}
