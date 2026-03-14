# Character Feature Architect Session

## Session Meta

- Role: architect
- Feature: Character Feature
- Slug: character-feature
- Date: 2026-03-13

## Current Objective

- 基于已审阅的 Feature Spec，输出统一角色系统的架构设计方案，重点解决 `CharacterStats` / `CharacterContext` 的职责边界、模块拆分、受击响应链路与不同实体的最小接入模型。

## Context Read

- Handoff: `docs/Workflow/Handoffs/character-feature.md`
- Feature Spec: `docs/FeatureSpecs/CharacterFeature.md`
- Module Design: `docs/ModuleDesign/CharacterFeature.md`
- Test Cases: `docs/TestCase/character-feature.md`
- Code / Logs: 按仓库规则，若涉及 bug 现象或现有实现偏差，先检查 `D:/projects/ProjectXII/Logger/` 最新日志；随后阅读角色控制、受击、数值、动画桥接相关脚本

## Architect Mission

- 将 `CharacterFeature` 从产品规格转化为可实现的系统设计，但本阶段**不写代码**。
- 设计必须覆盖 Player、Enemy、Boss、NPC、可破坏道具这五类实体的接入差异。
- 重点解决如何在不让 `CharacterContext` 失控膨胀的前提下，形成统一角色系统的最小闭环。
- 设计必须兼容项目现有 HFSM、`ActionPriority`、Kinematic Rigidbody2D、`FixedUpdate` + `MovePosition`、New Input System 等硬约束。

## Required Outputs

- 一份 Module Design 增补或新设计文档。
- 明确的模块拆分与职责表。
- 明确的运行时协作关系：StateMachine / CharacterContext / CharacterStats / 受击协调 / 动画桥接。
- 不同实体类型的接入矩阵与最小实现要求。
- 受击到行为响应的状态流或时序图。
- 面向 `Developer` 的实现约束与禁止事项。
- 技术风险评估，并标记 `low` / `medium` / `high`。

## Must Solve

### 1. `CharacterContext` 职责拆分

- 需要判断 `CharacterContext` 是否保持单体运行时枢纽，还是拆分为多个协作对象。
- 需要明确它保留哪些职责，哪些应下放给专用模块。
- 需要避免其演变成跨系统上帝对象。

### 2. `CharacterStats` 与行为层边界

- 需要定义数值变化、Buff、伤害结算、事件抛出应停留在哪一层。
- 需要明确行为层如何读取数值结果，而不与数值层强耦合。

### 3. 受击响应链路

- 需要设计从 `IDamageable.TakeDamage(HitData)` 到 HP 变化、霸体判断、受击硬直或死亡结果之间的完整链路。
- 需要说明哪部分属于通用角色系统，哪部分属于 Combat 或具体实体逻辑。

### 4. 实体接入矩阵

- 需要分别给出 Player、Enemy、Boss、NPC、可破坏道具的最小接入方案。
- 需要说明哪些实体只接入 `CharacterStats`，哪些需要完整 `CharacterContext`。
- 需要说明 `NPC` 的 HP 可选支持如何落地。

### 5. 模块边界

- 需要明确统一角色系统与 Respawn、Combat、Animation、Buff、AI 的边界。
- 需要说明哪些规则属于角色系统，哪些规则应交给外部系统处理。

### 6. 阶段落地策略

- 需要将 P0-A ~ P0-D 的产品完成定义转译成可实现的模块落地顺序。
- 需要确保 P0-A 能形成 Player / Enemy / 可破坏道具的最小闭环。

## Constraints

- 本阶段只做设计，不写实现代码。
- 不得绕开现有 HFSM 与 `ActionPriority` 约束。
- 不得把 Respawn 规则重新写回 `CharacterFeature` 体系。
- 不得直接编辑 `.prefab`、`.unity`、`.asset` 等 Unity 序列化资源。
- 若设计依赖现有 bug 或运行异常判断，必须先检查 `Logger/` 最新日志。

## Recommended Design Direction

- 将 `CharacterStats` 保持为偏纯数值层，不直接承担复杂行为切换。
- 将 `CharacterContext` 约束为运行时访问枢纽，而不是完整规则编排中心。
- 对受击响应考虑独立协调层或清晰的事件链，避免数值层和状态层直接缠死。
- 对不同实体采用“最小必要接入”策略，而不是强迫所有实体挂完整角色能力。
- 在 Player、Enemy、Boss、NPC、可破坏道具之间保持统一术语，但允许接入深度不同。

## Questions To Answer

- `CharacterContext` 是否要拆分为多个运行时对象；如果拆，按什么维度拆。
- `可破坏道具` 是否完全不需要 `CharacterContext`，还是需要极轻量桥接。
- `NPC` 的可选 HP 模型如何避免污染通用接口。
- 受击响应协调由谁负责最合适：`CharacterContext`、独立协调器，还是状态机层。
- 统一角色系统与 Combat / Respawn / Animation 的通信方式应如何组织。

## Deliverable Format

- 文档需包含：架构概览、模块拆分、职责表、实体接入矩阵、状态流/时序图、风险等级、交给 `Developer` 的约束。
- 文档应区分：已确认产品决策、架构推荐方案、仍需用户确认事项。

## Decisions Made

- 当前会话不直接写实现代码。
- `CharacterContext` 的职责边界已在 Feature Spec 收敛，但尚未决定是否拆分。
- Player 能量首版来源已确认按“击杀 / 处决 / 弹反”定义。
- 玩家死亡后的具体重生规则不在本设计中重新定义。
- 本轮新增：保留 `CharacterContext` 作为对外 facade，但内部必须拆成 `CharacterComponentRefs`、`CharacterStateSignals`、`AnimationBridge`、`DamageResponseCoordinator` 等协作模块。
- 本轮新增：`CharacterStats` 保持数值层，不负责状态切换；受击后的行为结果由 `DamageResponseCoordinator` 统一仲裁。
- 本轮新增：`IDamageable` 不再默认等同于 `CharacterStats`，可破坏道具与受伤 NPC 可使用轻量 receiver 接入。
- 本轮新增：P0-A 只要求 Player / Enemy / 可破坏道具最小闭环，不提前把完整 Buff、能量循环、Boss 多阶段受击塞进首阶段。

## Rejected Options

- 暂不接受让 `CharacterContext` 同时承担数值结算、重生判定、房间规则与所有行为编排的方案。
- 暂不接受强迫所有实体统一挂载完整角色能力的方案。

## Open Questions

- `DamageResponseCoordinator` 的最终命名和与未来 Combat 文档的接口细节，需 `Developer` 落地前再细化。
- `AnimationBridge` 是继续作为 `CharacterContext` 内部子对象，还是单独 MonoBehaviour 组件，需结合现有 Animator 接线方式决定。
- Enemy / Boss / NPC 模板是否分成独立 prefab authoring 规范，需后续设计/开发联合细化，但不阻塞当前架构方向。

## Next Update To Handoff

- 已输出架构设计文档 `Docs/ModuleDesign/CharacterFeature.md`；下一步更新 handoff 并将责任方交给 `Developer`。

## Suggested Next Chat Starter

```text
你现在以 @Architect 身份继续推进 `character-feature`。
请先阅读：
- `Docs/FeatureSpecs/CharacterFeature.md`
- `Docs/Workflow/Handoffs/character-feature.md`
- `docs/ModuleDesign/Locomotion.md`
- `Docs/Workflow/Sessions/character-feature/architect.md`

本次任务目标：
- 产出一版不写代码的统一角色系统技术方案。
- 重点解决 `CharacterStats` / `CharacterContext` 职责边界、受击响应链路、实体接入矩阵、模块边界与 P0-A 落地顺序。

本次输出必须包含：
- 模块拆分与职责表
- 关键数据结构 / API 草案
- 状态流或时序图
- Player / Enemy / Boss / NPC / 可破坏道具的接入矩阵
- 技术风险等级（low / medium / high）
- 交给 Developer 的实现约束

需要保留的边界：
- 先不写代码
- 不把 Respawn 规则重新塞回 CharacterFeature
- 必须遵守项目现有 HFSM、Kinematic Rigidbody2D、FixedUpdate + MovePosition 约束
```
