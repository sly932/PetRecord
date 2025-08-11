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
    @Published var pets: [Pet] = []

    // MARK: - CRUD（示例实现，后续可替换为 Core Data 持久化）

    func addPet(_ pet: Pet) {
        pets.append(pet)
    }

    func updatePet(_ pet: Pet) {
        guard let idx = pets.firstIndex(where: { $0.id == pet.id }) else { return }
        pets[idx] = pet
    }

    func addWeight(for petId: UUID, date: Date = Date(), weightKg: Double) {
        guard let idx = pets.firstIndex(where: { $0.id == petId }) else { return }
        pets[idx].weights.append(WeightEntry(date: date, weightKg: weightKg))
    }

    func addDeworming(for petId: UUID, date: Date = Date(), medicineName: String, notes: String? = nil) {
        guard let idx = pets.firstIndex(where: { $0.id == petId }) else { return }
        pets[idx].dewormings.append(DewormingRecord(date: date, medicineName: medicineName, notes: notes))
    }
}

// MARK: - 预置/预览数据（便于 SwiftUI Preview 直接可见）
extension PetStore {
    static func previewStore() -> PetStore {
        let store = PetStore()
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
        store.pets = [pet1, pet2]
        return store
    }
}
