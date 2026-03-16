# Module Design: Combat Combo Foundation

> 依据 `docs/FeatureSpecs/CombatComboFoundation.md`、`docs/FeatureSpecs/CorePriority.md`、`docs/ModuleDesign/CombatFoundation.md` 与 `docs/ModuleDesign/CharacterFeature.md`。

## 1. 设计目标

- 在 `P0-C` 建立可扩展的连招框架，而不是只堆三条硬编码演示招式。
- 让 `Light`、`Heavy`、`Shoot`、`Grapple` 在连招语境下支持派生与追击解释。
- 保持输入可靠、命中确认清晰、目标反应分层明确。
- 为后续空连、取消链、战斗钩索与资源武器系统预留稳定接口。

## 2. 非目标

- 不实现完整动作树编辑器。
- 不实现完整 Style Rank、镜头演出与高阶特效体系。
- 不实现完整枪械弹药经济与所有枪械种类。
- 不在本阶段完成 Boss 专用空连规则与复杂霸体矩阵。

## 3. 总体结构

```text
Player Input
-> ComboController
   -> ComboChainDefinition
   -> ComboStepDefinition
   -> ComboRuntimeState
-> Combat Action Resolver
-> Attack / Shoot / Grapple Follow-up
-> Target Reaction Resolver
-> CharacterStats / DamageReceiver / Signals
```

说明：

- `ComboController` 负责连招推进，不直接结算伤害。
- `Combat Action Resolver` 负责把输入与当前连招状态解释为具体招式。
- `Target Reaction Resolver` 负责把命中结果转换为倒地、挑飞、硬直、霸体抵抗等目标反应。

## 4. 首批三条连招的系统定位

### 4.1 `Knockdown String`

- 起手：`Light 1 -> Light 2`
- 终结：派生 `Heavy Finisher`
- 目标反应：
  - 小体型 / 普通动物：倒地
  - 大体型非霸体：显著硬直
  - 霸体：减弱或抵抗

### 4.2 `Launcher Gun Dump String`

- 起手：`Light 1 -> Light 2 -> Light 3`
- 终结：垂直挑飞 `Heavy Launcher`
- 跟进：空中 `Shoot -> Shoot`
- 资源后果：进入 `Reload`

### 4.3 `Air Chase Grapple String`

- 前置：必须处于空中
- 起手：空中 `Light 1 -> Light 2 -> Light 3`
- 终结：空中打飞 `Heavy`
- 跟进：`Grapple Chase`
- 结果：玩家快速追到被打飞敌人附近

## 5. 核心运行时概念

### 5.1 `ComboStepDefinition`

每段连招至少需要描述：

- `step_id`
- `input_action`
- `action_tag`
- `requires_hit_confirm`
- `allowed_state_tags`
- `followup_window_open`
- `followup_window_close`
- `next_step_ids`
- `branch_type`

用途：

- 让每段招式成为数据对象，而不是只靠 if/else 判断第几段。

### 5.2 `ComboChainDefinition`

每条连招至少需要描述：

- `chain_id`
- `entry_conditions`
- `step_sequence`
- `finisher_tags`
- `resource_hooks`
- `target_reaction_profile`

用途：

- 定义一条连招的身份与整体规则。

### 5.3 `ComboRuntimeState`

运行时至少需要记录：

- 当前连招 ID
- 当前步骤 ID
- 最近一次命中是否成立
- 当前可接受的下一输入窗口
- 连招是否已进入终结段
- 当前是否处于追击窗口

## 6. 输入与派生解释

### 6.1 同输入不同结果

`Heavy` 需要支持至少四种解释：

- 普通 `Heavy`
- `Knockdown Finisher`
- `Launcher Heavy`
- `Air Knockback Heavy`

设计原则：

- 输入不变，但解释依赖当前 `ComboRuntimeState`。
- 若不满足连招条件，则必须稳定回退为普通招式，不允许进入无定义状态。

### 6.2 命中确认要求

- `Knockdown String` 的终结 `Heavy` 建议要求前两段至少有一次有效命中。
- `Launcher Gun Dump String` 的挑飞 `Heavy` 建议要求前段链路成立。
- `Air Chase Grapple String` 的追敌 `Grapple` 建议要求空中打飞成立并进入追击窗口。

## 7. 目标反应层

### 7.1 目标分类

首版建议使用轻量分类：

- `humanoid_small`
- `animal_small`
- `large`
- `super_armor`

### 7.2 反应结果

首版建议至少支持：

- `knockdown`
- `launcher`
- `air_knockback`
- `heavy_stagger`
- `resisted`

### 7.3 规则建议

- `knockdown`：只对小体型和普通动物默认成立。
- `launcher`：优先对可挑飞目标成立。
- `heavy_stagger`：用于大型非霸体目标。
- `resisted`：用于霸体或强抗性目标。

## 8. `Launcher Gun Dump` 的资源链路

### 8.1 首版要求

- `Shoot -> Shoot` 必须是连招跟进，而不是普通随便开枪。
- 第二次 `Shoot` 后进入 `Reload`。
- `Reload` 至少要形成明确输入限制或状态锁定，不应只是日志标记。

### 8.2 设计边界

- `P0-C` 允许只为手枪建立最小 `magazine / reload` 闭环。
- 完整枪械系统留到后续阶段扩展。

## 9. `Air Chase Grapple` 的追敌链路

### 9.1 推荐首版做法

不要直接钩敌人碰撞体本体，优先采用：

- 敌人被空中终结击飞后生成一个短时追击目标点
- `Grapple` 在窗口内优先锁定该追击点
- 玩家被高速拉到该点附近

理由：

- 比直接绑敌人本体更稳定
- 更容易限制窗口时长和追击距离
- 不会立刻与完整敌人位移同步、受击动画、骨架节点绑定耦合过深

### 9.2 失败条件

至少要覆盖：

- 没有追击点
- 追击窗口已过
- 玩家当前状态不允许
- 目标已死亡或失效

## 10. 与现有模块边界

### 10.1 与 `CombatFoundation`

- 仍使用 `P0-B` 的基础命中链、受击链与基础攻击资源。
- `P0-C` 只增加“当前攻击如何解释为连招步骤”的上层逻辑。

### 10.2 与 `CharacterFeature`

- 连招运行时状态建议通过 `CharacterSignals` 或专用 `ComboRuntimeState` 暴露只读信息。
- 不建议把完整连招状态直接塞进 `CharacterStats`。

### 10.3 与 `Locomotion`

- 第三条连招要复用现有 `Grapple` 运动能力。
- 但“追敌目标”的判定应属于战斗层，而不是让 `Locomotion` 自己猜敌人。

## 11. 调试输出建议

调试 HUD 至少应显示：

- 当前连招 ID
- 当前步骤 ID
- 最近一次命中确认是否成立
- 当前是否在 follow-up window
- 当前 `Heavy` 被解释成哪种派生
- 当前是否处于 `Reload`
- 当前是否存在可追击 `Grapple` 目标

## 12. 推荐文件组织

```text
scripts/player/combo/combo_controller.gd
scripts/player/combo/combo_chain_definition.gd
scripts/player/combo/combo_step_definition.gd
scripts/player/combo/combo_runtime_state.gd
resources/combat/player_combo_chains/*.tres
```

## 13. 迁移策略

### 13.1 首轮实现建议顺序

1. 建 `ComboRuntimeState`
2. 建 `ComboController`
3. 先接 `Knockdown String`
4. 再接 `Launcher Gun Dump String`
5. 最后接 `Air Chase Grapple String`

### 13.2 为什么按这个顺序

- `Knockdown String` 依赖最少，是最稳的地面模板。
- `Launcher Gun Dump String` 会引入挑空和 `Reload`。
- `Air Chase Grapple String` 依赖最多，涉及战斗追敌目标与位移整合。

## 14. 当前结论

- `P0-C` 首版应先把三条原型连招做成框架模板，而不是直接扩成大量招式。
- 最关键的系统点是：连招步骤、派生终结技、命中确认、目标反应分层、跟进窗口、资源后果。
- 若这六个点设计清楚，后续新连招可以按数据和规则扩展，而不需要继续追加大块硬编码。

## 15. 当前骨架状态

- `ComboRuntimeState`、`ComboController`、`ComboStepDefinition`、`ComboChainDefinition` 的最小代码骨架已落地。
- `PlayerController` 已持有 `ComboController`，并通过 `PlayerTestActor` 暴露只读运行时状态入口。
- 当前骨架阶段只接入了动作记录、命中确认标记与 HUD 可视化，还未正式推进三条连招的步骤分支、派生终结与资源链路。
