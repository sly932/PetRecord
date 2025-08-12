// SettingsView.swift
// 设置页：导出数据（JSON）
// 知识点：使用 ShareLink 分享临时文件；也可改用 UIDocumentPicker 选择保存位置

import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject var store: PetStore
    @State private var exportURL: URL?
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var showImporter: Bool = false

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

                Button {
                    showImporter = true
                } label: {
                    Label("导入 JSON（覆盖当前数据）", systemImage: "tray.and.arrow.down")
                }
            }
        }
        .navigationTitle("设置")
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json], allowsMultipleSelection: false) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                // 知识点：沙盒应用访问外部文件需显式启动安全范围资源访问
                // 必须在访问 URL 之前调用 startAccessingSecurityScopedResource()
                // defer 确保无论成功失败，都能停止访问
                guard url.startAccessingSecurityScopedResource() else {
                    alertMessage = "无法获取文件访问权限"
                    showAlert = true
                    return
                }
                defer { url.stopAccessingSecurityScopedResource() }

                do {
                    let data = try Data(contentsOf: url)
                    let pets = try ImportService.decodePets(from: data)
                    store.replaceAll(with: pets)
                    alertMessage = "导入成功：已覆盖当前数据"
                    showAlert = true
                } catch {
                    alertMessage = "导入失败：\(error.localizedDescription)"
                    showAlert = true
                }
            case .failure(let error):
                alertMessage = "导入失败：\(error.localizedDescription)"
                showAlert = true
            }
        }
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
