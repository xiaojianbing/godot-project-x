# P0B Combat Foundation Test Case

## Purpose

- 本文是 `P0-B Combat Foundation` 的测试执行文档。
- `FeatureSpecs` 定义战斗目标，`ModuleDesign` 定义系统边界，本文定义本阶段如何验收。

## Inputs

- Requirement: `docs/FeatureSpecs/CombatFoundation.md`
- Requirement: `docs/FeatureSpecs/CorePriority.md`
- Design reference: `docs/ModuleDesign/CombatFoundation.md`
- Related design: `docs/ModuleDesign/CharacterFeature.md`
- Related design: `docs/ModuleDesign/Locomotion.md`

## Scope

- 验证基础攻击、受击、防御、地面弹反、空中弹反的最小闭环。
- 验证普通受击、普通防御、精确弹反三种结果是否清晰区分。
- 验证弹反成功时的无敌帧、敌人硬直、空中回弹收益。
- 本文不负责验收完整 `HitStop`、镜头震动或统一战斗特效表现。

## Out Of Scope

- 完整轻重派生连招。
- 复杂敌人 AI 或 Boss 战。
- 完整处决和大招系统。
- 完整 `HitStop`、镜头震动与统一战斗 VFX。

## Test Environment

- 使用 `Godot 4` 战斗测试房。
- 至少需要：Player、基础敌人 Dummy、可配置攻击碰撞、基础 HUD。
- 测试房统一放在 `scenes/testrooms/` 或后续独立战斗测试目录中。
- 测试房构建规则：每个房间宽度默认按 `800` 组织，每个房间只承载一个测试主题。
- 当前测试房为四个横向隔间，每个隔间默认按宽 `800` 组织，并由墙体隔离。
- 四个隔间依次用于：射击、近战、双发连锁弹反、高位空中弹反。

## Status Legend

- `Covered`：代码、场景与调试路径已落地，具备执行条件，但尚未做完整人工实机验收。
- `Pending`：仍缺实现或缺对应测试路径。

## Case Summary

| ID | Test Item | Status | Note |
| --- | --- | --- | --- |
| CB-01 | Light Attack Baseline | Covered | 玩家轻攻击框与命中路径已落地，待实机确认挥空/命中差异 |
| CB-02 | Heavy Attack Baseline | Covered | 玩家重攻击框颜色已区分，待实机确认节奏差异 |
| CB-03 | Shoot Baseline | Covered | 按住瞄准与松开发射链路已落地，待实机确认方向与命中 |
| CB-04 | Hurt Baseline | Covered | 受击掉血、击退与短暂无敌已接入，待实机确认 |
| CB-05 | Guard Baseline | Covered | 正面防御减伤与防御框已接入，待实机确认 |
| CB-06 | Ground Parry | Covered | 近战敌人与地面验证层已准备好，待实机确认敌人硬直 |
| CB-07 | Air Parry | Covered | 高位单发机关与回弹逻辑已接入，待实机确认 |
| CB-08 | Parry Invincibility | Covered | 连锁子弹层可用于验证弹反后无敌窗口，待实机确认 |
| CB-09 | Projectile Parry | Covered | 射击敌人与双机关层均可验证反射与归属切换 |
| CB-10 | Directional Defense | Covered | 玩家与敌人朝向框已落地，正反面规则待实机确认 |
| CB-11 | Result Priority | Covered | 结果分支代码已集中收口，待实机逐项走查 |

## Test Cases

### CB-01 Light Attack Baseline

- Goal: 验证轻攻击的挥空与命中差异。
- Steps:
- 使用手柄 `X` 触发轻攻击，分别攻击空气与 Dummy。
- Expected:
- 玩家能清楚区分轻攻击挥空与命中反馈。
- 轻攻击框显示为玩家侧亮绿色，并与重攻击框颜色明显不同。

### CB-02 Heavy Attack Baseline

- Goal: 验证重攻击的最小闭环。
- Steps:
- 使用手柄 `Y` 触发重攻击，分别攻击空气与 Dummy。
- Expected:
- 重攻击可正常触发，并与轻攻击有清晰节奏差异。
- 重攻击框显示为玩家侧偏青绿色，并与轻攻击颜色明显不同。

### CB-03 Shoot Baseline

- Goal: 验证射击作为独立输出动作存在。
- Steps:
- 按住手柄 `B` 进入瞄准态。
- 在按住期间推动左摇杆，分别朝水平、斜上、斜下和竖直方向瞄准。
- 松开 `B` 发射。
- 观察是否有独立远程结果链。
- Expected:
- `Shoot` 作为独立输入存在，不与近战键复用。
- 射击命中或飞行结果可被稳定观察。
- 按住 `Shoot` 时玩家进入瞄准态并暂时失去普通移动控制。
- 松开 `Shoot` 后按当前瞄准方向发射，不局限于固定水平发射。
- 瞄准线会稳定跟随当前方向变化，不应出现明显跳角、离散卡位或与最终发射方向不一致。
- 玩家主动射出的子弹应使用玩家侧颜色，而不是沿用敌方子弹颜色。

### CB-04 Hurt Baseline

- Goal: 验证普通受击结果。
- Steps:
- 不防御时让 Dummy 命中 Player。
- Expected:
- Player 正常掉血，进入受击反馈，并获得短暂无敌帧。

### CB-05 Guard Baseline

- Goal: 验证普通防御结果。
- Steps:
- 使用 `RShoulder`，在非精确窗口下提前举防御并承受攻击。
- Expected:
- Player 仅轻微掉血或承担轻微代价。
- 结果明显弱于 `Parry`，但优于普通受击。

### CB-06 Ground Parry

- Goal: 验证地面弹反成功结果。
- Steps:
- 在地面命中前极短时间按下 `RShoulder` 并承受攻击。
- Expected:
- Player 不掉血。
- 敌人进入清晰硬直。
- 结果明显强于普通 `Guard`。

### CB-07 Air Parry

- Goal: 验证空中弹反成功结果。
- Steps:
- 空中命中前极短时间按下 `RShoulder` 并承受攻击。
- Expected:
- Player 不掉血。
- Player 获得明确向上回弹或延空收益。

### CB-08 Parry Invincibility

- Goal: 验证弹反成功后的无敌帧稳定性。
- Steps:
- 让连续命中判定在弹反成功后继续覆盖 Player。
- Expected:
- 弹反成功后短时间内不会被后续同段攻击再次命中。

### CB-09 Projectile Parry

- Goal: 验证可弹反飞行物能被反射回敌人。
- Steps:
- 让敌人或测试发射器发出可弹反子弹。
- 在正确时机按下 `RShoulder`，触发 `Ground Parry` 或 `Air Parry`。
- 额外验证两枚子弹近乎同时抵达玩家正面时，是否都会被连锁弹反。
- 观察飞行物是否改变方向与伤害归属，并命中敌方目标。
- Expected:
- Player 不掉血。
- 飞行物明显反向飞回，而不是原地消失或继续按原方向飞行。
- 命中敌人后按玩家侧攻击结果结算。
- 若多枚子弹在首次 `Projectile Parry` 的短窗口内连续压到玩家正面，其余子弹也会一起被弹回。
- 成功弹反时应有明显但轻量的成功提示，至少能让测试者肉眼判断这次确实触发了 `Projectile Parry`。
- 被弹反后的飞行物应切换为玩家侧颜色，方便与敌方原始飞行物区分。

### CB-10 Directional Defense

- Goal: 验证 `Guard / Parry` 仅对正面攻击有效。
- Steps:
- 面向敌人，使用 `RShoulder` 承受正面攻击。
- 背对敌人，使用 `RShoulder` 承受背后攻击。
- Expected:
- 正面攻击可按设计进入 `Guard` 或 `Parry`。
- 背后攻击不会错误进入 `Guard` 或 `Parry`，而是按普通受击处理。

### CB-11 Result Priority

- Goal: 验证 `Hurt`、`Guard`、`Ground Parry`、`Air Parry` 的优先级正确。
- Steps:
- 分别在普通站立、防御、地面精确窗口、空中精确窗口中承受同类攻击。
- Expected:
- 系统按设计落入正确结果分支，不出现互抢或错误降级。

## Exit Criteria

- 普通受击、普通防御、地面弹反、空中弹反四类结果清晰可区分。
- `Ground Parry` 成功后敌人硬直可稳定复现。
- `Air Parry` 成功后玩家向上回弹可稳定复现。
- `Projectile Parry` 成功后飞行物可稳定反射回敌方。
- `Shoot` 的瞄准态、瞄准线与松开发射逻辑可稳定复现。
- 玩家侧与敌方飞行物颜色可稳定区分。
- 弹反无敌帧可稳定拦截后续连续命中。
