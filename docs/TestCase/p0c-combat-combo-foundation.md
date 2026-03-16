# P0C Combat Combo Foundation Test Case

## Purpose

- 本文是 `P0-C Combat Combo Foundation` 的测试执行文档。
- `FeatureSpecs` 定义连招目标，`ModuleDesign` 定义系统边界，本文定义本阶段如何验收。

## Inputs

- Requirement: `docs/FeatureSpecs/CombatComboFoundation.md`
- Requirement: `docs/FeatureSpecs/CorePriority.md`
- Design reference: `docs/ModuleDesign/CombatComboFoundation.md`
- Related design: `docs/ModuleDesign/CombatFoundation.md`
- Related design: `docs/ModuleDesign/Locomotion.md`

## Scope

- 验证三条核心原型连招的最小闭环。
- 验证普通 `Heavy` 与连招派生 `Heavy` 的区分。
- 验证倒地、挑飞、空中追敌三类收益是否明确可见。
- 验证 `Reload` 与 `Grapple Chase` 是否以连招语义接入。

## Out Of Scope

- 完整 Style Rank。
- 全量取消技与所有连招树分支。
- 完整枪械系统与完整 Boss 连段规则。

## Test Environment

- 使用 `Godot 4` 专用连招测试房。
- 至少需要：Player、小体型敌人、大体型敌人、霸体敌人、空中追击测试目标、连招调试 HUD。
- 测试房继续遵守：每个房间宽 `800`、每个房间只验证一个主题。

## Status Legend

- `Covered`：设计、代码或测试路径已落地，但尚未做完整人工实机验收。
- `Pending`：仍缺实现或缺对应测试路径。

## Case Summary

| ID | Test Item | Status | Note |
| --- | --- | --- | --- |
| CC-01 | Knockdown String Baseline | Covered | 已接入 `Light -> Light -> Heavy` 地面终结链 |
| CC-02 | Heavy Branch Separation | Covered | 普通 `Heavy`、倒地终结 `Heavy`、挑飞 `Heavy` 已分流 |
| CC-03 | Knockdown Target Categories | Covered | 已接入小体型 / 大体型 / 霸体最小反应分层 |
| CC-04 | Launcher Gun Dump Baseline | Covered | 已接入三轻起手、挑飞与双射追打基础链 |
| CC-05 | Reload Consequence | Covered | 第二次追射后进入最小 `Reload` 锁 |
| CC-06 | Air Chase Grapple Baseline | Covered | 已接入空中终结追击点与 `Grapple Chase` 最小闭环 |
| CC-07 | Follow-up Window Timing | Covered | 地面终结与双射跟进窗口已接入 |
| CC-08 | Hit Confirm Rules | Covered | 高收益派生与第二段追射均要求命中确认 |
| CC-09 | Combo Runtime Debug | Covered | HUD 已显示连招、分支、追射与 `Reload` 状态 |

## Test Cases

### CC-01 Knockdown String Baseline

- Goal: 验证 `Light -> Light -> Heavy` 的地面终结闭环。
- Steps:
- 对小体型目标执行 `Light -> Light -> Heavy`。
- Expected:
- 第三段进入连招派生终结，而不是普通 `Heavy`。
- 目标出现明显倒地或砸地结果。

### CC-02 Heavy Branch Separation

- Goal: 验证普通 `Heavy` 与连招 `Heavy` 派生可被区分。
- Steps:
- 单独输入 `Heavy`。
- 再执行有效轻攻击起手后输入 `Heavy`。
- Expected:
- 两种 `Heavy` 在节奏、动作或结果上明显不同。

### CC-03 Knockdown Target Categories

- Goal: 验证不同目标类型对地面终结的反应分层。
- Steps:
- 分别对小体型、大体型、霸体目标执行 `Knockdown String`。
- Expected:
- 小体型目标倒地。
- 大体型非霸体目标至少产生重硬直。
- 霸体目标不应错误倒地。

### CC-04 Launcher Gun Dump Baseline

- Goal: 验证 `Light -> Light -> Light -> Heavy -> Shoot -> Shoot`。
- Steps:
- 对可挑飞目标完整执行该连招。
- Expected:
- `Heavy` 把目标垂直挑飞。
- 后续两次 `Shoot` 能稳定追打空中目标。

### CC-05 Reload Consequence

- Goal: 验证枪械追打结束后的资源后果。
- Steps:
- 完整执行第二条连招并观察结束状态。
- Expected:
- 手枪进入 `Reload`。
- 不应继续无代价无限追射。

### CC-06 Air Chase Grapple Baseline

- Goal: 验证空中 `Light -> Light -> Light -> Heavy -> Grapple`。
- Steps:
- 在空中完成前三段轻攻击与空中 `Heavy`。
- 在有效窗口内触发 `Grapple`。
- Expected:
- 玩家被快速拉向被击飞敌人附近或追击点。
- 位移收益清晰，不应只是普通地形钩索重放。

### CC-07 Follow-up Window Timing

- Goal: 验证连招跟进窗口。
- Steps:
- 分别提早、正确、过晚输入 `Shoot` 或 `Grapple`。
- Expected:
- 只有正确窗口进入后续追打。
- 过早或过晚输入不会错误进入完整派生。

### CC-08 Hit Confirm Rules

- Goal: 验证高收益派生需要命中确认。
- Steps:
- 让前段攻击挥空，再尝试接终结或追打。
- Expected:
- 系统应阻止或降级高收益派生。

### CC-09 Combo Runtime Debug

- Goal: 验证连招运行时状态可调试。
- Steps:
- 执行三条连招并观察 HUD。
- Expected:
- 能看到当前连招 ID、步骤 ID、命中确认、跟进窗口、`Reload` 与追敌目标状态。

## Exit Criteria

- 三条核心原型连招都能稳定复现。
- 普通 `Heavy` 与派生 `Heavy` 的区分清晰。
- 倒地、挑飞、空中追敌三种收益都清楚可见。
- `Reload` 和 `Grapple Chase` 已作为连招结果链的一部分稳定接入。
- 系统具备继续增加新连招而不重写整体结构的基础。
