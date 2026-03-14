# Abyss Respawn Test Case

## Purpose

- 本文是 `abyss-respawn` 当前版本的测试执行文档。
- `@Tester` 设计测试用例时，以上游需求文档为输入。
- `@Tester` 执行回归时，以本文为主。

## Inputs

- Requirement: `Docs/FeatureSpecs/AbyssRespawn.md`
- Handoff: `Docs/Workflow/Handoffs/abyss-respawn.md`
- Design reference: `Docs/ModuleDesign/AbyssRespawn.md`

## Scope

- 验证当前最小闭环：`SpecialTrapFailure -> LastSafeGround -> Checkpoint -> SceneStart`
- 验证当前最小闭环：`NormalDeath -> Checkpoint -> SceneStart`
- 验证当前已接通来源：
- 深渊：`DeathZoneTrigger`
- 未解锁水域：`CharacterContext.EnterWater()`
- 普通死亡：`CharacterStats.OnDeath -> RespawnManager`
- 验证当前最小恢复项：输入冻结/恢复、速度清零、水体状态清除、输入缓冲清空、安全地面态恢复

## Out Of Scope

- `BossEntry`
- `BossFailure`
- checkpoint 持久化
- 读档恢复完整链路
- 完整恢复矩阵
- 完整 anchor 合法性校验

## Developer Prerequisites

- 本轮测试场景生成器由 `@Developer` 维护，不由 `@Tester` 编写正式 editor tooling。
- `@Developer` 在回交测试前，需先修复 `Assets/Editor/TestSetup/P0A_TestSceneSetup.cs`。
- 必须移除对 `DeathZoneTrigger` 已删除字段的写入：`leftEdgeOffsetX`、`rightEdgeOffsetX`、`respawnY`。
- 必须按当前 respawn 语义重设深渊安全锚点，不能沿用旧版额外 Y 偏移思路。
- 必须显式创建并保留 `SceneStart`、`Checkpoint`、深渊测试段、锁定水域测试段。
- 必须提供未解锁游泳测试入口，不能让 `swimUnlocked = true` 默认遮蔽锁水主用例。
- 若继续保留 `safeRespawnPoints` 或 `respawnPoint`，需明确其是正式链路还是测试兼容数据。
- 回交时必须附带基于当前实现的新日志，不能继续使用旧版直传送日志作为闭环证据。

## Environment

- 优先复用菜单 `ProjectXII/Test/Setup P0-A Locomotion Scene`
- 禁止直接编辑 `.unity`、`.prefab`、`.asset`
- 如需调整测试环境，必须通过 C# editor tooling
- 必须遵守 `Assets/Editor/TestSetup/P0A_TestSceneSetup.cs` 顶部的净空与间距常量
- 执行前先检查最新日志目录 `D:/projects/ProjectXII/Logger/`

## Current Alignment

- 深渊已统一上报 `SpecialTrapFailure`：`Assets/Scripts/Core/Character/DeathZoneTrigger.cs`
- 未解锁水域已统一上报 `SpecialTrapFailure`：`Assets/Scripts/Core/Character/CharacterContext.cs`
- 普通死亡已统一进入 `RespawnManager`：`Assets/Scripts/Core/Character/Respawn/RespawnManager.cs`
- 当前最新日志 `Logger/P0A_Locomotion_Log_2026-03-11_21-39-07.txt` 仍表现为旧版深渊直接回位，因此缺少当前实现的动态验证证据

## Static Checks Completed

- 已阅读 handoff、feature、module design
- 已阅读当前最小闭环相关代码
- 已检查最新日志目录
- 已执行 `dotnet build "ProjectXII.sln"`

## Case Summary

| ID | Test Item | Status | Note |
| --- | --- | --- | --- |
| AR-01 | `LastSafeGround` 仅在安全地面态更新 | Pending | 代码已实现，待动态验证 |
| AR-02 | 深渊进入统一 `SpecialTrapFailure` | Pending | 代码已实现，待动态验证 |
| AR-03 | 未解锁水域进入统一 `SpecialTrapFailure` | Pending | 代码已实现，待动态验证 |
| AR-04 | `SpecialTrapFailure` 优先回 `LastSafeGround` | Pending | 代码已实现，待动态验证 |
| AR-05 | 无有效 `LastSafeGround` 时回退 `Checkpoint` | Pending | 代码已实现，待动态验证 |
| AR-06 | 无有效 `Checkpoint` 时回退 `SceneStart` | Pending | 代码已实现，待动态验证 |
| AR-07 | `NormalDeath` 统一调度回 `Checkpoint/SceneStart` | Pending | 代码已实现，待动态验证 |
| AR-08 | respawn 后最小恢复完成 | Pending | 代码已实现，待动态验证 |
| AR-09 | 无环境脚本直接正式回位遗漏路径 | Verified | 已完成静态排查 |
| AR-10 | 同帧竞争优先级正确 | Pending | 代码已实现，待动态验证 |

## Test Cases

### AR-01 LastSafeGround Recording

- Goal: 确认 `LastSafeGround` 只在安全地面态更新。
- Preconditions: 场景可覆盖平地、蹲行区、深渊前平台。
- Steps:
- 在 `Idle` 后触发深渊 respawn
- 在 `Run` 后触发深渊 respawn
- 在 `CrouchIdle` / `CrouchWalk` 后触发深渊 respawn
- 在跳跃、下落、冲刺、贴墙、入水后立即触发深渊 respawn
- Expected:
- 仅 `Idle/Run/CrouchIdle/CrouchWalk` 形成的新安全点会被采用
- 空中、冲刺、贴墙、水中不会刷新 `LastSafeGround`
- Code reference: `Assets/Scripts/Core/Character/Respawn/RespawnAnchorService.cs`
- Result type: 代码已实现，待动态验证

### AR-02 Abyss To SpecialTrapFailure

- Goal: 确认深渊不再直接传送，只提交统一请求。
- Preconditions: 场景包含 `DeathZoneTrigger`。
- Steps:
- 角色跌入深渊
- 观察日志与角色行为
- Expected:
- 日志体现统一调度，而不是环境脚本直接写位置
- 角色由 `RespawnManager` 执行扣血、淡入淡出、回位
- Code reference: `Assets/Scripts/Core/Character/DeathZoneTrigger.cs`, `Assets/Scripts/Core/Character/Respawn/RespawnManager.cs`
- Result type: 代码已实现，待动态验证；现有日志与实现不一致

### AR-03 Locked Water To SpecialTrapFailure

- Goal: 确认未解锁游泳时，入水与深渊走同一调度管线。
- Preconditions: 场景支持 `swimUnlocked = false`。
- Steps:
- 将角色设置为未解锁游泳
- 进入 `WaterZone`
- 观察日志、HP、回位点
- Expected:
- 提交 `SpecialTrapFailure`
- 扣除 `MoveData.waterDamagePenalty`
- 回位链优先按 `LastSafeGround` 解析
- Code reference: `Assets/Scripts/Core/Character/CharacterContext.cs`
- Result type: 代码已实现，但当前被测试场景默认配置阻塞

### AR-04 SpecialTrapFailure Prefers LastSafeGround

- Goal: 确认特殊陷阱失败优先服务快速重试点。
- Preconditions: 先形成有效 `LastSafeGround`。
- Steps:
- 在合法地面态记录安全点
- 落入深渊或未解锁水域
- 对比回位位置与最近安全点
- Expected:
- 优先回到最近记录的 `LastSafeGround`
- 不应优先跳到 `Checkpoint` 或 `SceneStart`
- Code reference: `Assets/Scripts/Core/Character/Respawn/RespawnAnchorService.cs:81`
- Result type: 代码已实现，待动态验证

### AR-05 Fallback To Checkpoint

- Goal: 确认 `LastSafeGround` 缺失时正确回退到 `Checkpoint`。
- Preconditions: 存在有效 `Checkpoint`；不存在有效 `LastSafeGround`。
- Steps:
- 进入场景后不形成合法安全点，直接触发特殊陷阱失败
- 或通过测试辅助方式清空 `LastSafeGround` 后再触发
- Expected:
- 回位到有效 `Checkpoint`
- Code reference: `Assets/Scripts/Core/Character/Respawn/RespawnAnchorService.cs:96`
- Result type: 代码已实现，待动态验证

### AR-06 Fallback To SceneStart

- Goal: 确认 `Checkpoint` 缺失时最终兜底链可工作。
- Preconditions: 存在有效 `SceneStart`；不存在可用 `Checkpoint`。
- Steps:
- 触发 `SpecialTrapFailure`
- 触发 `NormalDeath`
- Expected:
- 两条链都回退到 `SceneStart`
- Code reference: `Assets/Scripts/Core/Character/Respawn/RespawnAnchorService.cs:38`
- Result type: 代码已实现，待动态验证

### AR-07 NormalDeath Unified Dispatch

- Goal: 确认普通死亡不再自行决定落点。
- Preconditions: 角色可被伤害至 0 HP。
- Steps:
- 通过伤害将角色 HP 降至 0
- 观察请求来源、回退链与恢复结果
- Expected:
- `CharacterStats.OnDeath` 被 `RespawnManager` 捕获并转成 `NormalDeath`
- 优先回 `Checkpoint`，无 checkpoint 时回 `SceneStart`
- Code reference: `Assets/Scripts/Core/Character/CharacterStats.cs`, `Assets/Scripts/Core/Character/Respawn/RespawnManager.cs`
- Result type: 代码已实现，待动态验证

### AR-08 Minimal Recovery

- Goal: 确认当前版本要求的最小恢复项已执行。
- Preconditions: 可分别触发 `SpecialTrapFailure` 与 `NormalDeath`。
- Steps:
- 在输入缓存残留跳跃/冲刺请求时触发 respawn
- 在存在速度、水体状态、蹲下碰撞体状态时触发 respawn
- respawn 完成后检查状态
- Expected:
- 输入在 respawn 期间冻结，结束后恢复
- `Velocity` 清零
- `CurrentWater` 清空
- 输入缓冲清空
- 状态机强制回 `Idle` 或 `CrouchIdle`
- `SpecialTrapFailure` 不自动满血；非 `SpecialTrapFailure` 来源会重置 HP
- Code reference: `Assets/Scripts/Core/Character/CharacterContext.cs`
- Result type: 代码已实现，待动态验证

### AR-09 Direct Teleport Path Audit

- Goal: 确认当前已接通环境脚本没有绕开统一调度。
- Method: 检索 `transform.position =`、`QueueTeleport`、respawn 提交入口。
- Expected:
- 深渊与锁水路径都通过 `RespawnManager`
- 不存在环境 hazard 脚本直接正式回位的遗漏路径
- Result type: 静态排查已通过；`CharacterEdgeGrabState` 直接改位置，但不属于 respawn 路径

### AR-10 Same-Frame Priority

- Goal: 确认 `SpecialTrapFailure` 与 `NormalDeath` 竞争时优先级正确。
- Preconditions: 可构造“深渊伤害导致 0 HP”的场景。
- Steps:
- 在低 HP 下进入深渊
- 分别测试 `forcesRespawnEvenOnZeroHp = true/false`
- 观察最终采用的请求来源
- Expected:
- `true` 时保留 `SpecialTrapFailure` 快速回位语义
- `false` 时升级为 `NormalDeath`
- Code reference: `Assets/Scripts/Core/Character/Respawn/RespawnManager.cs:171`
- Result type: 代码已实现，待动态验证

## Additional Suggested Cases

- AR-11 respawn 序列处理中再次触发 hazard，请求是否被吞掉或错误覆盖
- AR-12 `Checkpoint` 重复触发时是否稳定覆盖最近 checkpoint
- AR-13 `SceneStart` 缺失时是否输出明确错误日志
- AR-14 特殊陷阱显式 fallback anchor 与正式 `Checkpoint` 的优先级是否符合当前版本口径
- AR-15 回位后朝向是否正确应用 `FacingHint`

## Defects And Risks

- 代码已实现但待验证：`AR-01`、`AR-02`、`AR-03`、`AR-04`、`AR-05`、`AR-06`、`AR-07`、`AR-08`、`AR-10`
- 代码已实现并已静态验证：`AR-09`
- 测试阻塞：`Assets/Editor/TestSetup/P0A_TestSceneSetup.cs` 仍写入 `DeathZoneTrigger` 已删除字段
- 测试阻塞：测试场景默认 `swimUnlocked = true`，锁水主链不可执行
- 文档与实现不一致：最新日志仍是旧版深渊直接回位
- 已知未闭环项：完整 anchor 合法性校验与完整恢复矩阵，不计入本轮回归失败

## Handoff Back To Developer

- 先修复测试场景生成器，再回交 `@Tester`
- 回交时至少提供覆盖 `AR-02`、`AR-03`、`AR-05`、`AR-06`、`AR-07`、`AR-08`、`AR-10` 的一轮新日志
- 若实现边界发生变化，先更新本文，再进入下一轮测试

## Regression Result

- 本轮已重新执行 batch smoke 验证，统一 respawn 最小闭环通过。
- 本轮实际验证范围：`AR-04`、`AR-03`、`AR-05`、`AR-06`、`AR-07`。
- 当前无新增 blocker。

## Execution Record

- 执行命令：`"D:\Unity\Hub\Editor\2022.3.62f3\Editor\Unity.exe" -batchmode -projectPath "D:\projects\ProjectXII" -executeMethod ProjectXII.Editor.TestSetup.P0A_RespawnSmokeValidation.RunBatchValidation -logFile "D:\projects\ProjectXII\Logger\Unity_Batch_RespawnSmoke.log"`
- batch 日志：`D:\projects\ProjectXII\Logger\Unity_Batch_RespawnSmoke.log`
- 最新运行日志：`D:\projects\ProjectXII\Logger\P0A_Locomotion_Log_2026-03-13_14-00-28.txt`

## Latest Case Results

| ID | Test Item | Result | Evidence |
| --- | --- | --- | --- |
| AR-04 | `LastSafeGround` | PASS | `D:\projects\ProjectXII\Logger\P0A_Locomotion_Log_2026-03-13_14-00-28.txt:849` |
| AR-03 | `LockedWater` | PASS | `D:\projects\ProjectXII\Logger\P0A_Locomotion_Log_2026-03-13_14-00-28.txt:1653` |
| AR-05 | `CheckpointFallback` | PASS | `D:\projects\ProjectXII\Logger\P0A_Locomotion_Log_2026-03-13_14-00-28.txt:1983` |
| AR-06 | `SceneStartFallback` | PASS | `D:\projects\ProjectXII\Logger\P0A_Locomotion_Log_2026-03-13_14-00-28.txt:2029` |
| AR-07 | `NormalDeath` | PASS | `D:\projects\ProjectXII\Logger\P0A_Locomotion_Log_2026-03-13_14-00-28.txt:2844` |

- smoke 总结：`D:\projects\ProjectXII\Logger\P0A_Locomotion_Log_2026-03-13_14-00-28.txt:2850`

## Regression Conclusion

- `SpecialTrapFailure -> LastSafeGround -> Checkpoint -> SceneStart`：PASS
- `NormalDeath -> Checkpoint -> SceneStart`：PASS
- 当前 smoke 覆盖范围内未发现新的功能失败。
- 当前不需要因本轮验证结果回流 `@Developer`。
