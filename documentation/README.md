# Documentation 索引

面向 iOS App（SwiftUI + MVVM）的项目文档导航。建议按如下顺序阅读：

1. project_plan.md：项目目标、范围、里程碑与导航信息流（含 Mermaid）
2. tech_stack.md：技术栈与方案选择（SwiftUI/MVVM/Core Data/Swift Charts 等）
3. project_structure.md：推荐的目录结构与分层说明
4. data_model.md：实体字段、关系、ER 图与校验约束
5. ux_design.md：导航与交互、关键界面、Figma/原型建议与决策

## 核心结论（速览）
- 架构：SwiftUI + MVVM；持久化：Core Data；图表：Swift Charts（iOS 16+）
- 实体：Pet、WeightEntry、DewormingRecord；统一存储体重单位为 kg
- 导航：主页（宠物列表）→ 宠物档案 → 单宠体重/驱虫；另有“所有宠物体重面板”可互相跳转
- 决策：单独设立“体重功能面板”，档案中仅做概览与入口，避免重复 UI

## 下一步（只描述，不含命令）
- 在 Xcode 建立 Core Data 模型（依据 data_model.md）
- 新建基础界面骨架：宠物列表、档案详情、体重面板、驱虫面板
- 实现体重/驱虫的新增与列表；体重曲线可视化（Swift Charts）
- 可选：准备 4–5 张低保真线框（Figma）以锁定导航与布局
