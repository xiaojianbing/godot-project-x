# Character Attributes Test Case

## Purpose

- 本文是 `Character Attributes` 的测试执行文档。
- `FeatureSpecs` 定义属性系统目标，`ModuleDesign` 定义架构边界，本文定义后续实现时应如何验收。

## Inputs

- Requirement: `docs/FeatureSpecs/CharacterAttributes.md`
- Requirement: `docs/FeatureSpecs/CharacterFeature.md`
- Requirement: `docs/FeatureSpecs/CorePriority.md`
- Design reference: `docs/ModuleDesign/CharacterAttributes.md`
- Related design: `docs/ModuleDesign/CharacterFeature.md`

## Scope

- 验证基础属性模板、运行时属性修正、最终值查询与当前资源值之间的边界。
- 验证 `Player`、`Enemy`、`Boss`、`NPC` 是否能共用同一套属性结构。
- 验证永久成长、临时 Buff / Debuff、阶段修正、区域修正的最小叠加闭环。
- 验证属性变化对 `CharacterStats`、`DamageReceiver`、`Locomotion` 的下游影响是否稳定。

## Out Of Scope

- 完整装备面板 UI。
- 全部 Buff 内容池与策划平衡细节。
- 完整存档成长链路。
- 具体战斗动作帧数据与移动参数调优。

## Test Environment

- 使用 `Godot 4` 测试场景与最小角色原型。
- 至少准备：Player、Enemy、Boss Dummy、战斗 NPC、区域修正规则触发器。
- 调试 UI 至少能观察 `max_hp`、`max_energy`、`attack_power`、`defense_ratio` 与活跃 modifier 数量。

## Case Summary

| ID | Test Item | Status | Note |
| --- | --- | --- | --- |
| CA-01 | Base Attribute Profile Load | Pending | 验证基础模板正确装载 |
| CA-02 | Runtime Modifier Apply | Pending | 验证单个 modifier 生效 |
| CA-03 | Multiple Modifier Stacking | Pending | 验证加算与乘算叠加 |
| CA-04 | Override Priority | Pending | 验证覆盖型修正优先级 |
| CA-05 | Max HP Clamp | Pending | 验证上限变化后的当前 HP 钳制 |
| CA-06 | Max Energy Clamp | Pending | 验证上限变化后的当前 Energy 钳制 |
| CA-07 | Player Growth Relic | Pending | 验证永久成长入口 |
| CA-08 | Temporary Buff Debuff | Pending | 验证临时效果与回滚 |
| CA-09 | Enemy Elite Modifier | Pending | 验证敌人精英词缀复用 |
| CA-10 | Boss Phase Modifier | Pending | 验证 Boss 阶段修正复用 |
| CA-11 | Locomotion Scale Read | Pending | 验证移动模块读取倍率边界 |
| CA-12 | Combat Damage Read | Pending | 验证战斗读取最终攻击/防御值 |
| CA-13 | Starting Resource Init | Covered | 初始资源字段与初始化入口已落地，待实机确认 |
| CA-14 | Respawn Resource Policy | Covered | 重生策略字段与重置入口已落地，待实机确认 |

## Test Cases

### CA-01 Base Attribute Profile Load

- Goal: 验证属性模板能为不同角色提供稳定基线。
- Steps:
- 为 Player、Enemy、Boss 分别加载不同 `CharacterAttributesProfile`。
- 读取 `max_hp`、`attack_power`、`defense_ratio`。
- Expected:
- 各角色能读取正确基础属性。
- 不再依赖 `CombatProfile` 充当基础属性模板。

### CA-02 Runtime Modifier Apply

- Goal: 验证单个修正器生效。
- Steps:
- 给角色添加一个 `attack_power + 20` 的运行时修正。
- Expected:
- 最终攻击力立即变化。
- 属性变化信号被稳定发出。

### CA-03 Multiple Modifier Stacking

- Goal: 验证多个修正器叠加顺序可预测。
- Steps:
- 同时添加 `+20 max_hp`、`-10 max_hp`、`x1.5 attack_power`。
- Expected:
- 最终值按既定规则计算。
- 不出现不同系统各算一套的问题。

### CA-04 Override Priority

- Goal: 验证 `override` 型修正优先级。
- Steps:
- 在已有加算 / 乘算修正基础上加入一个覆盖型修正。
- Expected:
- 系统按设计落入覆盖结果。
- 覆盖来源可被调试观察到。

### CA-05 Max HP Clamp

- Goal: 验证最大 HP 变化后的当前 HP 处理。
- Steps:
- 让角色当前 HP 高于变化后的新上限。
- 施加 `max_hp` 减半效果。
- Expected:
- 当前 HP 被稳定钳制到新上限内。
- 不出现显示和实际值不同步。

### CA-06 Max Energy Clamp

- Goal: 验证最大 Energy 变化后的当前值处理。
- Steps:
- 让角色当前 Energy 接近旧上限。
- 降低 `max_energy`。
- Expected:
- 当前 Energy 被稳定钳制到新上限内。

### CA-07 Player Growth Relic

- Goal: 验证玩家永久成长入口。
- Steps:
- 模拟拾取增加最大 HP 或最大 Energy 的遗物。
- Expected:
- 上限变化立即生效。
- 重进房间或后续系统仍能读取同一份最终值。

### CA-08 Temporary Buff Debuff

- Goal: 验证临时 Buff / Debuff 的增加与回滚。
- Steps:
- 给玩家施加 `attack_power x2` 与 `max_hp x0.5` 等效果。
- 等待持续时间结束。
- Expected:
- 效果期间最终值正确变化。
- 效果结束后完整回滚。

### CA-09 Enemy Elite Modifier

- Goal: 验证敌人精英化可复用统一属性系统。
- Steps:
- 给普通敌人施加“生命更高、攻击更强”的精英修正。
- Expected:
- 不需要单独硬编码敌人专用属性路径。

### CA-10 Boss Phase Modifier

- Goal: 验证 Boss 阶段修正规则。
- Steps:
- 在 Boss 进入新阶段时施加属性修正。
- Expected:
- 阶段变化通过统一 modifier 进入。
- 下游战斗结算直接读取最终值。

### CA-11 Locomotion Scale Read

- Goal: 验证移动模块只读取属性倍率，不接管属性真相。
- Steps:
- 改变 `move_speed_scale` 或 `dash_scale`。
- 观察移动模块读取路径。
- Expected:
- `Locomotion` 读取最终倍率。
- 但基础移动设计参数仍由 `MotionProfile` 提供。

### CA-12 Combat Damage Read

- Goal: 验证战斗模块读取最终攻击 / 防御值。
- Steps:
- 改变 `attack_power` 与 `defense_ratio`。
- 进行一次伤害结算。
- Expected:
- 最终伤害结果反映最新属性值。
- `DamageReceiver` 不需要自己保存一套属性来源。

### CA-13 Starting Resource Init

- Goal: 验证角色首次生成时会按属性模板初始化资源值。
- Steps:
- 配置 `starting_hp` 与 `starting_energy`。
- 生成 Player 或 Enemy。
- Expected:
- `current_hp/current_energy` 与属性模板初始值一致。
- 不再依赖角色脚本硬编码初始资源。

### CA-14 Respawn Resource Policy

- Goal: 验证角色重生时会按统一策略恢复资源。
- Steps:
- 分别测试 `full`、`starting`、`ratio`、`fixed` 四种模式。
- 让角色死亡并触发重生。
- Expected:
- 重生资源值按策略恢复。
- 恢复结果会被钳制到当前最大值范围内。

## Exit Criteria

- 基础属性模板、运行时修正、最终值查询与当前资源值边界清晰可验证。
- `Player`、`Enemy`、`Boss`、`NPC` 都能复用统一属性系统。
- 永久成长、临时 Buff、区域修正、阶段修正的最小闭环可被验证。
- 初始资源与重生资源恢复策略边界清晰可验证。
- `CharacterCombatProfile` 不再被视为长期承载基础角色属性的正确位置。
