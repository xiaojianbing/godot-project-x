# P0A Locomotion Test Case

## Purpose

- 本文是 `P0A Locomotion` 的测试执行文档。
- `ModuleDesign` 负责说明系统如何设计；本文负责说明该系统如何验证。

## Inputs

- Requirement: `docs/FeatureSpecs/CorePriority.md`
- Requirement: `docs/FeatureSpecs/CharacterFeature.md`
- Design reference: `docs/ModuleDesign/CharacterFeature.md`
- Design reference: `docs/ModuleDesign/Locomotion.md`

## Scope

- 验证地面移动、下蹲/蹲行/蹲冲、起跳、二段跳、下落、转向、墙滑、墙跳、边缘挂停、边缘攀爬的最小闭环。
- 验证 `Coyote Time`、`Jump Buffer`、`Corner Correction` 的可用性与稳定性。
- 验证 `Swim` 的状态入口、锁水边界、水中控制基线与出水切换规则。
- 验证 `Grapple` 的钩点锁定、拉拽释放与未解锁失败反馈。
- 验证移动系统与 `CharacterStats`、`CharacterSignals`、`CharacterContext` 的基本联动边界。
- 验证本阶段移动系统是否达到“丝滑操控”的最低标准。

## Out Of Scope

- 完整攻击系统与连招系统。
- 复杂敌人 AI、Boss 机制与房间战斗设计。
- 存档、地图、剧情、完整能力解锁链路。

## Test Environment

- 使用 `Godot 4` 灰盒测试场景。
- 测试房统一放在 `scenes/testrooms/`，不要与 `scenes/levels/` 正式关卡目录混放。
- 测试场景应至少包含：平地、短平台、长平台、单墙、双墙、低矮通道、深坑、边缘挂停与翻越段、浅水区、深水区、至少一组固定钩点与对应落点。
- 推荐单独建立 `P0A` 测试房，不要把移动验证散落到正式关卡里。

## Case Summary

> Status 说明：
> - `Covered`：代码与结构约束已经明确覆盖，可通过静态检查确认。
> - `Passed`：实现、测试房和主观 playtest 已完成，本阶段签收通过。

| ID | Test Item | Status | Note |
| --- | --- | --- | --- |
| LC-01 | Ground Move Responsiveness | Passed | 起停与转向通过测试房实机验收 |
| LC-02 | Jump Height Control | Passed | 短跳/长跳差异通过实机验收 |
| LC-03 | Coyote Time | Passed | 土狼时间窗口通过边界验收 |
| LC-04 | Jump Buffer | Passed | 跳跃缓存通过落地瞬跳验收 |
| LC-05 | Fall Consistency | Passed | 上升/下落手感通过验收 |
| LC-06 | Dash Consistency | Passed | 地面/空中冲刺节奏通过验收 |
| LC-07 | Wall Slide | Passed | 墙滑速度与稳定性通过验收 |
| LC-08 | Wall Jump | Passed | 推出力与输入锁通过验收 |
| LC-09 | Edge Climb | Passed | 抓边与翻越闭环通过验收 |
| LC-10 | Corner Correction | Passed | 边角修正通过验收 |
| LC-11 | Crouch Family | Passed | 下蹲、蹲行、蹲冲与低矮通道通过验收 |
| LC-12 | Double Jump | Passed | 二段跳与解锁开关通过验收 |
| LC-13 | Edge Idle Input Rules | Passed | 挂边输入分支通过验收 |
| LC-14 | State Priority | Passed | 关键状态优先级通过验收 |
| LC-15 | Character Foundation Integration | Covered | `CharacterContext` / `stats` / `signals` 已稳定接线 |
| LC-16 | Swim Baseline | Passed | 水中移动与出水逻辑通过验收 |
| LC-17 | Swim Locked Boundary | Passed | 锁水反馈与测试区通过验收 |
| LC-18 | Grapple Baseline | Passed | 固定钩点、拉拽、穿点减速通过验收 |
| LC-19 | Grapple Locked Boundary | Passed | 锁定钩索失败路径与测试区通过验收 |

## Test Cases

### LC-01 Ground Move Responsiveness

- Goal: 验证地面移动起步、刹车、转向是否干脆。
- Steps:
- 在平地上从静止到全速移动。
- 高速反向输入，观察转向与减速。
- 松开输入，观察停下过程。
- Expected:
- 起步迅速，无明显迟滞。
- 转向稳定，不出现异常滑行。
- 停止时不会过度打滑，也不会突兀吸附。

### LC-02 Jump Height Control

- Goal: 验证可变跳跃高度是否稳定。
- Steps:
- 短按跳跃。
- 长按跳跃。
- 多次重复，观察高度差异。
- Expected:
- 短跳与长跳存在清晰可重复的高度差。
- 同条件多次操作结果稳定。

### LC-03 Coyote Time

- Goal: 验证离地后的补跳宽容窗口。
- Steps:
- 角色从平台边缘自然跑出。
- 在离台后极短时间内按跳跃。
- Expected:
- 在窗口内能成功补跳。
- 超过窗口后必须失败，边界清晰。

### LC-04 Jump Buffer

- Goal: 验证落地前提前按跳可触发落地瞬跳。
- Steps:
- 从高处下落。
- 落地前短时间按下跳跃。
- Expected:
- 角色落地后立即起跳。
- 同一跳跃请求不会被重复消费。

### LC-05 Fall Consistency

- Goal: 验证上升与下落手感差异是否合理。
- Steps:
- 连续执行跳跃并观察上升/下落速度。
- Expected:
- 下落比上升更干脆。
- 落地衔接自然，不抖动。

### LC-06 Dash Consistency

- Goal: 验证冲刺动作的启动、持续和收尾。
- Steps:
- 地面冲刺。
- 空中冲刺。
- 冲刺结束后立刻接移动输入。
- Expected:
- 冲刺是短、快、明确的位移。
- 收尾可控，不会突然卡停或异常漂移。

### LC-07 Wall Slide

- Goal: 验证贴墙下滑是否受控。
- Steps:
- 跳向墙面并持续贴墙。
- Expected:
- 角色进入稳定缓降，而非无限悬停或自由落体。

### LC-08 Wall Jump

- Goal: 验证墙跳推出力与输入锁定是否清晰。
- Steps:
- 贴墙后执行墙跳。
- 观察角色推出距离与重新接管控制的时机。
- Expected:
- 墙跳有明显横向推出。
- 不会立即吸回原墙。
- 玩家能感知到短暂锁定窗口。

### LC-09 Edge Climb

- Goal: 验证抓边与翻越闭环。
- Steps:
- 在可抓边平台边缘尝试挂边。
- 再执行翻越。
- Expected:
- 只有在满足前方有边且头顶空间足够时才触发。
- 抓边与翻越过程稳定，不闪烁。

### LC-11 Crouch Family

- Goal: 验证 `Crouch`、`CrouchMove`、`CrouchDash` 是否具备独立用途。
- Steps:
- 在平地进入下蹲。
- 在低矮通道中做蹲行。
- 从下蹲状态触发蹲冲。
- Expected:
- 下蹲后碰撞体缩小，角色能通过低矮通道。
- 蹲行速度慢于正常移动但依旧可控。
- 蹲冲与普通冲刺在姿态和用途上有清晰差别。

### LC-12 Double Jump

- Goal: 验证空中二次起跳是否稳定。
- Steps:
- 地面起跳后在空中再次按跳跃。
- 再尝试第三次空中跳跃。
- Expected:
- 第二次跳跃成功并重置竖直速度。
- 超出次数后必须失败，边界清楚。

### LC-13 Edge Idle Input Rules

- Goal: 验证 `EdgeIdle` 及其输入分支。
- Steps:
- 让角色挂到平台边缘进入 `EdgeIdle`。
- 分别按 `down`、按“后”、按 `jump`、按 `up`。
- Expected:
- `down`：进入下滑或松手下落，行为符合最终规则。
- “后”：角色松手进入 `Fall`。
- `jump`：角色执行 `WallJump`。
- `up`：角色进入 `EdgeClimb`，先上移再小段横移并站上平台。

### LC-10 Corner Correction

- Goal: 验证边角修正是否提升稳定性而不显得作弊。
- Steps:
- 让角色在上升时轻微擦到平台边角。
- Expected:
- 角色允许少量水平修正并成功越过边角。
- 修正幅度小且稳定，不出现明显吸附。

### LC-14 State Priority

- Goal: 验证 `Idle`、`Run`、`Jump`、`Fall`、`Dash`、`WallSlide`、`WallJump`、`EdgeClimb` 切换优先级。
- Steps:
- 在可复现环境中触发边界操作，如冲刺结束接跳跃、贴墙接墙跳、下落接抓边。
- Expected:
- 状态切换符合设计文档，不出现明显互抢或抖动。

### LC-15 Character Foundation Integration

- Goal: 验证移动系统与基础属性层边界正确。
- Steps:
- 检查移动系统是否通过 `CharacterContext` 访问 `stats`、`signals`、`motion_profile`。
- 检查移动系统是否只读取运动倍率，而不直接承担属性结算。
- Expected:
- `CharacterStats` 负责属性值，locomotion 不重复维护数值真相。
- `CharacterSignals` 能正确反映 `is_grounded`、`facing_direction`、`current_action_tag` 等运行时信息。

### LC-16 Swim Baseline

- Goal: 验证 `Swim` 的进入、控制和退出基线是否稳定。
- Steps:
- 进入已解锁游泳的深水区。
- 在水中分别执行水平移动、上浮、下潜、停止输入。
- 从水面边缘或上方离开水体。
- Expected:
- 入水后状态切换稳定，不与普通 `Jump` / `Fall` 反复争抢。
- 水中水平/竖直移动明显慢于地面，且控制方向清晰。
- 停止输入后角色按设计表现轻微上浮或缓慢下沉，结果可重复。
- 出水后能平滑回到 `Idle` / `Run` / `Fall`，不残留异常水中速度。

### LC-17 Swim Locked Boundary

- Goal: 验证未解锁游泳时的锁水边界与失败反馈。
- Steps:
- 将角色设置为 `swim_unlocked = false`。
- 进入深水区。
- 观察状态、失败原因输出以及是否进入 `AbyssRespawn` 或其他锁水处理。
- Expected:
- 角色不会错误进入 `Swim` 状态。
- HUD 或日志能看到明确失败原因，例如“未解锁游泳”。
- 深水处理结果与 `docs/TestCase/abyss-respawn.md` 的预期保持一致。

### LC-18 Grapple Baseline

- Goal: 验证 `Grapple` 的锁点、拉拽与释放是否稳定。
- Steps:
- 将角色置于空中，并确保前方或斜上方存在合法固定钩点。
- 按下 `grapple` 输入。
- 观察角色是否锁定钩点并被快速拉向目标。
- 观察角色是否先被带动、再逐步加速拉近钩点。
- 到达目标点后观察角色是否穿过钩点，并在短暂减速后自然回到 `Fall` 或衔接后续空中动作。
- Expected:
- 只有合法钩点会被锁定，不会误抓普通墙面或无效对象。
- 拉拽轨迹稳定，能明确感知“先被带住、后明显提速”的位移反馈。
- 穿点后角色不会在钩点处瞬停，而是保留惯性并在短时间内快速减速。
- 释放后角色不会卡在 `Grapple` 状态，也不会残留异常速度。

### LC-19 Grapple Locked Boundary

- Goal: 验证未解锁钩索时的失败边界与反馈。
- Steps:
- 将角色设置为 `grapple_unlocked = false`。
- 在合法钩点附近空中按下 `grapple`。
- 观察状态与失败原因输出。
- Expected:
- 角色不会错误进入 `Grapple` 状态。
- HUD 或日志能看到明确失败原因，例如“未解锁钩索”或“当前无权限使用”。
- 失败后角色继续保持原本空中态，不出现位置抖动或异常中断。

## Exit Criteria

- 核心移动逻辑统一在 `_physics_process()`。
- `move_and_slide()` 是唯一主移动提交点。
- 输入缓冲、土狼时间、边角修正均可独立开关与调参。
- 墙跳、冲刺、抓边可重复复现，具备稳定主观手感。
- 下蹲、蹲行、蹲冲、二段跳、边缘挂停与翻越具备明确输入反馈和状态边界。
- `Swim` 的入水、出水、锁水反馈与状态切换边界可重复复现。
- `Grapple` 的锁点、拉拽、释放和未解锁失败反馈可重复复现。
- 玩家主观上不会频繁怀疑输入丢失或状态切换异常。

## Current Conclusion

- 代码、测试房、调试 HUD、能力开关与 `LC-01 ~ LC-19` 的场景入口已经基本齐备。
- `LC-15 Character Foundation Integration` 可通过静态检查确认已经覆盖。
- 除 `LC-15 Character Foundation Integration` 以 `Covered` 记录外，其余条目已在 `scenes/testrooms/player_test_room.tscn` 中完成本轮 playtest 验收并签收通过。
- 本轮收口结论为：`Locomotion` 已达到当前阶段可交付标准，可作为后续战斗模块与关卡能力门设计的稳定基础。
