# Module Design: Combat Foundation

> 依据 `docs/FeatureSpecs/CombatFoundation.md`、`docs/FeatureSpecs/CorePriority.md` 与 `docs/FeatureSpecs/CharacterFeature.md`。

## 1. 设计目标

- 在 `P0-B` 建立“攻击 / 受击 / 防御 / 地面弹反 / 空中弹反”的最小战斗骨架。
- 保证战斗输入与现有 `Locomotion` 协同，不破坏已完成的移动响应性。
- 让 `Guard`、`Ground Parry`、`Air Parry` 共享一套清晰的命中结果判定链，而不是分别写成互相割裂的特殊分支。

## 2. 非目标

- 不实现完整轻重派生连招。
- 不实现复杂敌人 AI。
- 不实现完整能量消耗技、处决系统或风格系统。

## 3. 基础状态建议

首版战斗状态建议至少包含：

- `AttackLightGround`
- `AttackLightAir`
- `AttackHeavyGround`
- `AttackHeavyAir`
- `ShootGround`
- `ShootAir`
- `AttackGround`
- `AttackAir`
- `Guard`
- `ParryGround`
- `ParryAir`
- `Hurt`
- `EnemyHitStun`

说明：

- `Guard` 表示普通防御成立，但未触发精确弹反窗口。
- `ParryGround` 与 `ParryAir` 必须拆开，因为它们的收益不同：一个偏反制硬直，一个偏空中位移收益。
- 对于子弹型飞行物，`ParryGround` 与 `ParryAir` 的成功结果都应允许进入 `Projectile Parry` 分支，将飞行物反射回敌人。

## 4. 输入建议

建议在现有 `InputMap` 之外新增：

- `guard`
- `attack_light`
- `attack_heavy`
- `shoot`

首版默认约束：

- `guard` 可地面和空中触发。
- 控制器默认将 `guard` 绑定到 `RShoulder`。
- 控制器默认将 `attack_light` 绑定到 `X`。
- 控制器默认将 `attack_heavy` 绑定到 `Y`。
- 控制器默认将 `shoot` 绑定到 `B`。
- 首版不拆独立 `parry` 输入；`Parry` 由 `guard` 在“命中前极短时间按下”的条件下触发。
- 若玩家已提前按住 `guard` 并持续防御，则默认进入普通 `Guard` 结果，而不是 `Parry`。

### 4.1 输出动作分工

- `Light Attack`：快速、低承诺、用于稳定连段起手与基础命中验证。
- `Heavy Attack`：更慢、更重，强调打断感与重量感。
- `Shoot`：基础远程动作，手柄首版采用“按住瞄准、松开发射”的轻量方案，至少覆盖水平、斜上、斜下与竖直方向。
- `Shoot` 瞄准态期间，左摇杆输入从移动语义切换到瞄准语义，角色本体应被锁定在原地附近，不再吃普通水平移动与蹲伏切换。
- `Shoot` 瞄准态应提供一条轻量瞄准线，仅作为当前阶段调试与可读性辅助；后续统一反馈框架接管时应能轻松替换。

## 5. 命中结果链路

```text
Enemy Attack Hitbox
-> Player Defense Check
-> Result Branch
   -> Hurt
   -> Guard
   -> Ground Parry
   -> Air Parry
   -> Projectile Parry
-> DamageReceiver / CharacterStats / StateMachine
```

关键原则：

- 先判断是否处于防御态与弹反窗口。
- 先判断攻击是否来自角色正面；若来自背后，则直接跳过 `Guard / Parry` 判定。
- 再决定是否掉血、是否进入硬直、是否给敌人硬直。
- `Parry` 成功优先级高于普通 `Guard`。
- 若攻击对象属于可反射飞行物，则在 `Parry` 成功后优先转入 `Projectile Parry` 结果，而不是只做普通硬直结算。
- 若首枚飞行物成功触发 `Projectile Parry`，则在弹反无敌短窗口内，其余近同时抵达的正面飞行物也应按连锁弹反处理，而不是只穿体忽略。

## 6. 防御与弹反规则

### 6.1 `Guard`

- 玩家在防御态内被攻击命中，但未处于精确弹反窗口时，进入 `Guard` 结果。
- `Guard` 默认仍承受轻微伤害，或后续可扩展为消耗防御资源；首版优先采用“轻微掉血”。
- `Guard` 产生较小硬直，明显弱于普通受击。
- `Guard` 的成立前提可以是“提前按住防御”或“已进入普通防御持续态”，但只要不是在精确窗口内按下，就不升级为 `Parry`。
- `Guard` 仅对角色正面来袭的攻击有效，背后命中一律视为普通受击。
- 当前调试可读性要求：`Guard` 成立时角色周围应显示空心框，便于区分“未防御受击”和“已进入防御态”。

## 6.5 基础攻击分层

- `Light Attack` 与 `Heavy Attack` 必须是两个独立输入，不使用长按同键代替。
- `Light Attack` 与 `Heavy Attack` 在首版至少要体现节奏差异、持续时间差异或命中反馈差异。
- `Shoot` 必须作为独立结果链存在；控制器场景下当前默认流程为：按住 `Shoot` 进入瞄准态、左摇杆控制方向、松开 `Shoot` 时发射。

### 6.2 `Ground Parry`

- 玩家在地面于命中前极短窗口内按下 `guard` 时，进入 `Ground Parry`。
- 攻击还必须来自角色正面；若方向不满足，则不应错误判定为 `Ground Parry`。
- 玩家不掉血。
- 玩家获得短暂无敌帧。
- 敌人进入 `EnemyHitStun` 或专用 `ParriedStun`，时长明显高于普通命中硬直。

### 6.3 `Air Parry`

- 玩家在空中于命中前极短窗口内按下 `guard` 时，进入 `Air Parry`。
- 攻击还必须来自角色正面；若方向不满足，则不应错误判定为 `Air Parry`。
- 玩家不掉血。
- 玩家获得短暂无敌帧。
- 玩家立即获得向上回弹速度或垂直速度重置，使其能继续滞空、脱险或衔接空中动作。

### 6.4 `Projectile Parry`

- 若命中对象是标记为可弹反的子弹型飞行物，则 `Parry` 成功后，飞行物应切换阵营或伤害归属，并沿反射方向飞回敌方。
- 首版优先采用“直接反向 + 归属切换”的稳定规则，不强求复杂镜面反射几何。
- `Projectile Parry` 成功时，Player 仍获得与普通 `Parry` 一致的免伤与短暂无敌帧收益。
- 被反射的飞行物命中敌人后，应按玩家侧命中处理，可触发敌人受击、硬直或死亡。
- 敌方飞行物与玩家侧飞行物必须在颜色上明确区分；玩家主动射出的子弹和反弹后的子弹共用玩家侧配色。
- `Projectile Parry` 成功时应给出极轻但清晰的成功提示，当前阶段可采用防御框短暂变色这类易替换实现。
- 飞行物对角色的伤害结算统一走 `Hurtbox` 路径，避免角色体碰撞把反弹飞行物提前吞掉。

## 7. 参数建议

首版至少需要暴露以下参数：

| 参数 | 用途 |
| --- | --- |
| `guard_chip_ratio` | 普通防御时保留伤害比例 |
| `parry_window_ground` | 地面弹反窗口时长 |
| `parry_window_air` | 空中弹反窗口时长 |
| `parry_invincible_duration` | 弹反成功后的无敌帧时长 |
| `parry_enemy_stun_duration` | 弹反成功后的敌人硬直时长 |
| `air_parry_bounce_velocity` | 空中弹反后的向上回弹速度 |
| `projectile_parry_speed_scale` | 飞行物被反射后的速度倍率 |
| `guard_front_angle` | 正面防御有效角度范围 |

## 7.1 当前调试与反馈约束

- `dash` 残影、瞄准线、防御框、弹反闪框都属于当前阶段轻量可读性反馈，不应与未来统一反馈框架深耦合。
- 这些反馈允许使用简单 `Node2D` / `Polygon2D` 绘制实现，但后续必须可整体替换或接管。
- 敌方飞行物默认使用敌方配色；玩家主动射击与成功反射后的飞行物统一使用玩家配色。
- 当前测试阶段统一颜色约定：玩家攻击框与玩家侧飞行物使用绿色系，敌人攻击框与敌方飞行物使用橙红色系。
- 玩家轻攻击框使用亮绿色，重攻击框使用偏青绿色；两者保留同阵营语义，但能在节奏测试时一眼区分。
- 角色朝向示意框可采用前后分色，帮助快速识别 `flip` 后的正反面；防御框当前只覆盖前半身，明确表达“背后没有防护”。

## 7.2 战斗测试房分层

- 测试房固定放在 `scenes/testrooms/combat_foundation_test_room.tscn`。
- 测试房构建规则：每个房间宽度默认按 `800` 组织，每个房间只测试一个明确主题，避免多个目标互相干扰。
- 房间从左到右分成四个独立横向隔间，每个隔间默认按宽 `800` 的小房间组织，并由整面墙体隔离。
- 四个隔间分别用于：`Section 1` 射击、`Section 2` 近战、`Section 3` 双投射物连锁弹反、`Section 4` 高位单发空中弹反。
- `Layer C` 使用两台独立 `ProjectileEmitterTrap` 制造近同时到达的双发压迫，优先用于验证连锁 `Projectile Parry`。
- `Layer D` 机关高度高于玩家自然站位，要求玩家在平台或腾空过程中完成空中弹反验证。

## 8. 与 Character Foundation 的边界

- 掉血仍通过 `DamageReceiver` 和 `CharacterStats` 结算。
- `Guard`、`Ground Parry`、`Air Parry` 只是改变“是否掉血、掉多少、是否切状态”的解释层。
- `CharacterSignals.is_invincible` 继续作为弹反无敌帧的统一外部可见信号。
- 连锁 `Projectile Parry` 仍然基于同一套无敌窗口和结果解释层，不单独引入新资源系统或额外弹反状态机。

## 9. 与 Locomotion 的边界

- `Air Parry` 的向上回弹必须与现有空中运动兼容，不直接破坏 `Jump` / `Fall` / `Grapple` 的状态机骨架。
- `Ground Parry` 成功后的敌人硬直收益不应依赖额外移动系统 hack 来表达。
- `Parry` 成功时可以中断普通受击，但其优先级需要低于 `Death` 等终局状态。
- `Projectile Parry` 的飞行物归属切换必须与 `DamageReceiver` 链路兼容，避免敌我双方都把同一子弹继续当作原阵营攻击。
- 正反面判断应统一基于 `FacingDirection` 与攻击来源方向计算，避免不同攻击类型各自实现一套方向规则。

## 10. 调试输出建议

调试 HUD 至少应能看到：

- 当前战斗状态
- 最近一次受击结果：`hurt` / `guard` / `ground_parry` / `air_parry` / `projectile_parry`
- 当前是否处于 `parry_invincible`
- 最近一次 `guard` 输入是否落在 `parry_window` 内
- 最近一次输出动作：`light_attack` / `heavy_attack` / `shoot`
- 当前是否处于 `shoot_aim`
- 当前瞄准方向是否更新正常

## 11. 当前阶段结论

- `P0-B` 首版不追求复杂连招树，而是先把五类结果分支做稳：`Hurt`、`Guard`、`Ground Parry`、`Air Parry`、`Projectile Parry`。
- `P0-B` 的基础反馈以受击硬直、击退、无敌帧和结果差异为主；更完整的顿帧、镜头震动和战斗特效后续单独纳入特效规划。
- `P0-B` 当前已允许轻量调试型表现层：瞄准线、防御框、弹反闪框、轻量残影，但这些都必须保持易剥离。
- 只要这几类结果在测试房里具备清晰差异，`P0-B` 就能作为后续 `P0-C` 的可靠战斗基础。
