// ExportService.swift
// 数据导出服务：将当前内存数据编码为 JSON，并提供保存/分享支持
// 知识点：JSONEncoder + ISO8601 日期；ShareLink/DocumentPicker 可在 View 使用

import Foundation

struct ExportPayload: Codable {
    let version: Int
    let exportedAt: Date
    let pets: [ExportPet]
}

struct ExportPet: Codable {
    let id: UUID
    let name: String
    let gender: String
    let breed: String
    let birthday: String?
    let notes: String?
    let weights: [ExportWeight]
    let dewormings: [ExportDeworming]
}

struct ExportWeight: Codable {
    let id: UUID
    let date: String
    let weightKg: Double
}

struct ExportDeworming: Codable {
    let id: UUID
    let date: String
    let medicineName: String
    let dosage: String?
    let notes: String?
}

enum ExportService {
    static func makeJSON(store: PetStore) throws -> Data {
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = Calendar(identifier: .iso8601)
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let pets = store.pets.map { pet -> ExportPet in
            let weights = pet.weights.sorted { $0.date < $1.date }.map { w in
                ExportWeight(id: w.id, date: dateFormatter.string(from: w.date), weightKg: w.weightKg)
            }
            let dewormings = pet.dewormings.sorted { $0.date < $1.date }.map { d in
                ExportDeworming(id: d.id, date: dateFormatter.string(from: d.date), medicineName: d.medicineName, dosage: nil, notes: d.notes)
            }
            return ExportPet(
                id: pet.id,
                name: pet.name,
                gender: pet.gender.rawValue,
                breed: pet.breed,
                birthday: pet.birthday.map { dateFormatter.string(from: $0) },
                notes: pet.notes,
                weights: weights,
                dewormings: dewormings
            )
        }

        let payload = ExportPayload(version: 1, exportedAt: Date(), pets: pets)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(payload)
    }

    static func suggestedFileName(at date: Date = Date()) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd"
        return "PetRecord-\(f.string(from: date)).json"
    }
}
