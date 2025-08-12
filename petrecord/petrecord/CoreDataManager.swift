// CoreDataManager.swift
// 职责：
// - 以“纯代码”方式构建 Core Data 模型（无需 .xcdatamodeld 文件）
// - 提供统一的持久化接口：查询全部、增改宠物、添加体重/驱虫、整体替换数据
// - 将 NSManagedObject 转换为应用层 DTO（`Pet`/`WeightEntry`/`DewormingRecord`）
//
// 设计与知识点（面向新手）：
// 1) Core Data 两层模型：
//    - 持久化层（NSManagedObjectModel + NSPersistentContainer + NSManagedObjectContext）
//    - 应用层 DTO（本项目使用 struct `Pet` 等，见 Models.swift）
//    我们通过“转换函数”在两层之间映射，保持 UI 与业务的值类型简洁性。
// 2) 纯代码模型：
//    - 现实项目常用 .xcdatamodeld（可视化编辑）；这里用“代码创建”方便在仓库中直接查看与修改。
// 3) 线程/上下文：
//    - 这里简单使用主队列上下文（viewContext）进行读写，满足本地小数据量场景。
//    - 如需更高性能，可在后台上下文写入并回主线程刷新。

import Foundation
import CoreData

/// Core Data 管理器：封装容器、上下文与对象转换
final class CoreDataManager {
    // MARK: - Public

    /// 持久化容器（包含模型、存储与上下文）
    let container: NSPersistentContainer

    /// 便捷访问主上下文（用于简单读写；复杂场景建议使用后台上下文）
    var context: NSManagedObjectContext { container.viewContext }

    /// 初始化
    /// - Parameters:
    ///   - inMemory: 是否使用内存存储（用于 SwiftUI 预览/单元测试）
    init(inMemory: Bool = false) {
        // 1) 构建“纯代码”模型
        let model = CoreDataManager.buildManagedObjectModel()

        // 2) 构建容器并配置存储类型
        container = NSPersistentContainer(name: "PetRecordCoreData", managedObjectModel: model)

        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [description]
        }

        // 3) 加载存储
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("加载持久化存储失败：\(error)")
            }
        }

        // 4) 合并策略：属性覆盖，以应用层为准
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // MARK: - CRUD 接口（面向应用层 DTO）

    /// 查询全部宠物（包含体重与驱虫记录）
    func fetchAllPets() throws -> [Pet] {
        let request = NSFetchRequest<NSManagedObject>(entityName: "PetEntity")
        request.relationshipKeyPathsForPrefetching = ["weights", "dewormings"]
        let result = try context.fetch(request)
        return result.compactMap { self.convertToPet($0) }
    }

    /// 新增宠物
    func addPet(_ pet: Pet) throws {
        _ = try upsertPetInternal(pet)
        try context.save()
    }

    /// 更新宠物基本信息（不动子记录）
    func updatePet(_ pet: Pet) throws {
        guard let obj = try fetchPetEntity(by: pet.id) else { return }
        setPetFields(from: pet, to: obj)
        try context.save()
    }

    /// 为指定宠物添加体重记录
    @discardableResult
    func addWeight(petId: UUID, date: Date, weightKg: Double) throws -> WeightEntry? {
        guard let petObj = try fetchPetEntity(by: petId) else { return nil }
        let weightEntity = NSEntityDescription.insertNewObject(forEntityName: "WeightEntryEntity", into: context)
        weightEntity.setValue(UUID(), forKey: "id")
        weightEntity.setValue(date, forKey: "date")
        weightEntity.setValue(weightKg, forKey: "weightKg")
        weightEntity.setValue(petObj, forKey: "pet")
        try context.save()
        return convertToWeight(weightEntity)
    }

    /// 为指定宠物添加驱虫记录
    @discardableResult
    func addDeworming(petId: UUID, date: Date, medicineName: String, notes: String?) throws -> DewormingRecord? {
        guard let petObj = try fetchPetEntity(by: petId) else { return nil }
        let entity = NSEntityDescription.insertNewObject(forEntityName: "DewormingEntity", into: context)
        entity.setValue(UUID(), forKey: "id")
        entity.setValue(date, forKey: "date")
        entity.setValue(medicineName, forKey: "medicineName")
        entity.setValue(notes, forKey: "notes")
        entity.setValue(petObj, forKey: "pet")
        try context.save()
        return convertToDeworming(entity)
    }

    /// 用导入的数据替换全部（清库→插入→保存）
    func replaceAll(with pets: [Pet]) throws {
        try deleteAll()
        for pet in pets {
            let petObj = try upsertPetInternal(pet)
            // 插入权威子记录（覆盖）
            if let weights = pet.weights as [WeightEntry]? {
                for w in weights {
                    let wObj = NSEntityDescription.insertNewObject(forEntityName: "WeightEntryEntity", into: context)
                    wObj.setValue(w.id, forKey: "id")
                    wObj.setValue(w.date, forKey: "date")
                    wObj.setValue(w.weightKg, forKey: "weightKg")
                    wObj.setValue(petObj, forKey: "pet")
                }
            }
            if let dewormings = pet.dewormings as [DewormingRecord]? {
                for d in dewormings {
                    let dObj = NSEntityDescription.insertNewObject(forEntityName: "DewormingEntity", into: context)
                    dObj.setValue(d.id, forKey: "id")
                    dObj.setValue(d.date, forKey: "date")
                    dObj.setValue(d.medicineName, forKey: "medicineName")
                    dObj.setValue(d.notes, forKey: "notes")
                    dObj.setValue(petObj, forKey: "pet")
                }
            }
        }
        try context.save()
    }

    // MARK: - 私有：对象增改/查询/删除/转换

    /// 新建或更新宠物（不处理子记录）并返回实体对象
    private func upsertPetInternal(_ pet: Pet) throws -> NSManagedObject {
        if let obj = try fetchPetEntity(by: pet.id) {
            setPetFields(from: pet, to: obj)
            return obj
        } else {
            let obj = NSEntityDescription.insertNewObject(forEntityName: "PetEntity", into: context)
            setPetFields(from: pet, to: obj)
            return obj
        }
    }

    /// 设置宠物基本字段（不含关系）
    private func setPetFields(from pet: Pet, to obj: NSManagedObject) {
        obj.setValue(pet.id, forKey: "id")
        obj.setValue(pet.name, forKey: "name")
        obj.setValue(pet.gender.rawValue, forKey: "gender")
        obj.setValue(pet.breed, forKey: "breed")
        obj.setValue(pet.birthday, forKey: "birthday")
        obj.setValue(pet.notes, forKey: "notes")
    }

    /// 通过 id 查询宠物实体
    private func fetchPetEntity(by id: UUID) throws -> NSManagedObject? {
        let request = NSFetchRequest<NSManagedObject>(entityName: "PetEntity")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    /// 删除所有数据（宠物与关联记录）
    private func deleteAll() throws {
        let entities = ["WeightEntryEntity", "DewormingEntity", "PetEntity"]
        for name in entities {
            let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: name)
            let batch = NSBatchDeleteRequest(fetchRequest: fetch)
            try container.persistentStoreCoordinator.execute(batch, with: context)
        }
        context.reset()
    }

    // MARK: - 转换：ManagedObject → DTO

    private func convertToPet(_ obj: NSManagedObject) -> Pet? {
        guard
            let id = obj.value(forKey: "id") as? UUID,
            let name = obj.value(forKey: "name") as? String,
            let genderRaw = obj.value(forKey: "gender") as? String,
            let breed = obj.value(forKey: "breed") as? String
        else { return nil }

        let birthday = obj.value(forKey: "birthday") as? Date
        let notes = obj.value(forKey: "notes") as? String

        // 关系：weights / dewormings
        let weightSet = obj.value(forKey: "weights") as? Set<NSManagedObject> ?? []
        let dewormingSet = obj.value(forKey: "dewormings") as? Set<NSManagedObject> ?? []

        let weights: [WeightEntry] = weightSet.compactMap { convertToWeight($0) }.sorted { $0.date < $1.date }
        let dewormings: [DewormingRecord] = dewormingSet.compactMap { convertToDeworming($0) }.sorted { $0.date < $1.date }

        return Pet(
            id: id,
            name: name,
            gender: Gender(rawValue: genderRaw) ?? .unknown,
            breed: breed,
            birthday: birthday,
            notes: notes,
            weights: weights,
            dewormings: dewormings
        )
    }

    private func convertToWeight(_ obj: NSManagedObject) -> WeightEntry? {
        guard
            let id = obj.value(forKey: "id") as? UUID,
            let date = obj.value(forKey: "date") as? Date,
            let weightKg = obj.value(forKey: "weightKg") as? Double
        else { return nil }
        return WeightEntry(id: id, date: date, weightKg: weightKg)
    }

    private func convertToDeworming(_ obj: NSManagedObject) -> DewormingRecord? {
        guard
            let id = obj.value(forKey: "id") as? UUID,
            let date = obj.value(forKey: "date") as? Date,
            let medicineName = obj.value(forKey: "medicineName") as? String
        else { return nil }
        let notes = obj.value(forKey: "notes") as? String
        return DewormingRecord(id: id, date: date, medicineName: medicineName, notes: notes)
    }

    // MARK: - 模型构建（纯代码）

    /// 使用 NSAttributeDescription / NSRelationshipDescription 构建模型
    private static func buildManagedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // PetEntity
        let petEntity = NSEntityDescription()
        petEntity.name = "PetEntity"
        petEntity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)

        let pet_id = NSAttributeDescription()
        pet_id.name = "id"
        pet_id.attributeType = .UUIDAttributeType
        pet_id.isOptional = false

        let pet_name = NSAttributeDescription()
        pet_name.name = "name"
        pet_name.attributeType = .stringAttributeType
        pet_name.isOptional = false

        let pet_gender = NSAttributeDescription()
        pet_gender.name = "gender"
        pet_gender.attributeType = .stringAttributeType
        pet_gender.isOptional = false

        let pet_breed = NSAttributeDescription()
        pet_breed.name = "breed"
        pet_breed.attributeType = .stringAttributeType
        pet_breed.isOptional = false

        let pet_birthday = NSAttributeDescription()
        pet_birthday.name = "birthday"
        pet_birthday.attributeType = .dateAttributeType
        pet_birthday.isOptional = true

        let pet_notes = NSAttributeDescription()
        pet_notes.name = "notes"
        pet_notes.attributeType = .stringAttributeType
        pet_notes.isOptional = true

        petEntity.properties = [pet_id, pet_name, pet_gender, pet_breed, pet_birthday, pet_notes]

        // WeightEntryEntity
        let weightEntity = NSEntityDescription()
        weightEntity.name = "WeightEntryEntity"
        weightEntity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)

        let w_id = NSAttributeDescription()
        w_id.name = "id"
        w_id.attributeType = .UUIDAttributeType
        w_id.isOptional = false

        let w_date = NSAttributeDescription()
        w_date.name = "date"
        w_date.attributeType = .dateAttributeType
        w_date.isOptional = false

        let w_weight = NSAttributeDescription()
        w_weight.name = "weightKg"
        w_weight.attributeType = .doubleAttributeType
        w_weight.isOptional = false

        // to-one -> PetEntity
        let w_pet = NSRelationshipDescription()
        w_pet.name = "pet"
        w_pet.destinationEntity = petEntity
        w_pet.minCount = 0
        w_pet.maxCount = 1
        w_pet.deleteRule = .nullifyDeleteRule

        weightEntity.properties = [w_id, w_date, w_weight, w_pet]

        // DewormingEntity
        let dewormEntity = NSEntityDescription()
        dewormEntity.name = "DewormingEntity"
        dewormEntity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)

        let d_id = NSAttributeDescription()
        d_id.name = "id"
        d_id.attributeType = .UUIDAttributeType
        d_id.isOptional = false

        let d_date = NSAttributeDescription()
        d_date.name = "date"
        d_date.attributeType = .dateAttributeType
        d_date.isOptional = false

        let d_med = NSAttributeDescription()
        d_med.name = "medicineName"
        d_med.attributeType = .stringAttributeType
        d_med.isOptional = false

        let d_notes = NSAttributeDescription()
        d_notes.name = "notes"
        d_notes.attributeType = .stringAttributeType
        d_notes.isOptional = true

        // to-one -> PetEntity
        let d_pet = NSRelationshipDescription()
        d_pet.name = "pet"
        d_pet.destinationEntity = petEntity
        d_pet.minCount = 0
        d_pet.maxCount = 1
        d_pet.deleteRule = .nullifyDeleteRule

        dewormEntity.properties = [d_id, d_date, d_med, d_notes, d_pet]

        // 反向关系：Pet.weights / Pet.dewormings（to-many）
        let p_weights = NSRelationshipDescription()
        p_weights.name = "weights"
        p_weights.destinationEntity = weightEntity
        p_weights.minCount = 0
        p_weights.maxCount = 0 // 0 表示不限制（to-many）
        p_weights.deleteRule = .cascadeDeleteRule

        let p_deworms = NSRelationshipDescription()
        p_deworms.name = "dewormings"
        p_deworms.destinationEntity = dewormEntity
        p_deworms.minCount = 0
        p_deworms.maxCount = 0
        p_deworms.deleteRule = .cascadeDeleteRule

        // 设置关系的 inverse（成对）
        p_weights.inverseRelationship = w_pet
        w_pet.inverseRelationship = p_weights
        p_deworms.inverseRelationship = d_pet
        d_pet.inverseRelationship = p_deworms

        // 将反向关系加入 PetEntity 的 properties
        petEntity.properties.append(contentsOf: [p_weights, p_deworms])

        model.entities = [petEntity, weightEntity, dewormEntity]
        return model
    }
}


