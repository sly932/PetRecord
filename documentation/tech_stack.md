# 技术栈与方案（iOS 原生）

## 1. 语言与最低版本
- Swift 5.9+
- iOS 16+（可使用 Swift Charts；若需支持更低版本，图表库另选）

## 2. UI 与架构
- UI 框架：SwiftUI（声明式、开发效率高，适合新项目）
- 架构模式：MVVM
  - View：SwiftUI 视图，仅负责展示与用户交互
  - ViewModel：`@Published` 状态、业务编排、输入输出绑定
  - Model：数据实体与持久化映射（Core Data/DTO）
- 路由：`NavigationStack`（iOS 16+ 标准导航）

## 3. 数据持久化
- 首选：Core Data（Apple 官方，离线优先，后续可扩展 CloudKit 同步）
  - 优点：与 Swift/SwiftUI 生态整合好、性能可观、可建关系
  - 替代：SQLite/Realm（若对迁移/多平台有特殊要求）

## 4. 图表与可视化
- 首选：Swift Charts（iOS 16+ 原生图表）
  - 备选：Charts（第三方，支持更低 iOS 版本）

## 5. 响应式与异步
- Combine（`ObservableObject`/`@Published`）或 async/await（网络/异步任务）
- 对于本地持久化为主的场景，Combine 足够；如需并发任务，配合 async/await

## 6. 包管理与依赖
- Swift Package Manager（SPM）优先
  - 第三方（按需）：SwiftLint、Charts(如需)、SnapshotTesting 等

## 7. 测试与质量
- XCTest（单元/视图模型测试）
- SwiftLint（代码规范）
- Xcode Instruments（性能/内存）

## 8. 本地通知（可选）
- UserNotifications（下次驱虫提醒、定期称重提醒）

## 9. 为何如此选择（给新手的关键点）
- SwiftUI+MVVM：更少样板代码，学习曲线相对顺滑
- Core Data：离线优先、一体化，适合本地数据驱动的健康记录应用
- Swift Charts：原生质量/交互一致性高，维护成本低
