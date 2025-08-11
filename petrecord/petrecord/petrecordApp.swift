//  petrecordApp.swift
//  应用入口：注入全局状态（PetStore），展示 RootTabView（档案/数据/设置）

import SwiftUI

@main
struct petrecordApp: App {
    @StateObject private var store: PetStore = PetStore() // 运行态不再使用预置数据

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(store)
        }
    }
}
