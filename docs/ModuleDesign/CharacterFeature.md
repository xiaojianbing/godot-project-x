# Module Design: Character Foundation

> 依据 `docs/FeatureSpecs/CharacterFeature.md`、`docs/FeatureSpecs/CorePriority.md` 与 `docs/Glossary.md`。

---

## 1. 文档目标

本设计文档只聚焦 `Character` 的**基础属性层**与其最小运行时协作边界，目的是先为后续移动、战斗、受击、重生、Buff、敌人接入打下稳定地基。

本阶段不展开完整 locomotion 状态树，也不展开完整连招实现；但设计必须保证后续的 `丝滑操控` 与 `华丽战斗` 能建立在统一、清晰、可扩展的角色基础设施上。

## 2. 设计目标

- 为 Player、Enemy、Boss、可破坏物提供统一的基础属性接入模型。
- 保证数值层与行为层边界清楚，避免后续把角色系统做成难以维护的上帝对象。
- 让“受击后的数值变化”和“受击后的行为反应”可以解耦，但链路仍然清晰。
- 保证移动和战斗模块未来可以直接依赖统一的 HP、Energy、Buff、状态查询接口。
- 使用 `Godot 4` 语境设计，默认围绕 `CharacterBody2D`、`InputMap`、场景组合和信号进行实现。

## 3. 非目标

- 不定义具体跳跃、冲刺、墙跳、滑铲等 locomotion 参数。
- 不定义具体轻重攻击帧数据、取消帧、HitStop 时长等战斗参数。
- 不定义完整的 Buff 池、装备系统或地图系统。
- 不重写 Respawn 文档中关于死亡后去向的规则。

## 4. 基础原则

### 4.1 数值层服务手感，而不是破坏手感

- 角色属性系统不能让操作响应变得混乱、迟滞或不可预测。
- 任何影响移动、输入、硬直、霸体的属性或状态都必须能被清楚解释和调试。
- 当系统复杂度上升时，优先保持输入可读性与结果一致性。

### 4.2 行为层负责解释结果，不负责持有所有真相

- `CharacterStats` 保存数值真相。
- 行为层读取数值结果，再决定进入何种受击、死亡、霸体或连招状态。
- 不允许行为层和数值层各自偷偷存一套互相冲突的角色生存状态。

### 4.3 统一接口，按需接入

- Player 需要完整接入。
- Enemy / Boss 需要完整或接近完整接入。
- 可破坏物只接入最小必要层，不强绑完整角色上下文。
- NPC 是否具备 HP 和受击能力必须可选，而不是默认全部纳入。

## 5. 分层结构

```text
Character Scene
-> CharacterBody2D / Node2D Root
-> CharacterContext
   -> CharacterStats
   -> CharacterSignals
   -> CharacterCombatProfile
   -> CharacterMotionProfile
   -> CharacterAnimationBridge
   -> DamageReceiver
```

说明：

- `CharacterStats` 是基础数值核心。
- `CharacterSignals` 是运行时状态快照，不保存长期数值。
- `CharacterCombatProfile` 和 `CharacterMotionProfile` 是静态配置入口。
- `DamageReceiver` 是统一受击入口，负责把命中数据送入数值层，再把结果交给行为层。
- `CharacterContext` 只做运行时聚合与只读访问入口，不承担复杂公式结算。

### 5.1 `EnemyCharacter` 最小落地要求

- `EnemyCharacter` 默认以 `CharacterBody2D` 作为根节点，而不是 `Node2D`。
- 必须参与 `_physics_process()`，接受重力、地面判定与 `move_and_slide()` 结果。
- 必须复用 `CharacterStats`、`CharacterSignals`、`CharacterContext`、`DamageReceiver` 这条统一角色链路。
- 基础测试敌人允许只有轻量 AI，但不能绕开角色物理层直接用 `global_position` 假装移动。
- 受击击退应优先写入角色速度或受击速度，而不是长期直接改位置。
- 敌人的追击/开火/近战选择应优先挂到可替换的轻量 AI 协作者，而不是持续堆进 `EnemyCharacter` 本体。

## 6. 核心模块职责

### 6.1 `CharacterStats`

`CharacterStats` 是统一角色基础属性模块，负责保存与计算角色的核心数值状态。

应负责：

- 当前 HP、最大 HP、治疗、受伤、死亡判定。
- 当前 Energy、最大 Energy、增减接口。
- Buff / Modifier 的生效、移除、查询与重新结算。
- 返回结构化 `DamageResult`、`HealResult`、`EnergyChangeResult`。
- 发出稳定的属性变化信号，供 UI、动画、音效、战斗系统消费。

不应负责：

- 决定切入哪个 FSM 状态。
- 直接操作 `AnimationPlayer`、`AnimatedSprite2D`、`CharacterBody2D`。
- 计算玩家死亡后该回到哪个 checkpoint。
- 直接读取原始输入。

### 6.2 `CharacterSignals`

`CharacterSignals` 表示角色**当前运行时行为状态**，由移动、战斗、受击、死亡等系统持续更新。

建议包含：

- `is_grounded`
- `is_invincible`
- `has_super_armor`
- `can_accept_input`
- `is_dead`
- `facing_direction`
- `current_action_tag`

它的作用：

- 给状态机、战斗判定、UI 和表现层一个统一查询点。
- 避免多个系统各自维护一份互相冲突的布尔状态。

### 6.3 `CharacterContext`

`CharacterContext` 是运行时 facade，不是所有逻辑的归宿。

应负责：

- 汇总 `stats`、`signals`、配置资源、动画桥、移动体引用。
- 为状态机和系统提供统一访问入口。
- 提供少量受控操作，如翻面、输入开关、基础状态重置。

不应负责：

- 复杂伤害公式。
- Buff 结算细节。
- Respawn 规则。
- 房间、Boss、剧情等高层规则。

### 6.4 `DamageReceiver`

`DamageReceiver` 是统一受击入口，负责承接来自战斗、陷阱、机关的命中信息。

应负责：

- 接收 `HitData`。
- 调用 `CharacterStats.apply_damage()`。
- 根据 `DamageResult` 触发后续行为层入口。
- 向受击反馈、状态机、动画桥广播统一事件。

不应负责：

- 自己计算 HP。
- 自己维护角色长期属性。

## 7. 推荐属性模型

### 7.1 基础属性集合

首版建议把基础属性收敛为以下几类：

| 分类 | 属性 | 说明 |
| --- | --- | --- |
| 生存 | `max_hp` / `current_hp` | 决定承伤和死亡 |
| 能量 | `max_energy` / `current_energy` | 用于大招、技能资源或特殊系统 |
| 受击 | `defense_ratio` / `poise` / `stun_resistance` | 影响伤害、硬直、霸体阈值 |
| 攻击 | `attack_power` / `crit_bonus` | 提供战斗伤害的统一加成入口 |
| 机动 | `move_speed_scale` / `dash_scale` / `air_control_scale` | 影响移动表现，但不直接替代移动设计参数 |

### 7.2 为什么不把所有参数都塞进 `CharacterStats`

- 操控手感参数和角色成长参数虽然相关，但不是同一种职责。
- 例如跳高、加速度、冲刺距离等仍应主要属于 `MotionProfile` 或移动模块。
- `CharacterStats` 只保留那些会被 Buff、装备、成长或关卡效果稳定修改的“属性层数据”。

## 8. 配置资源设计

建议将静态配置与运行时状态分离。

### 8.1 `CharacterCombatProfile`

用于描述战斗相关默认属性：

- 基础 HP / Energy
- 攻击成长基线
- 受击抗性
- 霸体阈值
- 击退抗性

### 8.2 `CharacterMotionProfile`

用于描述移动能力相关的静态配置入口：

- 基础移动速度档位
- 冲刺资源消耗倍率
- 空中控制倍率
- 游泳或特殊地形移动倍率

> 这些 profile 建议以 `Resource` 形式存在，供 Player、Enemy、Boss、特殊 NPC 复用。

#### `CharacterMotionProfile` 的边界

- 它属于 `Character Foundation`，因为它定义的是角色可被移动模块读取的静态运动配置入口。
- 它不负责具体跳跃、冲刺、墙跳、抓边实现，这些内容应由 `Locomotion` 文档定义。
- 它的职责是为不同角色提供统一、可复用、可被倍率修正的基础运动参数来源。

## 9. 运行时数据与配置资源边界

| 内容 | 存放位置 | 原因 |
| --- | --- | --- |
| 当前 HP / Energy | `CharacterStats` | 运行时频繁变化 |
| Buff 列表 | `CharacterStats` | 运行时结算核心 |
| 基础最大 HP | `CharacterCombatProfile` | 静态配置，可复用 |
| 基础受击抗性 | `CharacterCombatProfile` | 静态配置，可平衡 |
| 基础移动倍率 | `CharacterMotionProfile` | 不和 HP 系统耦合 |
| 当前是否无敌 | `CharacterSignals` | 行为态，不是永久属性 |
| 当前是否可输入 | `CharacterSignals` | 行为态，不是属性值 |

## 10. 受击结果链路

推荐链路如下：

```text
Attack / Hazard / Trigger
-> DamageReceiver.receive_hit(hit_data)
-> CharacterStats.apply_damage(hit_data)
-> DamageResult
-> CharacterContext / State Machine / Animation Bridge
-> Hurt / Super Armor / Death / Ignore
```

关键原则：

- `CharacterStats` 只回答“数值上发生了什么”。
- 行为层再解释“动画和状态上该发生什么”。
- 这样可以避免未来战斗系统、陷阱系统、Boss 机制分别各写一套受击规则。

## 11. 事件与信号设计

建议使用稳定、少量、可组合的信号，而不是到处散落回调。

### 11.1 `CharacterStats` 推荐信号

- `hp_changed(previous_hp, current_hp)`
- `energy_changed(previous_energy, current_energy)`
- `damaged(hit_data, damage_result)`
- `healed(amount, current_hp)`
- `died(damage_result)`
- `buff_added(buff_id)`
- `buff_removed(buff_id)`

### 11.2 行为层推荐信号

- `hurt_requested(hit_data, damage_result)`
- `super_armor_hit(hit_data, damage_result)`
- `death_requested(damage_result)`
- `invincibility_changed(is_invincible)`

## 12. 数据结构草案

```gdscript
class_name DamageResult
extends RefCounted

var applied: bool = false
var previous_hp: float = 0.0
var current_hp: float = 0.0
var damage_applied: float = 0.0
var became_zero: bool = false
var was_blocked_by_invincible: bool = false
var triggered_super_armor: bool = false
```

```gdscript
class_name CharacterStatsView
extends RefCounted

var current_hp: float
var max_hp: float
var current_energy: float
var max_energy: float
var is_dead: bool
```

设计重点：

- 行为层优先读 `Result` 或只读视图，而不是回头猜测属性有没有变化。
- 结构化结果能显著降低受击、UI、相机反馈、AI 仇恨联动的耦合度。

## 13. 实体接入矩阵

| 实体 | `CharacterStats` | `CharacterSignals` | `CharacterContext` | `DamageReceiver` | 备注 |
| --- | --- | --- | --- | --- | --- |
| Player | 必需 | 必需 | 完整 | 必需 | 含 HP、Energy、Buff、死亡闭环 |
| Enemy | 必需 | 必需 | 完整 | 必需 | 含受击、击退、死亡 |
| Boss | 必需 | 必需 | 完整 | 必需 | 允许扩展阶段与特殊硬直规则 |
| NPC（可受伤） | 可选 | 可选 | 轻量或完整 | 可选 | 护送、战斗 NPC 才需要 |
| NPC（不可受伤） | 不需要 | 轻量 | 轻量 | 不需要 | 仅交互与演出 |
| 可破坏物 | HP-only | 不需要 | 不需要 | 轻量 | 破碎结果由自身脚本处理 |

## 14. Buff 与 Modifier 方向

首版建议支持两层结构：

- `Modifier`：对具体属性值做加算或乘算调整。
- `BuffInstance`：管理持续时间、来源、堆叠策略，并驱动若干 `Modifier`。

最低要求：

- 能加减最大 HP、攻击力、移动倍率、防御倍率。
- 能处理持续时间结束后的自动回滚。
- 能被 UI 和战斗日志稳定观察到。

## 15. 对移动模块的前置约束

这份文档完成后，`docs/ModuleDesign/Locomotion.md` 应默认依赖以下基础能力：

- 可以查询角色是否死亡、是否可输入、是否无敌。
- 可以读取移动相关倍率，但不让属性系统直接接管移动实现。
- 可以让受击、霸体、Buff 与移动系统发生受控交互。
- 可以让冲刺、受击、技能等行为稳定修改 `CharacterSignals`。

### 移动模块读取边界

`Locomotion` 可以读取但不应拥有：

- `move_speed_scale`
- `dash_scale`
- `air_control_scale`
- 与特殊地形或 Buff 相关的运动倍率

`Locomotion` 必须通过 `CharacterContext` 访问：

- `stats`
- `signals`
- `motion_profile`
- `animation_bridge`
- `body`

### 预留给移动与战斗协同的角色基础能力

- `CharacterSignals` 需要支持 `is_grounded`、`facing_direction`、`current_action_tag` 这类可被移动和战斗共享的运行时状态。
- `CharacterSignals` 需要允许冲刺、受击、技能等行为稳定修改角色当前动作标签。
- `CharacterContext` 需要为移动和战斗提供统一访问点，避免两边各自维护一套角色状态真相。

## 16. 实现建议

推荐初始文件组织：

```text
scripts/core/character/character_stats.gd
scripts/core/character/character_signals.gd
scripts/core/character/character_context.gd
scripts/core/character/damage_receiver.gd
resources/characters/character_combat_profile.tres
resources/characters/character_motion_profile.tres
```

## 17. 迁移结论

- 旧版文档把 `Character` 设计强绑定到 `Unity` 组件模型，不适合直接指导当前项目实现。
- 当前版本将重点收缩到 `基础属性层 + 运行时边界 + Godot 资源组织`，更适合作为后续 locomotion 和 combat 文档的依赖基础。
- `Locomotion` 文档应只保留移动系统本身的设计，不再重复定义角色基础边界。
