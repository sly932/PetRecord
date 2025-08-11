// WeighingSessionView.swift
// 批量称重（会话）界面
//
// 功能说明（给新手）：
// - 从“体重总览”点击“开始称重”进入本界面
// - 顶部显示统计：未完成/总数
// - 列表分为两组：未完成在上，已完成在下
// - 每个未完成项：输入体重（kg）+ 保存按钮；校验通过后写入仓库并将该项移动到下方
// - “全部完成”按钮在所有项完成后高亮，点击可返回上一页
//
// 知识点：
// - @StateObject 管理本地会话状态；@EnvironmentObject 访问全局 PetStore
// - 通过 Binding 将文本框输入与某个数组元素关联
// - withAnimation 包装状态变更以获得自然的列表过渡

import SwiftUI

// MARK: - 会话项模型（临时 UI 状态）
struct WeighingItem: Identifiable, Equatable {
    let id: UUID         // 对应 petId
    var name: String
    var pendingInputKg: String = "" // 文本输入更易做校验与格式化
    var isCompleted: Bool = false
    var error: String? = nil
}

// MARK: - 会话状态容器
final class WeighingSessionState: ObservableObject {
    @Published var items: [WeighingItem] = []
    @Published var date: Date = Date()

    // 初始化：由外部传入宠物列表生成会话项
    init(pets: [Pet]) {
        self.items = pets.map { WeighingItem(id: $0.id, name: $0.name) }
        reorder()
    }

    // 计算属性：分组视图需要
    var pendingItems: [WeighingItem] { items.filter { !$0.isCompleted } }
    var completedItems: [WeighingItem] { items.filter { $0.isCompleted } }

    // 将已完成项放到底部，保持名称顺序稳定
    func reorder() {
        items.sort { (a, b) in
            if a.isCompleted == b.isCompleted { return a.name < b.name }
            return a.isCompleted == false && b.isCompleted == true
        }
    }

    // 辅助：按 id 定位索引
    func index(of id: UUID) -> Int? { items.firstIndex { $0.id == id } }
}

// MARK: - 主视图
struct WeighingSessionView: View {
    @EnvironmentObject var store: PetStore
    @Environment(\.dismiss) private var dismiss

    @StateObject private var session: WeighingSessionState

    // 自定义初始化：由外部传入宠物数组
    init(pets: [Pet]) {
        _session = StateObject(wrappedValue: WeighingSessionState(pets: pets))
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            List {
                if !session.pendingItems.isEmpty {
                    Section("待称重") {
                        ForEach(session.pendingItems) { item in
                            row(item: item)
                        }
                    }
                }
                if !session.completedItems.isEmpty {
                    Section("已完成") {
                        ForEach(session.completedItems) { item in
                            HStack {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                                Text(item.name)
                                Spacer()
                                if let last = store.pets.first(where: { $0.id == item.id })?.currentWeightKg {
                                    Text(String(format: "%.1f kg", last)).foregroundStyle(.secondary).font(.footnote)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            footer
        }
        .navigationTitle("称重会话")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: 头部统计
    private var header: some View {
        let total = session.items.count
        let done = session.completedItems.count
        return VStack(alignment: .leading, spacing: 8) {
            Text("待称重 \(total - done)/\(total)")
                .font(.headline)
            DatePicker("称重日期", selection: $session.date, displayedComponents: .date)
                .datePickerStyle(.compact)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial)
    }

    // MARK: 底部操作区
    private var footer: some View {
        HStack(spacing: 12) {
            Button("取消") { dismiss() }
                .buttonStyle(.bordered)
            Button("全部完成") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .disabled(!session.completedItems.count.equalTo(session.items.count))
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    // MARK: 单行输入视图
    @ViewBuilder
    private func row(item: WeighingItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(item.name).font(.headline)
                Spacer()
                TextField("kg", text: bindingForInput(of: item.id))
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 120)
                Button("保存") { saveItem(item) }
                    .buttonStyle(.borderedProminent)
            }
            if let err = bindingForError(of: item.id).wrappedValue, !err.isEmpty {
                Text(err).foregroundStyle(.red).font(.footnote)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: 绑定：将文本输入与数组元素关联
    private func bindingForInput(of id: UUID) -> Binding<String> {
        Binding<String>(
            get: {
                guard let idx = session.index(of: id) else { return "" }
                return session.items[idx].pendingInputKg
            },
            set: { newValue in
                guard let idx = session.index(of: id) else { return }
                session.items[idx].pendingInputKg = newValue
                // 清除错误提示
                session.items[idx].error = nil
            }
        )
    }

    private func bindingForError(of id: UUID) -> Binding<String?> {
        Binding<String?>(
            get: {
                guard let idx = session.index(of: id) else { return nil }
                return session.items[idx].error
            },
            set: { newValue in
                guard let idx = session.index(of: id) else { return }
                session.items[idx].error = newValue
            }
        )
    }

    // MARK: 保存逻辑：校验 → 写入仓库 → 标记完成 → 下沉
    private func saveItem(_ item: WeighingItem) {
        guard let idx = session.index(of: item.id) else { return }
        let raw = session.items[idx].pendingInputKg.trimmingCharacters(in: .whitespaces)
        guard let value = Double(raw), value > 0 else {
            session.items[idx].error = "请输入有效的体重(kg)"
            return
        }
        // 写入全局仓库（此处为内存存储；未来可替换为 Core Data）
        store.addWeight(for: item.id, date: session.date, weightKg: value)
        // 标记完成并清空输入
        session.items[idx].isCompleted = true
        session.items[idx].pendingInputKg = ""
        session.items[idx].error = nil
        withAnimation { session.reorder() }
    }
}

// 小工具：计数比较
private extension Int {
    func equalTo(_ other: Int) -> Bool { self == other }
}

#Preview {
    NavigationStack {
        WeighingSessionView(pets: PetStore.previewStore().pets)
            .environmentObject(PetStore.previewStore())
    }
}
