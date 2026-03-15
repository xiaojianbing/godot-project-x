# Feature Spec: Character Attributes

## Feature 简述

`CharacterAttributes` 是统一角色系统中的底层属性模块，负责为 `Player`、`Enemy`、`Boss`、`NPC` 以及其他需要角色属性语义的实体提供一致的基础属性定义、运行时修正与最终值查询。

它解决的核心问题不是“角色怎么攻击”或“角色怎么移动”，而是先明确：

- 角色基础最大 HP / Energy / Attack / Defense 从哪里来
- 角色初始出生时带多少 HP / Energy，重生时恢复到多少
- 装备、遗物、Buff、Debuff、区域规则如何稳定修改这些属性
- 不同系统如何读取同一份最终属性真相，而不是各自缓存一份临时结果

本模块的目标是把“角色是谁、当前被改成什么样”从 `CombatProfile`、`MotionProfile` 与行为层逻辑中剥离出来，形成独立、可复用、可扩展的基础设施。

## 玩家体验目标

- 玩家拿到永久升级、遗物或特殊能力后，能稳定感知到最大 HP、能量上限、攻击力等核心属性的变化。
- 玩家受到临时 Buff / Debuff 影响时，属性变化结果明确、可预期，并能在效果结束后稳定回滚。
- 玩家面对“最大 HP 减半、攻击翻倍”这类高风险高收益效果时，系统结果应清楚、稳定，不出现显示和实际结算不一致。
- 不同敌人、精英词缀、Boss 阶段都能使用同一套属性系统表达差异，而不是各写一套特例。
- 属性系统不能破坏 `丝滑操控` 与 `华丽战斗`：任何属性变化都必须结果清晰、调试可见、不会让角色手感变得不可预测。

## 卖点对齐

- `丝滑操控`：移动与受击相关属性必须通过统一可解释的方式生效，不能让角色突然出现无法理解的速度漂移或手感异常。
- `华丽战斗`：攻击、减伤、硬直抗性、霸体阈值等属性需要支持精英词缀、Buff、处决奖励和风险型道具等后续战斗表达。

## 优先级

`P0/P1` 交界处的底层基础设施预设计模块。

它暂不要求在当前里程碑完成所有代码迁移，但必须先完成设计收口，因为后续成长、装备、Buff、敌人词缀、Boss 阶段与 UI 都会依赖它。

## 范围定义

### In Scope

- 定义统一 `CharacterAttributes` 模块的产品目标与职责边界。
- 定义基础属性、派生属性、运行时修正和最终值查询的概念模型。
- 定义 `Player`、`Enemy`、`Boss`、`NPC` 的属性接入方式。
- 定义属性模板、修正器、运行时属性集之间的职责分层。
- 定义永久成长、装备、遗物、Buff、Debuff、区域修正、阶段修正等来源如何进入属性系统。
- 定义与 `CharacterStats`、`CharacterContext`、`CombatProfile`、`MotionProfile` 的边界。

### Out of Scope

- 不定义具体装备池、Buff 池和全部数值内容。
- 不定义具体 UI 样式、面板布局与数值动画表现。
- 不直接定义战斗招式帧数据、移动参数、AI 行为树。
- 不在本阶段完成所有旧代码的即时迁移实现。

## 核心问题

当前工程中，`base_max_hp`、`base_max_energy`、`base_attack_power` 等基础角色属性被放在 `CharacterCombatProfile` 中。

这会带来几个长期问题：

- `CombatProfile` 同时承担“战斗行为参数”和“角色基础属性”，职责混杂。
- 永久成长与临时效果难以分层，容易把 `combat_profile` 变成大杂烩。
- `CharacterStats` 会被迫从战斗配置里读取基础属性，导致数据来源表达不准确。
- `Player`、`Enemy`、`NPC` 后续若共享统一成长 / 词缀 / 阶段机制，会越来越难维护。

因此本模块要明确：

- `CharacterAttributesProfile` 负责“基础属性模板”
- `CharacterCombatProfile` 负责“战斗动作与判定参数”
- `CharacterMotionProfile` 负责“移动相关静态参数”
- `CharacterStats` 负责“当前资源值”
- `CharacterAttributeSet` 负责“最终属性值计算与查询”

## 核心概念

### 1. 基础属性模板

基础属性模板描述角色默认拥有哪些核心属性，例如：

- `max_hp`
- `max_energy`
- `starting_hp`
- `starting_energy`
- `respawn_hp_mode`
- `respawn_hp_value`
- `respawn_energy_mode`
- `respawn_energy_value`
- `attack_power`
- `defense_ratio`
- `poise`
- `stun_resistance`
- `knockback_resistance`
- `move_speed_scale`
- `dash_scale`
- `air_control_scale`

### 2. 属性修正来源

属性修正必须支持多种来源统一进入系统：

- 永久成长（如生命容器、能量容器）
- 装备 / 遗物
- 临时 Buff / Debuff
- 地图区域规则
- Boss 阶段或精英词缀
- 特殊代价效果（如最大 HP 减半、攻击翻倍）

### 3. 最终属性值

最终属性值是运行时唯一可信的属性查询结果。

其他系统不应各自保存一份临时属性真相，而应统一读取属性模块的最终结果。

### 4. 资源值与属性值分离

必须区分：

- `max_hp` 是属性值
- `starting_hp` 是初始化属性值
- `current_hp` 是运行时资源值
- `max_energy` 是属性值
- `starting_energy` 是初始化属性值
- `current_energy` 是运行时资源值

也就是说：

- `CharacterAttributes` 决定上限、初始资源值与倍率
- `CharacterStats` 决定当前剩余多少

### 5. 初始值与重生策略

除了基础上限外，属性系统还应统一描述：

- 角色第一次生成时的 `starting_hp` / `starting_energy`
- 角色重生或房间重置时的 HP / Energy 恢复策略

推荐把这部分视为“初始化属性策略”，与运行时 `current_hp/current_energy` 分层：

- `starting_hp` / `starting_energy`：描述默认出生资源
- `respawn_hp_mode` / `respawn_energy_mode`：描述重生时如何恢复
- `current_hp` / `current_energy`：描述当前实时资源

推荐支持的重生模式至少包括：

- `full`：恢复到当前最大值
- `starting`：恢复到属性模板的起始值
- `ratio`：恢复到最大值的一定比例
- `fixed`：恢复到固定数值，再钳制到当前上限

这样可统一覆盖：

- Player 存档点复活回满
- Enemy 重生时回到设计规定值
- Boss 阶段切换时保留部分资源或重置到指定比例

## 支持的实体类型

| 实体 | 属性模板 | 运行时修正 | 资源值 | 备注 |
| --- | --- | --- | --- | --- |
| Player | 必需 | 必需 | 必需 | 成长、装备、遗物、Buff 最完整 |
| Enemy | 必需 | 必需 | 必需 | 支持区域倍率、词缀、精英化 |
| Boss | 必需 | 必需 | 必需 | 支持阶段切换与特殊抗性 |
| NPC | 可选 | 可选 | 可选 | 战斗 NPC 可完整接入，演出 NPC 可轻量接入 |
| 可破坏物 | 轻量可选 | 轻量可选 | 轻量可选 | 仅当需要统一属性语义时接入 |

## 设计输入给架构层

- `CharacterAttributesProfile`、`CharacterAttributeSet`、`CharacterStats` 三者如何拆分最稳定。
- 修正器如何支持加算、乘算、覆盖、条件生效与持续时间。
- 运行时哪些系统可以写属性，哪些系统只能读属性。
- 初始资源值与重生资源值应由谁定义、由谁消费。
- 上限变化时，当前 HP / Energy 如何安全重算与钳制。
- 敌人词缀、Boss 阶段和区域效果如何复用同一套修正器模型。

## 玩家视角验收标准

- 拿到增加最大 HP 的道具后，HP 上限立刻稳定增长，显示与结算一致。
- 获得临时攻击翻倍效果后，输出结果立刻改变；效果结束后稳定恢复。
- 遭遇“最大 HP 减半”类负面效果时，当前 HP 处理规则清晰，不出现 UI 和实际值错位。
- 敌人精英化或区域强化后，能通过统一属性结果观察到差异，而不是只靠隐藏脚本硬改。
- 多个属性来源叠加时，最终结果可预测、可调试、可解释。

## 阶段完成定义

### CharacterAttributes 设计完成定义

- 已形成独立的 `FeatureSpecs`、`ModuleDesign` 与 `TestCase` 文档。
- 已明确基础属性、运行时修正、最终值查询、资源值之间的边界。
- 已明确 `CharacterCombatProfile` 不再长期承载基础角色属性。
- 已为后续 Player、Enemy、Boss、NPC 共用属性系统提供统一方向。

## Review

### 已确认方向

- `CharacterAttributes` 是底层基础设施，不应继续混在 `CharacterCombatProfile` 中。
- 这套设计不只服务 `Player`，必须服务 `Enemy`、`Boss`、`NPC` 等统一角色体系。
- 永久成长、装备、遗物、Buff、Debuff、阶段修正都应通过统一属性系统进入，而不是直接散落到各模块里。
- 当前最小代码骨架与 `Player / Enemy / CombatDummy` 的首轮接线已落地；`CharacterCombatProfile` 中的旧 `base_*` 字段已移除，基础属性改由独立 `attributes_profile` 提供。
- `starting_energy` 也已迁入 `CharacterAttributesProfile`，不再留在 `CharacterCombatProfile` 中。
- `starting_hp`、`starting_energy` 与基础重生策略字段已进入 `CharacterAttributesProfile`，`Player / Enemy / CombatDummy` 的重置路径已开始统一走 `CharacterStats` 的策略接口。
- `CharacterStats.add_buff()` 已可接收属性 modifier 或 modifier 数组，并把它们挂入 `attribute_set`，作为首批真实运行时接入路径。

### 待后续实现细化

- 属性枚举是否采用 `StringName`、枚举常量还是资源驱动。
- 乘算 / 加算 / 覆盖的优先级与排序规则。
- 条件修正器是否在首版进入实现，还是后续扩展。
