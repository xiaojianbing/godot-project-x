# Module Design: Locomotion

> 依据 `docs/FeatureSpecs/CorePriority.md`、`docs/FeatureSpecs/CharacterFeature.md`、`docs/ModuleDesign/CharacterFeature.md` 与 `docs/Glossary.md`。

---

## 1. 文档目标

本设计文档定义 `P0-A` 阶段的角色移动系统，目标是在 `Godot 4` 中建立一套**低延迟、强响应、强可预测性**的 2D 动作平台移动骨架，为后续战斗、能力解锁和区域设计提供统一基础。

本阶段重点是：

- 跑、停、跳、落、转向的主观手感。
- `Coyote Time`、`Jump Buffer`、`Corner Correction` 等容错机制。
- 墙滑、墙跳、冲刺、边缘攀爬等基础移动动作。
- 为后续 `Swim` 等能力门预留可实现的状态、检测与参数结构。
- 与 `Character Foundation` 的集成方式。

本阶段不展开完整战斗状态树，但必须为 `P0-B` / `P0-C` 的攻击取消、空连追击、受击打断预留足够接口。

## 2. 设计目标

- 让玩家在灰盒地图中仅凭移动就感到角色“顺手、跟手、可信”。
- 让移动结果稳定可复现，降低“我明明按对了却没出”的挫败感。
- 让移动系统天生兼容 `Metroidvania-like` 的能力门与回访探索。
- 保持移动层职责清晰，不把数值、输入、战斗、重生全部混进同一个脚本。

## 3. 非目标

- 不定义完整攻击系统、受击系统与连招树。
- 不定义地图系统、存档系统和 Boss 规则。
- 不在本阶段实现所有后期能力，只为它们预留扩展位。

## 4. 手感原则

### 4.1 输入优先

- 玩家输入必须先于“物理正确性执念”被尊重。
- 角色应尽量做出玩家**期望发生**的动作，而不是只做“数值上最严格”的动作。
- 对于跳跃、墙跳、冲刺等高频动作，宁可做少量合理宽容，也不要让玩家怀疑输入丢失。

### 4.2 稳定可预测

- 相同输入在相同情境下应产生相同结果。
- 宽容机制必须稳定，不允许随机成功或随机失败。
- 所有容错应有清晰边界，避免角色像被隐形手推动。

### 4.3 动作有明确用途

- 跑步是基础位移与战斗站位的底层动作。
- 跳跃是平台解法、闪避纵向威胁和空战入口。
- 冲刺是快速位移、规避威胁和后续战斗取消的基础支点。
- 当前测试版 `Dash` 还应承担基础穿透职责：玩家冲刺时可穿过敌人角色体，并穿过敌方投射物。
- 当前测试版 `Dash` 还应承担基础规避判定职责：玩家冲刺期间不应再被敌人近战接触伤害错误命中。
- 当前 `Dash` 残影仅作为轻量占位反馈实现，需保持易剥离，后续统一音效/特效框架接管时不应形成强耦合。
- 墙滑/墙跳/边缘攀爬是垂直探索与高难房间的核心手段。

## 5. 系统分层

```text
Player Scene
-> CharacterBody2D
-> PlayerController
   -> PlayerInputBuffer
   -> LocomotionStateMachine
   -> GroundDetector / WallDetector / LedgeDetector
   -> LocomotionMotor
   -> CharacterContext
```

说明：

- `PlayerController` 负责组装，不负责全部逻辑。
- `PlayerInputBuffer` 统一处理输入缓存和消费。
- `LocomotionMotor` 负责速度计算和 `move_and_slide()` 执行。
- 检测节点负责地面、墙体、边缘、头顶空间等信息收集。
- `CharacterContext` 作为角色基础层的统一访问入口，由 `CharacterFeature` 文档定义其边界。

## 6. 推荐场景结构

```text
Player.tscn
-> Player (CharacterBody2D)
   -> SpriteRoot (Node2D)
   -> AnimationPlayer
   -> CollisionShape2D
   -> GroundRayLeft (RayCast2D)
   -> GroundRayRight (RayCast2D)
   -> WallRayFrontHigh (RayCast2D)
   -> WallRayFrontLow (RayCast2D)
   -> HeadRay (RayCast2D)
   -> LedgeRayForward (RayCast2D)
   -> LedgeRayDown (RayCast2D)
   -> Hurtbox
   -> HitboxAnchor
```

## 7. 核心模块职责

### 7.1 `PlayerController`

应负责：

- 在 `_physics_process()` 中驱动 locomotion 更新。
- 收集 `InputMap` 输入并写入 `PlayerInputBuffer`。
- 组装 `CharacterContext`、`LocomotionMotor`、检测器、状态机。

不应负责：

- 直接写全部跳跃、冲刺、墙跳细节。
- 自己同时承担受击、战斗、Buff、重生逻辑。

#### 当前落地目标

- `PlayerController` 作为 `Player` 场景下的独立子节点存在。
- 它持有 `PlayerInputBuffer`、`PlayerInputSnapshot`、`LocomotionStateMachine`、`LocomotionMotor`、各类 detector。
- `PlayerTestActor` 或后续 `PlayerActor` 负责持有 `CharacterBody2D`、`CharacterContext` 与动作原语。
- `PlayerController` 读取输入、驱动状态机、最后统一提交 `move_and_slide()`。

### 7.2 `PlayerInputBuffer`

应负责：

- 缓存 `jump`、`dash`、`attack` 等动作请求。
- 提供带时间窗的查询，例如 `consume_jump_if_valid()`。
- 记录按下、松开、持续按住等状态。

设计目标：

- 支持 `Jump Buffer`。
- 后续直接复用于攻击输入缓存。
- 给“高频输入不丢失”提供统一入口。

#### 实现版补充

- `PlayerInputBuffer` 只负责“带时间窗的动作请求”，不承担轴向值记录。
- 轴向输入、按住状态、just pressed 等瞬时输入由 `PlayerInputSnapshot` 承担。
- 本阶段最少缓存：`jump`、`dash`。
- 后续预留：`attack_light`、`attack_heavy`、`parry`、`interact`。

#### 推荐职责划分

| 模块 | 责任 |
| --- | --- |
| `PlayerInputSnapshot` | 当前帧输入快照，如横向轴、`jump_pressed`、`dash_just_pressed` |
| `PlayerInputBuffer` | 带时间窗的动作请求缓存，如 `jump_buffer_remaining` |

### 7.3 `LocomotionMotor`

应负责：

- 根据目标速度、加速度、重力和状态输出最终 `velocity`。
- 统一调用 `CharacterBody2D.move_and_slide()`。
- 提供跳跃起速、水平加速、空中控制、冲刺速度写入等基础操作。

不应负责：

- 决定是否允许跳跃。
- 决定状态切换时机。

#### 实现版补充

- `LocomotionMotor` 应逐步收拢以下纯运动计算：
- 目标水平速度计算
- 地面/空中加速度选择
- 上升/下落重力选择
- 跳跃、二段跳、墙跳、冲刺速度写入
- 冲刺方向归一化
- 最终 `move_and_slide()` 提交

- `LocomotionMotor` 不应知道 `Coyote Time`、`DoubleJump` 剩余次数、`EdgeIdle` 输入分支这类状态规则。

### 7.4 `LocomotionStateMachine`

建议使用轻量状态机，首版包含：

- `Idle`
- `Run`
- `Crouch`
- `CrouchMove`
- `Jump`
- `Fall`
- `Dash`
- `CrouchDash`
- `WallSlide`
- `WallJump`
- `DoubleJump`
- `EdgeIdle`
- `EdgeClimb`

后续预留：

- `Slide`

`Grapple` 虽然是剧情后期开启能力，但与 `Swim` 一样，不应只停留在一句“以后再说”的占位。当前阶段至少需要完成：钩点对象约束、输入入口、锁定/失锁规则、状态切换、中断优先级、参数结构与测试场景要求定义，确保后续接入时不需要重构已有 locomotion 骨架。

`Swim` 虽然是剧情后期开启能力，但不再视为“纯后续补充项”；本阶段必须完成它的架构预留、水体检测入口、参数分组与状态切换规则定义，保证后续接入时不需要推倒重写主移动骨架。

### 7.5 检测模块

建议拆成小型辅助组件或封装函数，负责：

- 地面接触
- 墙体接触
- 边缘可抓取
- 头顶是否有空间
- 当前是否处于可墙跳窗口

#### 实现版检测拆分

| Detector | 责任 |
| --- | --- |
| `GroundDetector` | `is_grounded`、coyote 计时更新、落地恢复条件 |
| `WallDetector` | `is_on_wall`、`is_wall_sliding`、`can_wall_jump`、墙法线 |
| `LedgeDetector` | 边缘射线更新、`EdgeIdle` 可挂判定、`EdgeClimb` snap 位置 |

#### 检测节点建议

- `GroundRayLeft` / `GroundRayRight`：后续用于更细的地面贴合和边缘离地判定。
- `WallRayFrontHigh` / `WallRayFrontLow`：后续用于更稳定的墙体判定与低矮边缘过滤。
- `HeadRay`：检测站起阻挡、边角修正和抓边头顶空间。
- `LedgeRayForward` / `LedgeRayDown`：判定是否存在可挂边缘与翻越落点。

## 8. 配置资源使用

移动系统读取 `CharacterMotionProfile` 作为基础运动参数来源，而不是在状态里硬编码全部参数。

### 8.1 核心参数组

| 参数组 | 说明 |
| --- | --- |
| `run` | 最大地面速度、加速度、减速度、转向减速 |
| `crouch` | 下蹲进入时间、蹲行速度、蹲姿碰撞体高度 |
| `jump` | 跳高目标、起跳速度、上升重力、下落重力、可变跳高度 |
| `double_jump` | 空中二次起跳速度、可用次数、恢复条件 |
| `coyote` | 土狼时间长度 |
| `buffer` | 跳跃缓存、冲刺缓存 |
| `air` | 空中控制、空中减速 |
| `dash` | 冲刺速度、持续时间、结束衰减、冷却 |
| `wall` | 墙滑速度比例、墙跳水平推力、墙跳锁定时间 |
| `ledge` | 边缘抓取偏移、`EdgeIdle` 对齐规则、翻越持续时间 |
| `swim` | 水中水平/竖直速度、加速度、浮力/下沉、入水/出水过渡 |
| `grapple` | 钩索搜索半径、锁定角度、起手速度比例、拉拽上限速度、到点阈值、穿点后减速、失锁规则 |

### 8.2 参数来源原则

- “决定手感骨架”的参数来自移动配置资源。
- “决定成长与强化”的倍率可来自 `CharacterStats`。
- 例如 `move_speed_scale`、`dash_scale`、`air_control_scale` 可以在最终计算时乘到基础参数上。

### 8.3 首版参数清单

实现阶段至少应暴露以下参数：

| 参数 | 用途 |
| --- | --- |
| `base_move_speed` | 基础水平移动速度 |
| `ground_acceleration` | 地面加速 |
| `ground_deceleration` | 地面减速 |
| `jump_velocity` | 首跳起跳速度 |
| `gravity_up` | 上升阶段重力 |
| `gravity_down` | 下落阶段重力 |
| `coyote_time` | 土狼时间 |
| `jump_buffer_time` | 跳跃缓存 |
| `double_jump_velocity` | 二段跳起跳速度 |
| `double_jump_count` | 空中二段跳次数 |
| `wall_slide_speed_ratio` | 墙滑速度相对自由下落速度比例 |
| `wall_jump_horizontal_speed` | 墙跳水平推出 |
| `wall_jump_vertical_speed` | 墙跳竖直速度 |
| `wall_jump_input_lock_time` | 墙跳输入锁 |
| `dash_speed` | 普通冲刺速度 |
| `dash_duration` | 普通冲刺持续时间 |
| `dash_cooldown` | 普通冲刺冷却 |
| `crouch_move_speed` | 蹲行速度 |
| `crouch_dash_speed` | 蹲冲速度 |
| `crouch_dash_duration` | 蹲冲持续时间 |
| `corner_correction_distance` | 边角修正水平量 |
| `edge_idle_snap_offset` | 挂边时角色对齐偏移 |
| `ledge_climb_up_distance` | `EdgeClimb` 上移距离 |
| `ledge_climb_forward_distance` | `EdgeClimb` 前移距离 |
| `ledge_climb_duration` | `EdgeClimb` 总时长 |
| `swim_horizontal_speed` | 水中水平移动速度 |
| `swim_vertical_speed` | 水中竖直移动速度 |
| `swim_acceleration` | 水中加速 |
| `swim_deceleration` | 水中减速 |
| `swim_buoyancy` | 水中上浮趋势 |
| `swim_surface_exit_boost` | 出水瞬间附加竖直速度 |
| `grapple_search_radius` | 钩点搜索半径 |
| `grapple_snap_angle` | 钩点锁定角度容差 |
| `grapple_initial_speed_ratio` | 钩索起手速度相对最大拉拽速度比例 |
| `grapple_pull_speed` | 钩索拉拽速度 |
| `grapple_min_pull_duration` | 最短拉拽时长 |
| `grapple_arrive_threshold` | 判定到达钩点的距离阈值 |
| `grapple_release_boost` | 释放时保留或附加的速度 |
| `grapple_release_duration` | 穿点后保留拉拽状态的短暂时长 |
| `grapple_release_deceleration` | 穿点后快速减速强度 |

## 9. 输入设计

### 9.1 `InputMap` 动作建议

- `move_left`
- `move_right`
- `move_up`
- `move_down`
- `jump`
- `dash`
- `attack_light`
- `attack_heavy`
- `interact`
- `grapple`

### 9.2 输入读取规则

- 轴向输入每帧读取。
- 动作类输入写入 `PlayerInputBuffer`。
- 状态消费输入，而不是直接在输入读取处触发动作。

这样做的原因：

- 让移动与战斗都能共享一套输入可读性逻辑。
- 减少“多处同时消费同一输入”的混乱。

### 9.3 输入约定

| 输入 | 主要用途 |
| --- | --- |
| `move_left` / `move_right` | 跑、转向、墙跳方向参考 |
| `move_up` | 进入 `EdgeClimb`、水中上浮、后续上方向动作 |
| `move_down` | 进入 `Crouch`、`EdgeIdle` 下滑/松手分支、水中下潜 |
| `jump` | 首跳、二段跳、墙跳、`EdgeIdle` 跳离 |
| `dash` | 普通冲刺、蹲冲派生 |
| `grapple` | 搜索可用钩点并进入 `Grapple` 拉拽 |

### 9.4 输入消费规则

- `jump` 优先级：`EdgeIdle Jump` > `WallJump` > `DoubleJump` > `Ground Jump` > `Coyote Jump` > `Buffered Jump`。
- `dash` 优先级：`CrouchDash` > 普通 `Dash`。
- `grapple` 默认仅在空中态消费；若当前没有合法钩点，必须输出明确失败原因而不是吞输入。
- 当状态不允许消费某输入时，HUD 或 debug 输出必须保留失败原因，避免玩家误以为吞输入。

## 10. 状态切换原则

### 10.1 地面态

- `Idle`：无水平输入，速度归零或接近归零。
- `Run`：有明确水平输入，目标速度可达。
- `Crouch`：玩家按下后进入下蹲，碰撞体与可通行空间发生变化。
- `CrouchMove`：玩家在下蹲状态下缓慢移动，用于低矮通道与谨慎位移。

### 10.2 空中态

- `Jump`：起跳后的上升期。
- `Fall`：竖直速度转负或离地后进入下落期。
- `DoubleJump`：空中再次起跳，重置竖直速度并给予明确的二段跳反馈。

### 10.3 特殊态

- `Dash`：短时高速度动作，可中断普通移动。
- `CrouchDash`：下蹲派生冲刺，用于穿越低矮通道或做贴地高速位移。
- `WallSlide`：贴墙下滑，控制下落速度。
- `WallJump`：从墙面反向弹出，短时间锁定部分水平控制。
- `Grapple`：锁定合法钩点后，角色先被带动、再逐步加速拉向目标点，穿过钩点后进入短暂的高速减速段，再回到普通空中动作。
- `Swim`：角色位于水体中时的专用移动状态，允许独立的水平/竖直控制与浮力表现。
- `EdgeIdle`：角色挂在平台边缘，角色上边缘与平台平面基本持平，等待玩家给出下一步输入。
- `EdgeClimb`：成功抓边后执行翻上流程。

### 10.4 优先级建议

- `Death` / `Hurt` / `SuperArmorReaction` 高于 locomotion。
- `Dash` 高于普通地面/空中移动。
- `CrouchDash` 高于普通 `CrouchMove`。
- `EdgeIdle` 高于普通 `Fall`。
- `EdgeClimb` 高于普通 `Fall`。
- `WallJump` 在短锁定期内高于普通空中输入。
- `Grapple` 高于普通 `Jump` / `Fall` / `WallSlide`，但低于 `Death` / `Hurt` / `Respawn` 等系统中断。
- `Swim` 高于普通 `Idle` / `Run` / `Jump` / `Fall`，但低于 `Death` / `Hurt` / `Respawn` 等系统中断。

### 10.5 实现版状态切换总表

| 当前状态 | 输入/条件 | 下个状态 |
| --- | --- | --- |
| `Idle` | 水平输入 | `Run` |
| `Idle` | `move_down` | `Crouch` |
| `Idle` | `jump` | `Jump` |
| `Idle` | `dash` | `Dash` |
| `Run` | 无水平输入 | `Idle` |
| `Run` | `move_down` | `Crouch` |
| `Run` | `jump` | `Jump` |
| `Run` | `dash` | `Dash` |
| `Crouch` | 保持 `move_down` 且有水平输入 | `CrouchMove` |
| `Crouch` | 释放 `move_down` 且头顶无遮挡 | `Idle` / `Run` |
| `Crouch` | `dash` | `CrouchDash` |
| `Jump` | 上升结束 | `Fall` |
| `Jump` / `Fall` | 空中再次 `jump` 且剩余次数 > 0 | `DoubleJump` |
| `Jump` / `Fall` / `WallSlide` | `grapple` 且存在合法钩点 | `Grapple` |
| 任意普通地面/空中态 | 进入水体且已解锁游泳 | `Swim` |
| 任意普通地面/空中态 | 进入水体且未解锁游泳 | 锁水反馈 / `AbyssRespawn` |
| `Fall` | 墙体接触 | `WallSlide` |
| `Fall` | 可挂边 | `EdgeIdle` |
| `Grapple` | 到达钩点并穿点减速结束 | `Fall` / 后续空中动作 |
| `Grapple` | 受击、死亡、失去钩点合法性 | 中断到高优先级状态 |
| `Swim` | 离开水体且脚下有地面 | `Idle` / `Run` |
| `Swim` | 离开水体且仍在空中 | `Fall` |
| `WallSlide` | `jump` | `WallJump` |
| `WallSlide` | 离墙 | `Fall` |
| `EdgeIdle` | `move_up` | `EdgeClimb` |
| `EdgeIdle` | `jump` | `WallJump` |
| `EdgeIdle` | `move_down` / 背离平台方向 | `Fall` / `WallSlide` |
| `Dash` / `CrouchDash` | 持续时间结束 | `Idle` / `Run` / `Fall` |
| `EdgeClimb` | 动作结束 | `Idle` |

## 11. 关键机制设计

### 11.1 地面移动

- 地面加速要快于空中加速。
- 转向时允许更高减速度，避免角色“拖泥带水”。
- 完全松开输入时快速减速，但不能显得像突然吸附。

### 11.1.1 下蹲、蹲行与蹲冲

- `Crouch` 必须是明确状态，而不是简单播放一个蹲下动画。
- 下蹲后角色碰撞体应缩小，以支持穿越低矮通道。
- `CrouchMove` 应明显慢于正常 `Run`，但不能慢到失去控制感。
- `CrouchDash` 是从下蹲状态派生的贴地冲刺，应优先服务地形穿越与后续战斗联动。
- 若头顶空间不足，角色离开 `Crouch` 时应保持蹲姿，而不是强行站起。

#### 实现版补充

- `Crouch` 应触发碰撞体高度切换。
- `CrouchMove` 默认只允许地面态进入。
- `CrouchDash` 默认沿角色朝向执行，不允许空中触发。
- `CrouchDash` 结束后若仍按住 `move_down`，应回到 `Crouch` 或 `CrouchMove`，而不是直接站立。

### 11.2 跳跃

- 起跳速度由目标跳高和上升时间推导，不使用难以解释的魔法数。
- 长按跳跃键维持更高跳跃，松开则提前切入更强下坠。
- `Coyote Time` 与 `Jump Buffer` 默认启用。

### 11.2.1 二段跳

- `DoubleJump` 允许角色在空中再次跳跃一次。
- 二段跳应重置竖直速度，并提供与首跳明显区分的视觉或状态反馈。
- 二段跳使用次数在落地后恢复，后续若设计多段空中跳跃，应从此规则扩展。
- 设计上将其视为重要探索能力门，即使在原型阶段先默认开启，也要保留后续解锁开关。

#### 实现版补充

- 首版默认限制为“最多一次额外空中跳跃”。
- `DoubleJump` 不能在 `WallSlide`、`EdgeIdle` 中直接覆盖更高优先级动作。
- `DoubleJump` 成功时应重置竖直速度，并可选重置部分空中横向控制窗口。
- 落地时恢复空中跳次数；后续如有存档/能力门控制，应通过 `World State` 或能力解锁模块启用。

### 11.3 下落

- 下落重力应略大于上升重力，增强干脆感。
- 接近地面时可以配合轻量落地缓冲，避免视觉抖动。

### 11.4 冲刺

- 冲刺应是短、快、明确的动作，而不是长时间漂移。
- 首版可优先做 4 向或水平冲刺；若要 8 向，必须确认不会破坏平台设计可读性。
- 冲刺结束要有可控收尾，避免速度突兀归零。
- `CrouchDash` 若存在，必须与普通 `Dash` 明确区分进入条件、姿态和地形用途。

#### 实现版补充

- 首版普通 `Dash` 维持水平冲刺即可，不强求 8 向。
- `Dash` 期间可标记无敌帧。
- `Dash` 结束后需要一小段可控收尾，不应让速度瞬间变成完全静止。
- `CrouchDash` 的姿态和碰撞体必须允许穿越低矮通道，否则它失去设计意义。

### 11.5 墙滑与墙跳

- 角色贴墙时进入受控下滑，不应无限停空。
- 墙跳后要有清晰的横向推出力与短暂输入锁定，防止立刻吸回原墙。
- 墙跳窗口应与墙体检测、朝向和输入方向共同判定。
- 墙滑速度建议默认以“自由落体速度的约 50%”为调参起点，再按手感细修。
- 最终暴露给配置资源的不是绝对拍脑袋数值，而应支持相对自由落体速度的比例化调节。

### 11.6 边缘攀爬

- 只有在前方有边、头顶空间足够、角色速度和位置满足条件时才允许抓边。
- 抓边后动作要稳定，不允许反复闪烁进入/退出。
- 边缘攀爬应主要服务垂直探索和路线连续性，而不是成为强制慢动作流程。

### 11.6.1 `EdgeIdle` / `EdgeClimb` 详细规则

- 当角色挂在边缘时，应先进入 `EdgeIdle`，而不是直接自动翻上平台。
- `EdgeIdle` 时角色的上边缘应与平台平面大致持平，玩家能清楚感知“已经挂住”。
- `EdgeIdle` 输入规则：
- 按 `down`：进入 `WallSlide` 或直接松手下落，具体以后续最终手感方案为准。
- 按“后”（背离平台方向）：立即松手进入 `Fall`。
- 按 `jump`：执行 `WallJump`。
- 按 `up`：进入 `EdgeClimb`。
- `EdgeClimb` 流程应先做向上位移，让角色下边缘越过平台平面，再做向平台方向的小段水平位移，最终稳定站立。
- `EdgeIdle` 与 `EdgeClimb` 都必须避免闪烁切换、重复抓取和错误吸附。

#### 11.6.2 `EdgeIdle` / `EdgeClimb` 实现版补充

- `EdgeIdle` 进入时必须执行一次 snap 对齐，避免角色挂点忽高忽低。
- `EdgeIdle` 期间默认锁定普通跑步输入，不允许同时被地面态和挂边态争抢。
- “后” 的定义是与当前平台方向相反的水平输入，而不是世界固定左右。
- `EdgeClimb` 建议拆成两个阶段：`up phase` 与 `forward phase`，即使最终仍由单状态实现，也要保留内部阶段概念。

### 11.7 游泳

- `Swim` 的目标不是复制地面移动，而是提供明显更粘滞、更缓慢、但依旧可预测的水中控制。
- 入水后角色应切换到独立的水平/竖直运动参数，不再直接沿用普通重力下落手感。
- `move_up` 对应上浮，`move_down` 对应下潜；未输入时允许轻微浮力或缓慢下沉，但必须稳定可调。
- 水中默认禁用 `Crouch`、`CrouchMove`、`CrouchDash`、`WallSlide`、`EdgeIdle`；是否允许 `Dash` / `DoubleJump` 需要由能力规则显式决定，首版默认关闭以减少状态冲突。
- 角色从水面出水时可选给予轻微 `surface_exit_boost`，让跃出水面的反馈更连贯，但不得破坏平台段可读性。
- 未解锁游泳时，进入深水应走锁水逻辑，并与 `AbyssRespawn` 文档中的失足/落水处理保持一致。

#### 11.7.1 实现版补充

- 水体建议通过 `Area2D` + 专用组或标签提供 `is_in_water` 信号，不把水体判断硬编码进 `LocomotionMotor`。
- `LocomotionStateMachine` 只根据 `is_in_water` 与 `swim_unlocked` 决定是否进入 `Swim`；具体浮力、速度、阻尼由 `LocomotionMotor` 和 `CharacterMotionProfile` 参数组驱动。
- `Swim` 状态需要提供明确的失败原因输出，例如“未解锁游泳”“当前水体禁止进入”“被高优先级状态中断”。
- 若后续存在浅水区，应允许设计成“不进 `Swim` 状态，仅施加移动倍率”的独立关卡规则，避免把所有水体都强绑成完整游泳。

### 11.8 钩索

- `Grapple` 首版目标是“固定钩点、先缓后快地拉近、穿点后快速减速”，而不是一上来就实现复杂摆荡物理。
- 角色默认仅在空中态允许触发 `Grapple`，避免与地面移动、下蹲、攀边等已有状态互抢。
- 按下 `grapple` 后，系统应在可配置搜索范围内寻找合法钩点；若无合法目标，必须输出明确失败原因。
- 成功锁定后，角色应先以较低速度被钩索带动，在接近钩点时明显提速，穿过钩点后保留惯性并在短窗口内快速减速，不允许在钩点处瞬间清零速度。
- 未解锁钩索时，即使场景中存在钩点，也只能给出锁定失败反馈，不允许进入 `Grapple` 状态。

#### 11.8.1 实现版补充

- 钩点建议作为独立节点或 `Area2D` 资源对象存在，并通过组、标签或接口暴露“是否可被钩索命中”。
- `LocomotionStateMachine` 只负责决定是否进入 `Grapple`；具体拉拽曲线、速度上升、穿点衰减、到点阈值由 `LocomotionMotor` 和 `CharacterMotionProfile` 参数组驱动。
- 首版默认不做摆荡、绳长模拟和物理绳渲染；只需要把“锁定 -> 拉近 -> 释放”三段体验做稳定。
- `Grapple` 的失败原因至少要覆盖：未解锁、无合法钩点、当前状态不允许、钩点中途失效。

## 12. 容错与可读性设计

### 12.1 `Coyote Time`

- 离地后短时间内仍允许起跳。
- 计时应以“最后一次稳定在地面”的时刻为准。

### 12.2 `Jump Buffer`

- 玩家落地前提前按下跳跃，应在落地瞬间自动起跳。
- 同一请求只能被消费一次。

### 12.3 `Corner Correction`

- 上升阶段轻撞边角时，允许进行少量水平修正。
- 修正量必须小而稳定，不能让角色像被吸附到平台上。

### 12.4 输入可读性

- 若跳跃失败，应能明确归因：没有地面、没有土狼、没有缓存、状态锁定中。
- 若冲刺失败，应能明确归因：冷却中、资源不足、状态禁用。
- 若下蹲或站起失败，应能明确归因：头顶空间不足或当前状态不允许切换。
- 若 `DoubleJump` 失败，应能明确归因：空中次数已耗尽或当前状态禁用。
- 若 `EdgeClimb` 未触发，应能明确归因：无有效边缘、头顶受阻、方向输入不符或当前状态优先级更高。

### 12.5 失败原因与调试输出

- 调试 HUD 至少应显示：当前状态、速度、是否着地、是否贴墙、coyote 剩余时间、dash 剩余时间。
- 对于失败输入，至少应记录最近一次 `jump` 与 `dash` 的失败原因。
- 后续应扩展到 `Crouch`、`DoubleJump`、`EdgeClimb`、`Swim`、`Grapple` 的失败原因输出。

## 13. 预留给战斗系统的接口

虽然本阶段不实现完整战斗，但 locomotion 必须预留以下能力：

- 冲刺期间可标记无敌帧。
- 跳跃、下落、冲刺、墙跳状态都能暴露给攻击系统做招式分支。
- 空中态与地面态切换要足够稳定，供 `air attack` / `ground attack` 判定复用。
- `PlayerInputBuffer` 未来可扩展支持攻击缓存与取消窗口。
- 移动状态优先级要能与 `Hurt` / `Attack` / `Ultimate` 协同。

### 13.2 当前 `Dash` 与战斗的接口约束

- `Dash` 期间玩家 body 碰撞应临时忽略敌人角色体，但仍保留世界碰撞。
- `Dash` 期间敌方投射物命中玩家 `Hurtbox` 时，应视为穿透，不应错误结算普通受击。
- `Dash` 期间敌人近战接触判定命中玩家时，也应跳过伤害结算。
- 当前 `Dash` 残影只承担轻量视觉提示职责，不承载真实命中、无敌或资源结算语义。
- 当前 `Dash` 残影实现应继续保持轻脚本、轻节点、易删除，后续统一反馈框架接管时可整体替换。

### 13.1 当前阶段对齐目标

- 在代码实现上，优先完成 `PlayerController`、`detector`、`motor`、`state machine` 四部分的职责拆分，再去进入 Combat。
- `Locomotion` 在达到“结构可扩展 + 测试可验证 + 原型可玩”前，不进入后续战斗模块实现。
- `Combat` 接入前，`Locomotion` 至少要完成：`Crouch Family`、`DoubleJump`、`EdgeIdle/EdgeClimb`、`Swim` 架构预留与锁水边界定义、`Grapple` 架构预留与钩点规则定义、失败原因可视化与关键参数稳定化。

## 14. 推荐文件组织

```text
scripts/player/player_controller.gd
scripts/player/player_input_buffer.gd
scripts/player/player_input_snapshot.gd
scripts/player/locomotion/locomotion_state_machine.gd
scripts/player/locomotion/locomotion_motor.gd
scripts/player/locomotion/states/idle_state.gd
scripts/player/locomotion/states/run_state.gd
scripts/player/locomotion/states/crouch_state.gd
scripts/player/locomotion/states/crouch_move_state.gd
scripts/player/locomotion/states/jump_state.gd
scripts/player/locomotion/states/fall_state.gd
scripts/player/locomotion/states/double_jump_state.gd
scripts/player/locomotion/states/dash_state.gd
scripts/player/locomotion/states/crouch_dash_state.gd
scripts/player/locomotion/states/wall_slide_state.gd
scripts/player/locomotion/states/wall_jump_state.gd
scripts/player/locomotion/states/edge_idle_state.gd
scripts/player/locomotion/states/edge_climb_state.gd
scripts/player/locomotion/detectors/ground_detector.gd
scripts/player/locomotion/detectors/wall_detector.gd
scripts/player/locomotion/detectors/ledge_detector.gd
resources/characters/player_motion_profile.tres
scenes/player/player_test_actor.tscn
```

## 15. 相关测试文档

- 本模块的测试与验收已独立到 `docs/TestCase/p0a-character-locomotion.md`。
- 后续新增移动能力或调参回归时，应优先更新对应 `TestCase`，而不是继续膨胀本设计文档。

## 16. 下一步

- 文档层面，当前 `Locomotion` 已可作为 `P0-A` 的实现与验证基线。
- 后续若继续实现，应严格以 `docs/TestCase/p0a-character-locomotion.md` 作为验收入口。
- 若新增移动能力或调整规则，应先回写 `FeatureSpecs`、`ModuleDesign`、`TestCase` 三层文档，再进入代码阶段。
