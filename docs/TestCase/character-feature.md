# Character Feature Test Case

## Purpose

- 本文是 `Character Feature` 的测试执行文档。
- `FeatureSpecs` 定义产品目标，`ModuleDesign` 定义系统边界，本文定义这套基础角色系统如何验证。

## Inputs

- Requirement: `docs/FeatureSpecs/CharacterFeature.md`
- Requirement: `docs/FeatureSpecs/CorePriority.md`
- Design reference: `docs/ModuleDesign/CharacterFeature.md`
- Related design: `docs/ModuleDesign/Locomotion.md`

## Scope

- 验证 `CharacterStats`、`CharacterSignals`、`CharacterContext`、`DamageReceiver` 的职责边界。
- 验证 Player、Enemy、Boss、NPC、可破坏物五类实体的最小接入模型。
- 验证 HP、Energy、Buff、DamageResult、运行时状态信号的基本闭环。
- 验证基础角色系统是否足以支撑后续 `Locomotion` 与战斗系统接入。

## Out Of Scope

- 完整移动状态树的动态手感验证。
- 完整攻击连招、Boss 多阶段行为、地图与存档系统。
- 具体关卡内容、区域路线与世界解锁链路。

## Test Environment

- 使用 `Godot 4` 测试场景与最小角色原型。
- 至少准备以下测试实体：Player、Enemy Dummy、Boss Dummy、可受伤 NPC、不可受伤 NPC、可破坏物。
- UI 需至少能观察 HP、Energy、Buff 与死亡状态变化。

## Case Summary

| ID | Test Item | Status | Note |
| --- | --- | --- | --- |
| CF-01 | Stats HP Loop | Pending | 验证受伤、治疗、死亡 |
| CF-02 | Energy Loop | Pending | 验证能量增减与上限 |
| CF-03 | Buff Modifier Loop | Pending | 验证 Buff 增减与回滚 |
| CF-04 | DamageResult Structure | Pending | 验证结构化结果输出 |
| CF-05 | CharacterSignals Sync | Pending | 验证运行时状态同步 |
| CF-06 | CharacterContext Access Boundary | Pending | 验证统一访问入口 |
| CF-07 | DamageReceiver Flow | Pending | 验证受击入口链路 |
| CF-08 | Entity Integration Matrix | Pending | 验证不同实体接入差异 |
| CF-09 | Non-Character Destructible | Pending | 验证轻量接入模型 |
| CF-10 | Locomotion Dependency Boundary | Pending | 验证与移动系统边界 |
| CF-11 | EnemyCharacter Physics Loop | Pending | 验证敌人角色重力与落地 |

## Test Cases

### CF-01 Stats HP Loop

- Goal: 验证 `CharacterStats` 的 HP 基础闭环。
- Steps:
- 对 Player 或 Enemy 连续施加伤害。
- 施加治疗。
- 将 HP 压到 0。
- Expected:
- HP 正确减少与恢复。
- 到 0 时进入死亡结果。
- HP 变化信号按顺序发出。

### CF-02 Energy Loop

- Goal: 验证能量增减、上限与只读查询。
- Steps:
- 连续添加能量。
- 消耗能量。
- 尝试超过上限和低于 0。
- Expected:
- Energy 在合法范围内钳制。
- `energy_changed` 信号稳定发出。

### CF-03 Buff Modifier Loop

- Goal: 验证 Buff 和 Modifier 生效与回滚。
- Steps:
- 给角色添加提高攻击或移动倍率的 Buff。
- 观察属性变化。
- 等待持续时间结束或主动移除。
- Expected:
- 属性变化即时生效。
- Buff 结束后属性恢复。
- 不出现重复叠加残留。

### CF-04 DamageResult Structure

- Goal: 验证 `DamageResult` 是否足够支撑行为层决策。
- Steps:
- 在普通受击、无敌、霸体、致死四种条件下施加伤害。
- 记录 `DamageResult`。
- Expected:
- 能区分是否生效、伤害量、是否致死、是否被无敌拦截、是否触发霸体分支。

### CF-05 CharacterSignals Sync

- Goal: 验证 `CharacterSignals` 作为运行时状态真相快照。
- Steps:
- 驱动角色进入 grounded、invincible、dead、不同 action tag 状态。
- Expected:
- `CharacterSignals` 与实际行为同步，不出现多系统状态冲突。

### CF-06 CharacterContext Access Boundary

- Goal: 验证 `CharacterContext` 是统一访问入口而不是规则黑洞。
- Steps:
- 检查移动和受击模块对角色数据的访问路径。
- Expected:
- 通过 `CharacterContext` 获取 `stats`、`signals`、`motion_profile`、`animation_bridge`、`body`。
- 不在外部模块重复维护角色状态真相。

### CF-07 DamageReceiver Flow

- Goal: 验证统一受击入口链路。
- Steps:
- 用战斗命中、陷阱命中、环境伤害三种来源触发 `DamageReceiver`。
- Expected:
- 统一进入 `CharacterStats.apply_damage()`。
- 统一产出 `DamageResult`。
- 行为层能基于结果分流受击、霸体、死亡。

### CF-08 Entity Integration Matrix

- Goal: 验证五类实体的最小接入模型。
- Steps:
- 分别检查 Player、Enemy、Boss、可受伤 NPC、不可受伤 NPC、可破坏物的挂载和运行结果。
- Expected:
- 每类实体都只接入自身所需的最低模块组合。
- 不需要完整角色系统的对象不会被强行绑入完整上下文。

### CF-09 Non-Character Destructible

- Goal: 验证可破坏物可通过轻量模型工作。
- Steps:
- 对可破坏物施加伤害直到销毁。
- Expected:
- 可破坏物不需要完整 `CharacterContext`。
- 仍能通过轻量 HP-only + receiver 闭环工作。

### CF-10 Locomotion Dependency Boundary

- Goal: 验证角色基础层与 `Locomotion` 的依赖边界。
- Steps:
- 检查移动模块是否只读取 `move_speed_scale`、`dash_scale`、`air_control_scale` 等倍率。
- 检查移动模块是否通过 `CharacterContext` 访问角色基础层。
- Expected:
- `CharacterFeature` 负责角色基础真相。
- `Locomotion` 不重复定义或持有基础属性逻辑。

### CF-11 EnemyCharacter Physics Loop

- Goal: 验证真正的敌人角色接入统一角色物理层。
- Steps:
- 在测试房生成 `EnemyCharacter`，观察其出生后受重力下落并稳定落地。
- 让其在受击与重生后再次恢复地面状态。
- Expected:
- 敌人通过 `CharacterBody2D` 和 `_physics_process()` 参与物理更新。
- 重力、地面、受击击退与重生不会绕开统一角色基础设施。

## Exit Criteria

- `CharacterStats`、`CharacterSignals`、`CharacterContext`、`DamageReceiver` 的职责边界清晰可验证。
- 五类实体的最小接入矩阵具备可落地性。
- 结构化结果与信号足以支撑后续移动、战斗、UI、受击系统。
- 基础角色系统不会破坏 `丝滑操控` 与 `华丽战斗` 两大卖点。
