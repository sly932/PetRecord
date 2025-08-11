// RootTabView.swift
// 底部 Tab 容器：档案 / 数据 / 设置
// 知识点：TabView + 每个 Tab 内自带 NavigationStack，互不影响各自导航栈

import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            NavigationStack { HomeView() }
                .tabItem { Label("档案", systemImage: "person.text.rectangle") }

            NavigationStack { DataHubView() }
                .tabItem { Label("数据", systemImage: "chart.xyaxis.line") }

            NavigationStack { SettingsView() }
                .tabItem { Label("设置", systemImage: "gearshape") }
        }
    }
}

#Preview {
    RootTabView().environmentObject(PetStore.previewStore())
}
