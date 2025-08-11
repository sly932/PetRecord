# Documentation 索引

面向 iOS App（SwiftUI + MVVM）的项目文档导航。建议按如下顺序阅读：

1. project_plan.md：目标/范围/里程碑（档案新增按钮、手动添加、编辑能力、Tabs 调整）
2. tech_stack.md
3. project_structure.md：新增 `PetEditorView`、`WeightFormView`、`DewormingFormView`
4. data_model.md：表单校验/默认值；不再使用随机写入
5. ux_design.md：编辑交互方案对比与推荐（方案A）、体重/驱虫手动添加、档案页不含体重总览

## 下一步
- 实现档案页“新增档案”按钮与 `PetEditorView`
- 体重/驱虫改为表单新增（替换演示写入），并接入校验
- 档案详情采用“编辑”模式（右上角按钮）统一保存/取消
