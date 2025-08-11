// DataHubView.swift
// 数据页：集中放置与数据相关的入口（当前：体重记录）

import SwiftUI

struct DataHubView: View {
    var body: some View {
        List {
            Section("记录与可视化") {
                NavigationLink {
                    AllPetsWeightView()
                } label: {
                    Label("体重记录", systemImage: "scalemass")
                }
            }
        }
        .navigationTitle("数据")
    }
}

#Preview {
    NavigationStack { DataHubView() }
        .environmentObject(PetStore.previewStore())
}
