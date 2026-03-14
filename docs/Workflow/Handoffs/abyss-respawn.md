# Abyss Respawn Handoff

## Feature

- Name: Abyss Respawn
- Slug: abyss-respawn
- Current Stage: `Architect`
- Next Owner: Developer

## Goal

- 这个功能要解决什么问题：需要先建立统一的重生规则口径，区分初始进入、特殊陷阱失败、Boss 失败、加载游戏、普通战死等不同来源，再明确 `abyss-respawn` 在整套 Respawn 体系中的定位。
- 目标玩家体验：玩家在不同失败来源下都能得到稳定、可预期、符合直觉的回位结果；其中深渊坠落作为 `特殊陷阱失败`，应提供类似 `Celeste` 的快速重试循环，保持平台挑战节奏。
## Scope

- In Scope: 重生分类定义、`普通陷阱` / `特殊陷阱` 的产品分层、深渊坠落作为 `特殊陷阱失败` 的定位、Boss 失败回位规则、玩家视角验收标准、`@Architect` 设计问题整理。
- Out of Scope: 重生锚点算法实现、存档系统重构、场景重载、相机/输入/无敌帧等实现细节、经济惩罚系统、Boss 房编辑器工具。
- Priority: `P0`

## Source Documents

- Feature Spec: `Docs/FeatureSpecs/AbyssRespawn.md`
- Module Design: `Docs/ModuleDesign/AbyssRespawn.md`
- Test Cases:
- Related Logs / References: `Celeste` quick retry loop, `Hollow Knight` hazard recovery expectations

## Confirmed Decisions

- 使用四会话协作：`Producer`、`Architect`、`Developer`、`Tester` 各自维护独立聊天上下文。
- 跨角色共识以本 handoff 为准，角色内部连续讨论写入 `Docs/Workflow/Sessions/abyss-respawn/`。
- 当前阶段先进入 `Producer`，先产出并审阅 Feature Spec，再进入架构设计。
- 重生需要作为一套更完整的系统口径来考虑，而不是只讨论单一深渊场景。
- 重生至少分为五类：初始进入、特殊陷阱失败、Boss 失败、加载游戏、普通战死。
- `深渊坠落` 被抽象为 `特殊陷阱`。
- `普通陷阱` 只扣血；`特殊陷阱` 扣血并触发重生。
- 仅 `特殊陷阱失败重生` 扣血，其他重生不做额外惩罚。
- Boss 失败默认优先回 Boss 战触发点前，否则回最近存档点。
- `特殊陷阱` 扣血按陷阱类型配置。
- Boss 战前置重生点仅对关键 Boss 开放。
- 首版只要求 `深渊` 接入 `特殊陷阱`，其他特殊陷阱先保留分类定义与扩展口。

## Open Questions

- `RespawnRecoveryProfile` 应由角色层还是更高层系统持有，需 `Developer` 结合现有运行时代码细化。
- 未来房间系统接入后，`Checkpoint` 与房间默认入口的映射方式仍需补接口约定。
- 若后续新增资源惩罚或尸体回收机制，需要在 respawn 调度之外定义扩展边界。

## Risks

- Risk Level: `medium`
- Risk Notes: 已完成统一架构方案，但实现风险仍集中在 `CharacterRespawnController` 与现有轻量 FSM 的衔接、动态平台/危险边缘的锚点有效性校验、Boss 前置点与 `Checkpoint` 回退链，以及当前 `DeathZoneTrigger` 直接传送逻辑的收口。

## Implementation Notes

- Relevant Files: `docs/ModuleDesign/Locomotion.md`, player locomotion and hazard-related runtime scripts to be identified in design stage
- Constraints: 必须遵守 `Rigidbody2D (Kinematic)` + `FixedUpdate` + `MovePosition`；状态切换需遵循 `ActionPriority`；不得在实现前跳过设计文档；当前阶段只确认产品规则，不进入技术实现。
- Known Deviations:

## Validation Notes

- Checks Completed: 已建立四角色会话文档骨架；已完成首版 Feature Spec；已输出 `Docs/ModuleDesign/AbyssRespawn.md`，明确了 `RespawnSource` 优先级、`RespawnAnchor` 分类、恢复矩阵、HFSM 打断原则和回退链；尚未开始实现。
- Issues Found:
- Remaining Concerns: 尚未把设计映射到具体运行时代码接口；`Checkpoint` / Boss / 房间系统当前代码基础薄弱，`Developer` 需先补统一调度骨架再落具体来源。

## Next Step

- Recommended Role: `Developer`
- Recommended Action: 以 `Docs/ModuleDesign/AbyssRespawn.md` 为准，先搭建 `RespawnRequest` / `RespawnManager` / `RespawnAnchorService` 骨架，并把现有 `DeathZoneTrigger`、未解锁水域和 `CharacterStats.OnDeath` 接入统一调度。

