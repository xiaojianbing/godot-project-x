# Module Design: Character Attributes

> 依据 `docs/FeatureSpecs/CharacterAttributes.md`、`docs/FeatureSpecs/CharacterFeature.md` 与 `docs/FeatureSpecs/CorePriority.md`。

## 1. 文档目标

本设计文档聚焦统一角色属性系统的架构边界与运行时协作方式。

目标是为后续成长、装备、遗物、Buff、Debuff、敌人词缀、Boss 阶段与 UI 建立一个稳定的数据底盘，同时把基础属性从 `CharacterCombatProfile` 中拆出。

## 2. 设计目标

- 为 `Player`、`Enemy`、`Boss`、`NPC` 提供统一的基础属性接入模型。
- 把基础属性与战斗参数、移动参数明确解耦。
- 允许多个来源稳定叠加并输出唯一可信的最终属性值。
- 让 `CharacterStats` 只负责当前资源值，而不再承担基础模板定义职责。
- 让后续成长、装备、Buff 系统能在不破坏角色手感的前提下稳定接入。

## 3. 非目标

- 不定义具体装备系统、遗物池或全部 Buff 内容。
- 不在本阶段设计完整存档成长结构。
- 不定义完整 UI 面板结构和数值动画。
- 不强行让所有可破坏物都完整接入角色属性模块。

## 4. 核心原则

### 4.1 属性真相必须唯一

- 其他系统只能读取统一的最终属性值，不应缓存自己的长期副本。
- `DamageReceiver`、`Locomotion`、战斗计算、UI 都应从同一属性查询入口取值。

### 4.2 基础模板与运行时资源分离

- `max_hp`、`attack_power`、`move_speed_scale` 是属性层。
- `starting_hp`、`starting_energy` 是初始化属性层配置。
- `current_hp`、`current_energy` 是资源层。
- 上限变化由属性层决定；当前值变化由资源层管理。

### 4.3 属性模块不抢行为层职责

- 属性模块负责回答“数值上现在是多少”。
- 行为层负责解释“因此该进入什么状态、播放什么动画、触发什么反馈”。

### 4.4 修改来源统一建模

- 永久成长、装备、遗物、Buff、Debuff、阶段规则都必须通过统一修正器模型进入。
- 禁止不同系统各自对 `max_hp`、`attack_power` 做私有硬改，导致难以调试。

## 5. 推荐分层结构

```text
Character Scene
-> CharacterContext
   -> CharacterStats
   -> CharacterAttributeSet
      -> CharacterAttributesProfile
      -> CharacterAttributeModifier[]
   -> CharacterCombatProfile
   -> CharacterMotionProfile
   -> CharacterSignals
   -> DamageReceiver
```

说明：

- `CharacterAttributesProfile`：静态基础模板。
- `CharacterAttributeModifier`：单个属性修正来源。
- `CharacterAttributeSet`：运行时最终属性计算与查询中心。
- `CharacterStats`：当前 HP / Energy 等资源值，以及按属性策略完成初始化 / 重生恢复。
- `CharacterCombatProfile`：战斗动作参数。
- `CharacterMotionProfile`：移动参数。

## 6. 模块职责

### 6.1 `CharacterAttributesProfile`

作为 `Resource`，描述角色默认基础属性。

应负责：

- 提供所有基础属性默认值。
- 提供默认出生资源与重生恢复策略。
- 作为不同角色模板的复用入口。
- 为 `Player`、`Enemy`、`Boss`、`NPC` 提供统一基线。

不应负责：

- 保存运行时当前 HP / Energy。
- 保存 Buff 实例。
- 保存战斗 hitbox、弹反窗口、射击速度等战斗动作参数。

### 6.2 `CharacterAttributeModifier`

表示一个运行时修正来源。

建议包含：

- `attribute_id`
- `operation_type`
- `value`
- `source_id`
- `stack_group`
- `priority`
- `duration`（可选）
- `tags`

支持的基础操作：

- `flat_add`
- `percent_add`
- `multiplier`
- `override`

### 6.3 `CharacterAttributeSet`

运行时属性中心。

应负责：

- 持有基础模板引用。
- 持有当前修正器集合。
- 计算某属性的最终值。
- 提供只读查询接口。
- 发出属性变化信号。

不应负责：

- 决定玩家是否死亡。
- 直接扣减 `current_hp`。
- 直接操作行为状态机。

### 6.4 `CharacterStats`

在新结构中，`CharacterStats` 的职责应收缩为资源值管理。

应负责：

- `current_hp`
- `current_energy`
- 基于属性集读取 `max_hp` / `max_energy`
- 基于属性模板或策略完成 `starting_hp` / `starting_energy` 初始化
- 按重生策略恢复 HP / Energy
- 受伤、治疗、能量增减、死亡判定
- 上限变化时的当前值钳制

不应负责：

- 自己保存基础最大 HP / 攻击力模板
- 自己保存装备或 Buff 的最终属性逻辑

## 7. 属性分类建议

### 7.1 核心生存属性

- `max_hp`
- `max_energy`
- `starting_hp`
- `starting_energy`
- `defense_ratio`
- `damage_taken_scale`

### 7.1.1 初始化 / 重生策略属性

- `respawn_hp_mode`
- `respawn_hp_value`
- `respawn_energy_mode`
- `respawn_energy_value`

推荐语义：

- `*_mode = full | starting | ratio | fixed`
- `*_value` 在 `ratio` 与 `fixed` 模式下生效

### 7.2 战斗能力属性

- `attack_power`
- `poise`
- `stun_resistance`
- `knockback_resistance`
- `guard_strength`

### 7.3 运动倍率属性

- `move_speed_scale`
- `dash_scale`
- `jump_scale`
- `air_control_scale`

这些属性属于“角色属性层”，但不直接替代 `MotionProfile` 的设计参数。

含义是：

- `MotionProfile` 决定默认移动设计值
- `CharacterAttributes` 决定当前倍率修正

## 8. 推荐计算顺序

对单个属性建议按以下顺序结算：

```text
final_value = ((base_value + flat_add_sum) * (1.0 + percent_add_sum)) * multiplier_product
```

若存在 `override`：

- 默认优先级高于上述普通结算
- 仅在特殊状态或极端规则中使用

### 8.1 示例

- 基础 `max_hp = 100`
- 遗物 `+20`
- Debuff `-30`
- 区域词缀 `x0.5`

结果：

```text
((100 + 20 - 30) * 1.0) * 0.5 = 45
```

### 8.2 当前值钳制规则

当 `max_hp` 或 `max_energy` 变化时：

- `current_hp = clamp(current_hp, 0, final_max_hp)`
- `current_energy = clamp(current_energy, 0, final_max_energy)`

对于“当前值是否按比例缩放”这一问题：

- 首版建议默认只做钳制，不自动按比例重算
- 若设计需要，可后续引入独立策略字段

### 8.3 初始化与重生恢复规则

推荐把“第一次生成”和“后续重生”拆开处理：

- 初次生成：优先读取 `starting_hp` / `starting_energy`
- 后续重生：优先读取 `respawn_hp_mode` / `respawn_energy_mode`

推荐默认规则：

- 若 `starting_hp <= 0`，则视为 `max_hp`
- 若 `starting_energy` 未设置，则视为 `0`
- 若 `respawn_*_mode = full`，恢复到当前最大值
- 若 `respawn_*_mode = starting`，恢复到起始值
- 若 `respawn_*_mode = ratio`，恢复到 `max * value`
- 若 `respawn_*_mode = fixed`，恢复到 `value` 后再钳制到当前上限

## 9. 与现有模块边界

### 9.1 与 `CharacterCombatProfile`

`CharacterCombatProfile` 未来只应保留：

- 攻击 hitbox
- hitstun / knockback
- guard / parry 参数
- projectile 参数
- enemy 攻击节奏参数

已迁出且不应回流：

- `base_max_hp`
- `base_max_energy`
- `starting_energy`
- `base_attack_power`
- `base_defense_ratio`
- `base_poise`
- `base_stun_resistance`
- `base_knockback_resistance`

### 9.2 与 `CharacterMotionProfile`

- `CharacterMotionProfile` 保持默认运动参数入口。
- `CharacterAttributes` 提供运行时倍率修正。
- `Locomotion` 从两者共同读取最终运动结果。

### 9.3 与 `CharacterContext`

- `CharacterContext` 暴露 `attribute_set` 供外部统一访问。
- 不应自己维护一份属性真相。

### 9.4 与 `DamageReceiver`

- `DamageReceiver` 读取最终 `defense_ratio`、`damage_taken_scale` 等结果。
- 但不负责保存这些属性的来源。

## 10. 推荐运行时链路

```text
Equipment / Relic / Buff / PhaseRule / AreaRule
-> CharacterAttributeModifier
-> CharacterAttributeSet.recalculate_if_needed()
-> final attribute query
-> CharacterStats / DamageReceiver / Locomotion / UI
```

关键原则：

- 属性来源统一进入修正器层。
- 运行时其他系统只消费最终值。
- 保持依赖方向单向清晰。

## 11. 信号与调试建议

### 11.1 `CharacterAttributeSet` 推荐信号

- `attribute_changed(attribute_id, previous_value, current_value)`
- `attributes_recalculated()`
- `modifier_added(source_id, attribute_id)`
- `modifier_removed(source_id, attribute_id)`

### 11.2 调试输出建议

调试 HUD 至少应支持观察：

- `max_hp`
- `max_energy`
- `attack_power`
- `defense_ratio`
- 当前活跃修正器数量
- 最近一次属性变化来源

## 12. 数据结构草案

```gdscript
class_name CharacterAttributesProfile
extends Resource

@export var max_hp: float = 100.0
@export var max_energy: float = 0.0
@export var starting_hp: float = -1.0
@export var starting_energy: float = 0.0
@export var respawn_hp_mode: StringName = &"full"
@export var respawn_hp_value: float = 1.0
@export var respawn_energy_mode: StringName = &"starting"
@export var respawn_energy_value: float = 0.0
@export var attack_power: float = 10.0
@export var defense_ratio: float = 0.0
@export var poise: float = 0.0
@export var stun_resistance: float = 0.0
@export var knockback_resistance: float = 0.0
@export var move_speed_scale: float = 1.0
@export var dash_scale: float = 1.0
@export var air_control_scale: float = 1.0
```

```gdscript
class_name CharacterAttributeModifier
extends RefCounted

var attribute_id: StringName
var operation_type: StringName
var value: float
var source_id: StringName
var priority: int = 0
var duration: float = -1.0
```

```gdscript
class_name CharacterAttributeSet
extends RefCounted

var profile: CharacterAttributesProfile
var modifiers: Array[CharacterAttributeModifier] = []

func get_value(attribute_id: StringName) -> float:
	return 0.0
```

## 13. 文件组织建议

```text
resources/characters/character_attributes_profile.gd
resources/characters/player_attributes_profile.tres
resources/characters/enemy_attributes_profile.tres
scripts/core/character/data/character_attribute_modifier.gd
scripts/core/character/data/character_attribute_set.gd
```

## 14. 迁移建议

### 14.1 迁移顺序

1. 新增 `CharacterAttributesProfile` 与 `CharacterAttributeSet`
2. 让 `CharacterStats` 改为从 `attribute_set` 读取上限与基础攻击力
3. 迁出 `CharacterCombatProfile` 中的基础属性字段
4. 保持旧接口兼容一段过渡期
5. 再逐步接入 Buff、装备、遗物与阶段修正

### 14.2 最小兼容策略

- 首版迁移可允许 `CharacterStats` 同时接受旧 `combat_profile` 和新 `attributes_profile`
- 但文档层必须明确：旧路径只是过渡，不是长期结构

### 14.3 当前已落地的最小实现

- `CharacterAttributesProfile`、`CharacterAttributeSet` 与 `CharacterAttributeModifier` 骨架已落地。
- `Player`、`Enemy`、`CombatDummy` 已开始通过 `attributes_profile` 初始化 `CharacterStats`。
- `CharacterStats` 当前同时兼容旧 `combat_profile` 初始化调用形式与新 `attributes_profile` 初始化调用形式；旧调用形式内部会退化到默认属性模板。
- `CharacterCombatProfile` 中的基础属性字段已移除，基础属性资源已迁往独立 `player_attributes_profile` / `enemy_attributes_profile`。
- `starting_energy` 也已从 `CharacterCombatProfile` 迁入 `CharacterAttributesProfile`，初始资源值由属性模板统一提供。
- `starting_hp`、`respawn_hp_mode`、`respawn_energy_mode` 等初始化 / 重生策略字段已接入属性模板，`CharacterStats` 已开始统一消费这些策略完成初始化与重生恢复。
- `CharacterStats.add_buff()` 已能把属性 modifier 或 modifier 数组挂入 `attribute_set`，作为首批运行时修改入口。

## 15. 当前结论

- `CharacterAttributes` 值得单独成模块，因为它是后续成长与战斗表达的共同底座。
- 它必须服务于 `Player`、`Enemy`、`Boss`、`NPC` 的统一角色系统，而不是只服务玩家。
- 现有 `CharacterCombatProfile` 承载基础属性只是原型阶段折中，后续应迁出。
