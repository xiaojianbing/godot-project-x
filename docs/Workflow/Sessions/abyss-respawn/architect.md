# Abyss Respawn Architect Session

## Session Meta

- Role: architect
- Feature: Abyss Respawn
- Slug: abyss-respawn
- Date: 2026-03-12

## Current Objective

- 基于已审阅的 Feature Spec，输出一版可落地的架构设计方案，明确多来源重生系统的判定顺序、锚点分类、状态恢复矩阵与失效回退策略。

## Context Read

- Handoff: `Docs/Workflow/Handoffs/abyss-respawn.md`
- Feature Spec: `Docs/FeatureSpecs/AbyssRespawn.md`
- Module Design: `docs/ModuleDesign/Locomotion.md`
- Test Cases:
- Code / Logs: 按仓库规则先检查 `D:/projects/ProjectXII/Logger/` 最新日志，再阅读 player locomotion、hazard、checkpoint、room、boss 相关脚本

## Architect Mission

- 将 `AbyssRespawn` 从产品规则转化为可实现的系统设计，但本阶段**不写代码**。
- 设计范围必须覆盖五类重生来源：`初始进入`、`特殊陷阱失败`、`Boss 失败`、`加载游戏`、`普通战死`。
- 重点定义 `特殊陷阱失败`、Boss 失败和存档点恢复之间的衔接边界。
- 设计必须遵守项目现有 HFSM、`ActionPriority`、`Rigidbody2D (Kinematic)`、`FixedUpdate` + `MovePosition`、New Input System 等约束。

## Required Outputs

- 一份 Module Design 增补或新设计文档。
- 明确的重生来源优先级表。
- 明确的重生锚点分类与失效回退规则。
- 明确的重生状态流：触发、锁输入、反馈、回位、状态恢复、重新获得控制。
- 面向 `Developer` 的实现约束与禁止事项。
- 技术风险评估，并标记 `low` / `medium` / `high`。

## Must Solve

### 1. 重生来源优先级

- 当同一帧或相邻帧内同时出现 `特殊陷阱失败`、HP 归零、Boss 失败判定时，系统应如何决策唯一结果。
- 需要给出统一的 `RespawnSource` 判定顺序，避免多套规则竞争。

### 2. 重生锚点模型

- 需要定义至少三类锚点：`最后安全落脚点`、`Boss 战前置点`、`存档点`。
- 需要明确各类锚点的职责、适用场景、优先级和失效后的回退顺序。
- 需要回答锚点记录是世界坐标、引用对象、还是混合模型。

### 3. 特殊陷阱体系

- 需要设计 `普通陷阱` 与 `特殊陷阱` 的系统分层方式。
- 需要说明 `深渊` 如何默认接入 `特殊陷阱`。
- 需要考虑未来其他 `特殊陷阱`（如秒杀尖刺坑、酸液坑）的可扩展接入方式。

### 4. 状态恢复矩阵

- 需要明确不同 `RespawnSource` 下，角色应恢复什么、不恢复什么。
- 至少覆盖：位置、朝向、速度、输入缓冲、当前状态、跳跃/冲刺资源、无敌帧、相机控制权。
- 需要明确 `特殊陷阱失败` 与 Boss 失败是否共享同一套恢复模板。

### 5. HFSM / ActionPriority 衔接

- 需要说明重生触发时如何安全打断当前状态。
- 需要说明深渊/特殊陷阱失败是否作为高优先级中断源。
- 需要说明与受击、冲刺、空中状态、水域状态的衔接方式。

### 6. 空间安全与失效回退

- 需要解决移动平台、塌陷平台、单向平台、危险边缘、动态机关附近的锚点有效性。
- 需要说明当首选锚点失效时如何回退到次级锚点。
- 需要保证回位后不会卡墙、悬空或立刻再次掉入危险。

## Constraints

- 本阶段只做设计，不写实现代码。
- 不得绕过现有架构约束去提出与 HFSM 冲突的方案。
- 不得把所有情况粗暴合并为“统一死亡流程”，因为 Feature Spec 已明确不同来源有不同产品定位。
- 不得直接编辑 `.prefab`、`.unity`、`.asset` 等 Unity 序列化资源。
- 若需要日志依据，必须先检查 `Logger/` 最新日志。

## Recommended Design Direction

- 采用统一的 `RespawnSource` + `RespawnAnchor` 心智模型。
- `特殊陷阱失败` 优先服务快速重试，应以“最近有效安全点”为主。
- Boss 失败应独立于 `最后安全落脚点`，优先使用 Boss 战前置点，否则回最近存档点。
- `最后安全落脚点` 建议采用“稳定落地后更新”的方向，而不是每帧记录玩家位置。
- 对动态平台和危险边缘建议设计显式失效判定与回退链，而不是盲目复用静态地面逻辑。

## Questions To Answer

- `特殊陷阱失败` 的扣血已确认按危险类型配置，配置粒度和默认值应如何设计。
- Boss 战前置点应作为独立锚点类型，关键 Boss 的启用条件如何定义。
- `普通战死` 与 Boss 失败是否共用存档点通道，但拥有不同触发来源。
- 未解锁水域惩罚是否直接复用 `特殊陷阱失败` 管线。
- 是否需要统一的 Respawn Manager，还是由现有 Level / Room / Character 模块协作完成。

## Deliverable Format

- 文档需包含：架构概览、模块拆分、状态流、锚点策略、优先级表、恢复矩阵、风险等级、交给 `Developer` 的约束。
- 文档应明确哪些是已定决策，哪些是推荐方案，哪些仍需用户确认。
- 若 `@Architect` 与 `@Developer` 预期可能分歧，请在设计文档中记录双方关注点。

## Decisions Made

- 当前会话不直接写实现代码。
- 已确认五类重生来源都要纳入同一套系统设计视野。
- 已确认 `深渊坠落` 属于 `特殊陷阱失败`。
- 已确认仅 `特殊陷阱失败重生` 扣血，其他重生不做额外惩罚。
- 本轮新增：采用统一的 `RespawnRequest` + `RespawnAnchor` 架构，而不是让各类失败源直接传送角色。
- 本轮新增：`SpecialTrapFailure`、`BossFailure`、`NormalDeath` 共用调度框架，但不共用锚点语义。
- 本轮新增：`BossFailure` 明确禁止回落到 `LastSafeGround`，只走 `BossEntry -> Checkpoint -> SceneStart`。
- 本轮新增：`LastSafeGround` 采用“稳定落地后记录 + 使用前再校验”的方案，不采用每帧坐标快照。

## Rejected Options

- 暂不采用“每帧记录玩家坐标作为重生点”的方案，因为容易误记空中、边缘或危险区域。
- 暂不把所有重生都压扁成单一死亡流程，因为这会破坏产品规则边界。

## Open Questions

- `RespawnRecoveryProfile` 应放在角色层、关卡层还是存档层管理，`Developer` 需要结合现有代码进一步细化。
- 未来房间系统落地后，`Checkpoint` 与房间默认入口的绑定方式需要在实现前补一版接口约定。
- 若后续加入资源型死亡惩罚，需明确它属于 `NormalDeath/BossFailure` 的外层规则，而不是写进核心 respawn 调度。

## Next Update To Handoff

- 已输出架构设计文档 `Docs/ModuleDesign/AbyssRespawn.md`；下一步更新 handoff 并把责任方切到 `Developer`。

## Suggested Next Chat Starter

```text
你现在以 @Architect 身份继续推进 `abyss-respawn`。
请先阅读 `Docs/Workflow/Handoffs/abyss-respawn.md`、`Docs/FeatureSpecs/AbyssRespawn.md` 和 `docs/ModuleDesign/Locomotion.md`。
按仓库规则，先检查 `D:/projects/ProjectXII/Logger/` 最新日志，再阅读相关角色移动、陷阱、房间、Boss、存档点代码。

本次任务目标：
- 产出一版不写代码的技术方案，覆盖五类重生来源：初始进入、特殊陷阱失败、Boss 失败、加载游戏、普通战死。
- 重点解决：RespawnSource 优先级、RespawnAnchor 分类、特殊陷阱接入、HFSM/ActionPriority 打断、状态恢复矩阵、动态锚点失效回退。

本次输出必须包含：
- 模块拆分
- 关键数据结构 / API 草案
- 状态流或时序图
- 锚点优先级与回退表
- 不同重生来源的恢复矩阵
- 技术风险等级（low / medium / high）
- 交给 Developer 的实现约束

需要保留的边界：
- 先不写代码
- 不把所有重生合并成单一死亡流程
- 必须遵守项目现有 HFSM、Kinematic Rigidbody2D、FixedUpdate + MovePosition 约束
```
