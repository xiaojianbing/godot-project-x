# Multi-Session Workflow

这套目录用于给 `Producer / Architect / Developer / Tester` 四个角色分别维护独立会话与交接记录。

它不会被 GPT 自动当作系统规则执行，而是作为你手动组织多会话协作的工作台。

## Goals

- 让每个角色拥有长期独立会话，不互相污染上下文。
- 让跨角色信息通过文档交接，而不是依赖聊天记忆。
- 让同一功能在不同阶段都能持续讨论，并保留决策痕迹。

## Structure

- `Docs/Workflow/Roles/`: 每个角色的职责说明与开场提示词。
- `Docs/Workflow/Handoffs/`: 跨角色交接文档。
- `Docs/Workflow/Sessions/`: 每个功能在每个角色会话中的讨论记录。

## Naming

- 推荐四个主角色：`@Producer`、`@Architect`、`@Developer`、`@Tester`。
- 如果旧工作流或其他工具使用 `@Designer`，可将其视为 `@Architect` 的兼容别名。

## Recommended Usage

1. 为一个功能创建 slug，例如 `air-dash`。
2. 复制 `Docs/Workflow/Handoffs/_Template.md` 为 `Docs/Workflow/Handoffs/air-dash.md`。
3. 新建目录 `Docs/Workflow/Sessions/air-dash/`。
4. 复制 `Docs/Workflow/Sessions/_Template.md` 为以下四个文件：
   - `Docs/Workflow/Sessions/air-dash/producer.md`
   - `Docs/Workflow/Sessions/air-dash/architect.md`
   - `Docs/Workflow/Sessions/air-dash/developer.md`
   - `Docs/Workflow/Sessions/air-dash/tester.md`
5. 分别打开四个聊天会话，并在每个会话的第一条消息中粘贴：
   - 对应的角色文件内容
   - 当前 handoff 文档
   - 当前阶段相关的 Feature Spec / Module Design / Test Case 文档
6. 每次阶段结束后，先更新 handoff，再切换到下一个角色会话。

## Quick Start Script

- 手动建文件以外，也可以直接运行脚手架脚本：
- `powershell -ExecutionPolicy Bypass -File "Docs/Workflow/New-FeatureWorkflow.ps1" -Slug "air-dash" -FeatureName "Air Dash"`
- 这会自动创建：
  - `Docs/Workflow/Handoffs/air-dash.md`
  - `Docs/Workflow/Sessions/air-dash/producer.md`
  - `Docs/Workflow/Sessions/air-dash/architect.md`
  - `Docs/Workflow/Sessions/air-dash/developer.md`
  - `Docs/Workflow/Sessions/air-dash/tester.md`
- 预演而不落盘时，可加 `-WhatIf`。

## Migration Notes

- 旧的 Gemini 工作流仍保留在 `.agents/workflows/multi-agent-workflow.md`。
- GPT 环境不会自动执行该文件，但你可以继续把它当作参考说明。
- 角色会话实际落地时，以 `Docs/Workflow/` 下的角色文件、handoff 文件和 session 文件为准。

## Handoff Rules

- `Producer` 负责确认目标、价值、范围和验收标准。
- `Architect` 负责确认架构方案、状态拆分、API 形状和技术风险。
- `Developer` 负责根据已审阅设计实现代码，并记录偏差。
- `Tester` 负责验证行为、补充测试文档并把缺陷回传。

## Session Discipline

- 每个角色只处理自己的阶段任务，不提前越界。
- 每个角色会话都应持续更新自己的 `Sessions/<slug>/<role>.md`。
- 所有跨角色的结论，以 `Handoffs/<slug>.md` 为准。
- 如果实现阶段发现设计缺口，应退回 `Architect` 会话，而不是在 `Developer` 会话中悄悄改设计。
