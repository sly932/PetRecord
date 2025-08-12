// Models.swift
// PetRecord iOS
//
// 内容：数据模型（DTO）+ 简易内存数据仓库（PetStore）
// 目的：先跑通 UI 预览与基本交互，不依赖持久化；后续可替换为 Core Data
// 知识点：
// - 使用 struct 表达不可变/值语义的数据模型
// - 使用 ObservableObject + @Published 驱动 SwiftUI 刷新
// - 通过 id 关联实体，便于在数组中查找与更新

import Foundation
import SwiftUI
import CoreData

/// 性别枚举（受限值，避免魔法字符串）
enum Gender: String, CaseIterable, Codable, Identifiable {
    case male
    case female
    case unknown
    var id: String { rawValue }
}

/// 体重记录（单位统一为 kg；显示时再做单位转换）
struct WeightEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var date: Date
    var weightKg: Double
    init(id: UUID = UUID(), date: Date, weightKg: Double) {
        self.id = id
        self.date = date
        self.weightKg = weightKg
    }
}

/// 驱虫记录
enum DewormingMedicine: String, CaseIterable, Codable {
    case unknown
}

struct DewormingRecord: Identifiable, Codable, Equatable {
    let id: UUID
    var date: Date
    var medicineName: String
    var notes: String?
    init(id: UUID = UUID(), date: Date, medicineName: String, notes: String? = nil) {
        self.id = id
        self.date = date
        self.medicineName = medicineName
        self.notes = notes
    }
}

/// 宠物实体（聚合体：包含体重/驱虫子记录）
struct Pet: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var gender: Gender
    var breed: String
    var birthday: Date?
    var notes: String?
    var weights: [WeightEntry]
    var dewormings: [DewormingRecord]

    init(
        id: UUID = UUID(),
        name: String,
        gender: Gender,
        breed: String,
        birthday: Date? = nil,
        notes: String? = nil,
        weights: [WeightEntry] = [],
        dewormings: [DewormingRecord] = []
    ) {
        self.id = id
        self.name = name
        self.gender = gender
        self.breed = breed
        self.birthday = birthday
        self.notes = notes
        self.weights = weights
        self.dewormings = dewormings
    }

    /// 计算属性：当前体重（取最近一条）
    var currentWeightKg: Double? {
        weights.sorted { $0.date < $1.date }.last?.weightKg
    }
}

/// 简易仓库：管理内存中的宠物数组，供 SwiftUI 环境共享
/// - 流程：视图通过 EnvironmentObject 引用仓库 → 调用增删改方法 → @Published 触发 UI 刷新
final class PetStore: ObservableObject {
    /// 对外发布的应用层数据（UI 直接使用）
    @Published var pets: [Pet] = []

    /// 持久化管理器（Core Data 封装）
    private let core: CoreDataManager

    /// 初始化
    /// - 参数：
    ///   - coreDataManager: 可注入自定义管理器，默认使用本地持久化；预览/测试可传入 `inMemory: true`
    init(coreDataManager: CoreDataManager = CoreDataManager()) {
        self.core = coreDataManager
        loadAll()
    }

    /// 从持久化层读取全部数据，刷新 UI 绑定
    func loadAll() {
        do {
            pets = try core.fetchAllPets()
        } catch {
            // 简单处理：读取失败则清空（实际项目可上报/打点）
            pets = []
        }
    }

    // MARK: - CRUD：统一落到 Core Data，再刷新内存镜像

    /// 新增宠物
    func addPet(_ pet: Pet) {
        do {
            try core.addPet(pet)
            loadAll()
        } catch {
            // 可以加入错误提示管道
        }
    }

    /// 更新宠物基本信息
    func updatePet(_ pet: Pet) {
        do {
            try core.updatePet(pet)
            loadAll()
        } catch {
        }
    }

    /// 添加体重
    func addWeight(for petId: UUID, date: Date = Date(), weightKg: Double) {
        guard weightKg > 0 else { return }
        do {
            _ = try core.addWeight(petId: petId, date: date, weightKg: weightKg)
            loadAll()
        } catch {
        }
    }

    /// 添加驱虫
    func addDeworming(for petId: UUID, date: Date = Date(), medicineName: String, notes: String? = nil) {
        do {
            _ = try core.addDeworming(petId: petId, date: date, medicineName: medicineName, notes: notes)
            loadAll()
        } catch {
        }
    }

    /// 用导入的数据覆盖全部（用于 JSON 导入）
    func replaceAll(with pets: [Pet]) {
        do {
            try core.replaceAll(with: pets)
            loadAll()
        } catch {
        }
    }
}

// MARK: - 预置/预览数据（便于 SwiftUI Preview 直接可见）
extension PetStore {
    static func previewStore() -> PetStore {
        // 预览使用内存型 Core Data，避免污染真数据
        let manager = CoreDataManager(inMemory: true)
        let store = PetStore(coreDataManager: manager)

        // 构造示例数据并写入持久层，随后统一通过 loadAll() 刷新
        let now = Date()
        let days: [Int] = [0, -7, -14, -21, -28]
        func w(_ base: Double, _ d: Int) -> WeightEntry { .init(date: Calendar.current.date(byAdding: .day, value: d, to: now)!, weightKg: base + Double(Int.random(in: -2...2)) * 0.1) }

        let pet1 = Pet(
            name: "Milo",
            gender: .male,
            breed: "Shiba Inu",
            birthday: Calendar.current.date(byAdding: .year, value: -2, to: now),
            weights: days.map { w(9.5, $0) },
            dewormings: [
                .init(date: Calendar.current.date(byAdding: .month, value: -1, to: now)!, medicineName: "Broadline")
            ]
        )
        let pet2 = Pet(
            name: "Luna",
            gender: .female,
            breed: "British Shorthair",
            birthday: Calendar.current.date(byAdding: .year, value: -1, to: now),
            weights: days.map { w(3.8, $0) },
            dewormings: [
                .init(date: Calendar.current.date(byAdding: .month, value: -2, to: now)!, medicineName: "Revolution")
            ]
        )
        // 写入
        do {
            try manager.addPet(pet1)
            try manager.addPet(pet2)
            for w in pet1.weights { _ = try manager.addWeight(petId: pet1.id, date: w.date, weightKg: w.weightKg) }
            for d in pet1.dewormings { _ = try manager.addDeworming(petId: pet1.id, date: d.date, medicineName: d.medicineName, notes: d.notes) }
            for w in pet2.weights { _ = try manager.addWeight(petId: pet2.id, date: w.date, weightKg: w.weightKg) }
            for d in pet2.dewormings { _ = try manager.addDeworming(petId: pet2.id, date: d.date, medicineName: d.medicineName, notes: d.notes) }
        } catch { }

        store.loadAll()
        return store
    }
}
