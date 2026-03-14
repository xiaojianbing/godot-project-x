# GPT Workflow Mapping

这个文件说明如何把 `.agents/workflows/multi-agent-workflow.md` 的工作方式映射到当前 GPT 环境，而不修改原有 Gemini 文件。

## Keep Both

- `.agents/workflows/multi-agent-workflow.md` 继续服务 Gemini。
- `AGENTS.md` 继续提供 GPT 会读取的仓库规则。
- `Docs/Workflow/` 提供你手动维护多角色独立会话时使用的文档工作台。

## Concept Mapping

| Gemini / Old Workflow | GPT / Current Setup |
| --- | --- |
| `.agents/workflows/multi-agent-workflow.md` | `AGENTS.md` + `Docs/Workflow/README.md` |
| `@Producer` | `Docs/Workflow/Roles/Producer.md` |
| `@Designer` | `Docs/Workflow/Roles/Designer.md` or `Docs/Workflow/Roles/Architect.md` |
| `@Developer` | `Docs/Workflow/Roles/Developer.md` |
| `@Tester` | `Docs/Workflow/Roles/Tester.md` |
| Stage handoff in chat | `Docs/Workflow/Handoffs/<slug>.md` |
| Long-running role context | `Docs/Workflow/Sessions/<slug>/<role>.md` |

## What Changes In GPT

- GPT 不会自动根据 `.agents/workflows/...` 创建多会话。
- 你需要自己维护四个固定聊天窗口，分别对应四个角色。
- 跨角色共享信息时，不依赖聊天记忆，而是依赖 handoff 文档。
- 同一角色的连续讨论，记录在该角色的 session 文档里。

## Suggested Chat Setup

### Chat 1: Producer

首条消息粘贴：

1. `Docs/Workflow/Roles/Producer.md`
2. `Docs/Workflow/Handoffs/<slug>.md`
3. 当前相关 `Docs/FeatureSpecs/...`

### Chat 2: Architect

首条消息粘贴：

1. `Docs/Workflow/Roles/Architect.md`
2. `Docs/Workflow/Handoffs/<slug>.md`
3. 当前相关 `Docs/FeatureSpecs/...`
4. 当前相关 `Docs/ModuleDesign/...`

### Chat 3: Developer

首条消息粘贴：

1. `Docs/Workflow/Roles/Developer.md`
2. `Docs/Workflow/Handoffs/<slug>.md`
3. 当前相关 `Docs/FeatureSpecs/...`
4. 当前相关 `Docs/ModuleDesign/...`
5. 目标代码文件或错误日志

### Chat 4: Tester

首条消息粘贴：

1. `Docs/Workflow/Roles/Tester.md`
2. `Docs/Workflow/Handoffs/<slug>.md`
3. 当前相关 `Docs/FeatureSpecs/...`
4. 当前相关 `Docs/ModuleDesign/...`
5. 当前相关 `Docs/TestCases/...`
6. 需要验证的实现说明

## Minimal Operating Loop

1. `Producer` 讨论需求并更新 Feature Spec。
2. 更新 `Docs/Workflow/Handoffs/<slug>.md`。
3. 切到 `Architect` 会话继续设计。
4. 更新 handoff。
5. 切到 `Developer` 会话实现。
6. 更新 handoff。
7. 切到 `Tester` 会话验证。
8. 如有缺陷，更新 handoff 并回流到对应角色。

## Role Naming

- 新体系推荐使用 `Architect`。
- 旧体系仍可继续用 `Designer`。
- 为兼容旧命名，`Docs/Workflow/Roles/Designer.md` 已指向 `Architect` 语义。

## Recommended Rule Of Thumb

- `AGENTS.md` 管规则。
- `.agents/...` 管 Gemini 兼容。
- `Docs/Workflow/Roles/` 管角色提示词。
- `Docs/Workflow/Handoffs/` 管跨角色共识。
- `Docs/Workflow/Sessions/` 管角色内长期记忆。
