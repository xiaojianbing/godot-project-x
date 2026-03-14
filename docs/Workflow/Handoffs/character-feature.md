# Character Feature Handoff

## Feature

- Name: Character Feature
- Slug: character-feature
- Current Stage: `Architect`
- Next Owner: `Developer`

## Goal

- 这个功能要解决什么问题：需要建立一套统一的角色系统产品边界，让 Player、Enemy、Boss、NPC、可破坏道具在数值层与行为层上拥有一致但可分层的接入方式，避免后续实现中职责混乱、接口分裂或把 `CharacterContext` 做成上帝对象。
- 目标玩家体验：玩家攻击不同对象时，会得到一致且符合对象类型差异的反馈；玩家能稳定理解 HP、能量、Buff、霸体、受击响应之间的关系；角色系统的行为结果对玩家来说应公平、清晰、可预期。

## Scope

- In Scope: 统一角色系统的产品目标、实体覆盖边界、`CharacterStats` / `CharacterContext` 职责边界、能量来源规则、玩家视角验收标准、阶段完成定义、交给 `@Architect` 的设计输入。
- Out of Scope: 具体类拆分、代码级 API、状态树实现细节、完整战斗系统实现、重生规则实现、关卡/房间/存档点工具。
- Priority: `P0`

## Source Documents

- Feature Spec: `docs/FeatureSpecs/CharacterFeature.md`
- Module Design: `docs/ModuleDesign/CharacterFeature.md`
- Test Cases: `docs/TestCase/character-feature.md`
- Related Logs / References: `Hollow Knight`, `Devil May Cry 5`, `Prince of Persia: The Lost Crown`, `Nioh`

## Confirmed Decisions

- `CharacterStats` 是统一数值层，`CharacterContext` 是行为层运行时枢纽。
- `CharacterContext` 需要收敛职责边界，不应承担重生判定、房间规则或完整数值结算。
- `CharacterContext` 是否进一步拆分，属于 `@Architect` 设计任务，不在 Feature Spec 中预先写死。
- Player 能量首版来源按“击杀 / 处决 / 弹反”定义，不写成“普通命中即获得能量”。
- `NPC` 的 HP 支持为可选，不要求所有 NPC 默认纳入完整受伤/死亡体系。
- 玩家死亡后的具体重生结果不在本规格内写死，遵循独立 Respawn 规格。
- P0-A 目标是统一角色系统最小闭环，不要求在该阶段完成完整 Buff、能量循环和大招系统。

## Open Questions

- `DamageResponseCoordinator` 与未来 Combat 设计文档的接口细节仍需在实现前补一版约定。
- `AnimationBridge` 采用内部子对象还是独立组件实现，需 `Developer` 根据现有 Animator 接线方式做最终选择。
- Enemy / Boss / NPC 的模板化 authoring 规范仍需后续补充，但不影响当前基础架构落地。

## Risks

- Risk Level: `medium`
- Risk Notes: 已形成明确拆分方案，但实现风险仍集中在当前胖 `CharacterContext` 的收缩改造、`IDamageable` 从单实现改为多实现模型、以及 `DamageResponseCoordinator` 与未来 HFSM / `ActionPriority` 的衔接。

## Implementation Notes

- Relevant Files: `docs/FeatureSpecs/CharacterFeature.md`, `docs/ModuleDesign/CharacterFeature.md`, `docs/ModuleDesign/Locomotion.md`, `docs/TestCase/character-feature.md`
- Constraints: 必须遵守 HFSM、`ActionPriority`、`Rigidbody2D (Kinematic)`、`FixedUpdate` + `MovePosition`、Unity New Input System；当前阶段先做架构设计，不写实现代码。
- Known Deviations:

## Validation Notes

- Checks Completed: 已完成 Feature Spec 的 Producer 侧补强；已检查最新日志；已对当前运行时代码做结构盘点；已输出 `Docs/ModuleDesign/CharacterFeature.md`，覆盖模块拆分、受击链路、实体接入矩阵、阶段落地顺序与实现约束。
- Issues Found: 当前 `CharacterContext` 已承担游泳/蹲伏/Respawn 等多类职责；`CharacterStats` 仍存在反查行为层耦合；当前仅 Player 主干落地，受击硬直链未形成闭环。
- Remaining Concerns: `Combat` 设计文档尚未补齐，`DamageResponseCoordinator` 的精确接口要在实现前与战斗模块再对齐一次。

## Next Step

- Recommended Role: `Developer`
- Recommended Action: 以 `Docs/ModuleDesign/CharacterFeature.md` 为准，先收口 `CharacterStats` / `IDamageable` 边界，再把 `CharacterContext` 重构为 facade + 子模块协作结构，并完成 P0-A 的 Player / Enemy / 可破坏道具最小闭环模板。
