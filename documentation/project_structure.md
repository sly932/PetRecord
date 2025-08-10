# 项目结构与目录说明（iOS SwiftUI + MVVM）

> 说明：你当前目录类似 `PetRecord/petrecord/petrecord`。这是 Xcode 常见形态：仓库根 → 工程根 → 源码目录。以下给出“推荐的功能分层”，不用立即重构，先按思想组织新文件即可。

## 1. 结构示例
```
PetRecord/
├─ documentation/                  # 文档（本目录）
├─ petrecord/                      # Xcode 工程根
│  ├─ petrecord.xcodeproj
│  ├─ petrecord/                   # 源码根（App Target 同名）
│  │  ├─ App/                      # App 入口与全局配置
│  │  │  └─ PetRecordApp.swift
│  │  ├─ Shared/
│  │  │  ├─ Models/               # 数据模型（DTO/实体），与 Core Data 映射
│  │  │  ├─ Services/             # 持久化/通知/图表数据准备 等服务
│  │  │  ├─ Components/           # 可复用通用组件（UI）
│  │  │  └─ Utils/                # 工具方法、格式化、单位换算
│  │  ├─ Features/
│  │  │  ├─ PetProfile/           # 宠物档案（列表/详情/编辑）
│  │  │  ├─ Weight/               # 体重（新增/列表/图表）
│  │  │  └─ Deworming/            # 驱虫（新增/列表/时间轴）
│  │  ├─ Data/
│  │  │  ├─ CoreData/             # .xcdatamodeld 模型文件与子版本
│  │  │  └─ Migrations/           # 迁移脚本/说明（如需要）
│  │  └─ Resources/               # 资源（Assets、本地化）
│  └─ Tests/                       # XCTest 测试
└─ .gitignore
```

## 2. 分层说明（给新手的“放什么”的指南）
- App：应用启动入口、依赖注入、全局样式/主题
- Shared/Models：
  - DTO/简单结构体（供视图模型使用）
  - 与 Core Data 的 NSManagedObject 子类或生成文件（如使用）
- Shared/Services：
  - PersistenceService（Core Data 封装）
  - NotificationService（提醒通知）
  - ChartDataService（整理图表数据）
- Features/*：以业务功能为边界，包含 View、ViewModel、子视图等
- Data/CoreData：数据模型版本管理，新增字段/实体时新增子版本

## 3. 命名与文件拆分建议
- 功能文件夹内使用 MVVM 命名：`XxxView`、`XxxViewModel`
- 视图小而专注；通用 UI 下沉到 Components
- 模型字段命名语义化、统一单位（体重：kg；可在 UI 支持 lb 转换）
