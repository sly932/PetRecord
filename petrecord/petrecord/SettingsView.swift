// SettingsView.swift
// 设置页：导出数据（JSON）
// 知识点：使用 ShareLink 分享临时文件；也可改用 UIDocumentPicker 选择保存位置

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: PetStore
    @State private var exportURL: URL?
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    var body: some View {
        List {
            Section("数据与备份") {
                if let url = exportURL {
                    ShareLink(item: url) {
                        Label("导出数据（JSON）", systemImage: "square.and.arrow.up")
                    }
                } else {
                    Button {
                        do {
                            let data = try ExportService.makeJSON(store: store)
                            let tmp = FileManager.default.temporaryDirectory
                            let url = tmp.appendingPathComponent(ExportService.suggestedFileName())
                            try data.write(to: url, options: .atomic)
                            exportURL = url
                        } catch {
                            alertMessage = "导出失败：\(error.localizedDescription)"
                            showAlert = true
                        }
                    } label: {
                        Label("导出数据（JSON）", systemImage: "square.and.arrow.up")
                    }
                }
            }
        }
        .navigationTitle("设置")
        .alert("提示", isPresented: $showAlert) {
            Button("好的", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }
}

#Preview {
    NavigationStack { SettingsView() }
        .environmentObject(PetStore.previewStore())
}
