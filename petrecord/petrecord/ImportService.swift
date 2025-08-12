// ImportService.swift
// 职责：从导出的 JSON（ExportService 生成的结构）解析为应用层 DTO，并返回 [Pet]
//
// 新手要点：
// - 与导出对应，我们定义了解析函数，严格匹配字段与日期格式（yyyy-MM-dd）。
// - 解析成功后，由 `PetStore.replaceAll(with:)` 负责“清库 + 覆盖写入”。

import Foundation

enum ImportService {
    /// 将 JSON 数据解析为应用层 DTO（[Pet]）
    /// - 参数 data: 来自文件或分享的 JSON 二进制
    /// - 返回: 解析得到的宠物数组
    /// - 抛错: JSON 格式不符或日期解析失败
    static func decodePets(from data: Data) throws -> [Pet] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        // 重用导出的数据结构（ExportPayload/ExportPet 等）
        let payload = try decoder.decode(ExportPayload.self, from: data)

        // 日期格式与导出一致（yyyy-MM-dd）
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .iso8601)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM-dd"

        let pets: [Pet] = try payload.pets.map { ep in
            let birthday: Date? = try {
                if let b = ep.birthday {
                    guard let d = f.date(from: b) else { throw ImportError.invalidDate("birthday:", b) }
                    return d
                }
                return nil
            }()

            let weights: [WeightEntry] = try ep.weights.map { ew in
                guard let d = f.date(from: ew.date) else { throw ImportError.invalidDate("weight:", ew.date) }
                return WeightEntry(id: ew.id, date: d, weightKg: ew.weightKg)
            }

            let dewormings: [DewormingRecord] = try ep.dewormings.map { ed in
                guard let d = f.date(from: ed.date) else { throw ImportError.invalidDate("deworm:", ed.date) }
                return DewormingRecord(id: ed.id, date: d, medicineName: ed.medicineName, notes: ed.notes)
            }

            return Pet(
                id: ep.id,
                name: ep.name,
                gender: Gender(rawValue: ep.gender) ?? .unknown,
                breed: ep.breed,
                birthday: birthday,
                notes: ep.notes,
                weights: weights,
                dewormings: dewormings
            )
        }

        return pets
    }

    enum ImportError: Error, LocalizedError {
        case invalidDate(String, String)

        var errorDescription: String? {
            switch self {
            case let .invalidDate(field, value):
                return "日期解析失败(\(field))：\(value)"
            }
        }
    }
}


