# 项目结构与目录说明（iOS SwiftUI + MVVM）

> 说明：你当前目录类似 `PetRecord/petrecord/petrecord`。这是 Xcode 常见形态：仓库根 → 工程根 → 源码目录。以下给出“推荐的功能分层”，不用立即重构，先按思想组织新文件即可。

## 1. 结构示例
```
PetRecord/
├─ documentation/
├─ petrecord/
│  ├─ petrecord.xcodeproj
│  ├─ petrecord/
│  │  ├─ App/
│  │  ├─ Shared/
│  │  │  ├─ Models/
│  │  │  ├─ Services/             # + ExportService（已有）/未来 Persistence
│  │  │  ├─ Components/
│  │  │  └─ Utils/
│  │  ├─ Features/
│  │  │  ├─ Tabs/
│  │  │  ├─ PetProfile/
│  │  │  │  ├─ PetListView.swift        # 档案列表（顶部“新增档案”按钮）
│  │  │  │  ├─ PetDetailView.swift      # 档案详情（查看）
│  │  │  │  └─ PetEditorView.swift      # 档案编辑（方案A：整页编辑）
│  │  │  ├─ Weight/
│  │  │  │  ├─ WeightPanelView.swift    # 单宠体重
│  │  │  │  ├─ AllPetsWeightView.swift  # 体重总览（入口仅在“数据”Tab）
│  │  │  │  └─ WeightFormView.swift     # 新增体重表单
│  │  │  └─ Deworming/
│  │  │     ├─ DewormingPanelView.swift # 单宠驱虫
│  │  │     └─ DewormingFormView.swift  # 新增驱虫表单
│  │  ├─ Data/
│  │  └─ Resources/
│  └─ Tests/
```

## 2. 分层说明
- PetProfile：新增 `PetEditorView`；列表顶部加“新增档案”按钮
- Weight/Deworming：新增表单视图用于手动添加记录；移除任何随机/演示数据写入
- Tabs：档案页不再包含体重总览入口；总览入口统一在“数据”Tab 中

## 3. 命名与文件拆分建议
- 功能文件夹内使用 MVVM 命名：`XxxView`、`XxxViewModel`
- 视图小而专注；通用 UI 下沉到 Components
- 模型字段命名语义化、统一单位（体重：kg；可在 UI 支持 lb 转换）
