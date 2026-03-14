# 技术设计文档：Abyss Respawn

> **@Architect 产出** | 依据 Feature Spec: `Docs/FeatureSpecs/AbyssRespawn.md`

---

## 1. 架构目标

- 在不破坏现有 HFSM、`Rigidbody2D (Kinematic)`、`FixedUpdate` + `MovePosition` 约束的前提下，为五类重生来源建立统一判定框架。
- 让 `特殊陷阱失败` 保持类似 `Celeste` 的快速重试节奏，同时让 `Boss 失败`、`普通战死`、`加载游戏` 仍走各自独立的恢复语义。
- 用统一的 `RespawnSource` + `RespawnAnchor` 心智模型取代当前仅有的 `DeathZoneTrigger + LastSafePosition` 局部方案。
- 将“来源判定”“锚点选择”“状态恢复”“反馈时序”分层，避免未来 Boss、存档点、房间和相机逻辑互相耦合。

## 2. 已确认决策 vs 本文补充

### 2.1 已确认决策

- 重生来源共五类：`InitialSpawn`、`SpecialTrapFailure`、`BossFailure`、`LoadGame`、`NormalDeath`。
- `深渊坠落` 属于 `特殊陷阱失败`。
- 仅 `特殊陷阱失败` 扣血，且伤害按陷阱类型配置。
- Boss 失败优先回 Boss 战前置点，否则回最近存档点。
- 首版只要求 `深渊` 接入 `特殊陷阱`；其他特殊陷阱保留扩展口。

### 2.2 本文新增设计结论

- 引入统一运行时判定单元：`RespawnRequest`，所有回位触发都先转成请求，再进入统一仲裁。
- 引入统一锚点抽象：`RespawnAnchor`，按类型区分 `LastSafeGround`、`BossEntry`、`Checkpoint`、`SceneStart`。
- `特殊陷阱失败` 与未解锁水域惩罚共用同一条回位管线；差异只体现在 `HazardDefinition` 配置。
- 重生不等于“通用死亡流程”；统一的是调度框架，不统一的是来源语义、目标锚点和恢复模板。

## 3. 系统总览

### 3.1 分层职责

1. `RespawnSource Layer`
   - 负责把深渊、普通死亡、Boss 失败、读档、初始进入等事件转成 `RespawnRequest`。
2. `RespawnResolver Layer`
   - 负责同帧冲突仲裁、锚点选择、回退链、有效性校验。
3. `RespawnExecution Layer`
   - 负责锁输入、打断状态、播放反馈、重置角色状态、落点恢复和重新放权。
4. `Anchor Recording Layer`
   - 负责维护 `LastSafeGround`、当前有效 `Checkpoint`、Boss 前置点等缓存。

### 3.2 推荐模块拆分

| 模块 | 责任 | 风险 |
| --- | --- | --- |
| `RespawnManager` | 接收请求、仲裁、驱动重生序列 | medium |
| `RespawnAnchorService` | 记录/查询/校验锚点，提供回退链 | medium |
| `RespawnRecoveryProfile` | 按来源定义恢复矩阵 | low |
| `HazardDefinition` | 定义普通陷阱 / 特殊陷阱行为和伤害 | low |
| `BossRespawnContext` | 提供 Boss 前置点启用与失效信息 | medium |
| `CharacterRespawnController` | 负责角色级打断、冻结、状态清理和复位 | high |

### 3.3 与现有架构的衔接

- `DeathZoneTrigger`、未来的特殊陷阱体积、未解锁水域都只负责发起 `SpecialTrapFailure` 请求，不再直接写 `transform.position`。
- `CharacterStats.OnDeath` 不直接决定落点，只上报 `NormalDeath` 或 `BossFailure` 候选请求。
- `PlayerController` 不再裸露维护 `LastSafePosition`，而是把“稳定落地”事件交给 `RespawnAnchorService`。
- `CharacterContext` 负责提供当前状态、面朝方向、速度清理、输入冻结等角色级 API，但不自行做来源仲裁。

## 4. RespawnSource 判定模型

### 4.1 统一请求结构

```csharp
public enum RespawnSource
{
    InitialSpawn,
    SpecialTrapFailure,
    BossFailure,
    LoadGame,
    NormalDeath,
}

public struct RespawnRequest
{
    public RespawnSource Source;
    public object SourceContext;
    public int Priority;
    public int FrameIndex;
    public bool RequiresDamage;
    public bool CanOverrideLowerPriority;
}
```

### 4.2 来源优先级表

| 优先级 | 来源 | 为什么 |
| --- | --- | --- |
| 500 | `LoadGame` | 外部显式恢复指令，必须压过运行中失败事件 |
| 400 | `InitialSpawn` | 只在场景进入时使用，不与运行态失败竞争 |
| 300 | `BossFailure` | Boss 战失败是比普通 HP 归零更高层的战斗上下文结果 |
| 200 | `SpecialTrapFailure` | 平台失败需要稳定压过同帧普通死亡，确保走快速回位链 |
| 100 | `NormalDeath` | 默认世界层失败兜底 |

### 4.3 冲突仲裁规则

- 同一 FixedUpdate 内只允许一个 `RespawnRequest` 生效。
- 若同帧同时出现 `SpecialTrapFailure` 与 `NormalDeath`：
  - 若该特殊陷阱已声明 `ForcesRespawnEvenOnZeroHp = true`，则按 `SpecialTrapFailure` 处理。
  - 否则若扣血后进入 0 HP，升级为 `NormalDeath` 或 `BossFailure`，避免玩家在“应死亡”时错误走快速回位。
- 若角色当前处于 Boss 战上下文中且触发 `OnDeath`，由 Boss 系统先上报 `BossFailure`，它应覆盖 `NormalDeath`。
- `LoadGame` 和 `InitialSpawn` 只在非战斗运行态触发，不参与普通帧竞争；若被调用时已有进行中的重生序列，先取消旧序列再执行新序列。

## 5. RespawnAnchor 模型

### 5.1 锚点类型

| 锚点类型 | 用途 | 主服务来源 |
| --- | --- | --- |
| `SceneStart` | 新游戏或首进场景的初始放置 | `InitialSpawn` |
| `LastSafeGround` | 特殊陷阱失败后的快速重试点 | `SpecialTrapFailure` |
| `BossEntry` | 关键 Boss 的战前重试点 | `BossFailure` |
| `Checkpoint` | 存档点 / 普通战死 / 读档恢复 | `NormalDeath` / `LoadGame` / `BossFailure` 回退 |

### 5.2 数据形态

推荐使用“引用对象 + 已解析世界坐标”的混合模型。

```csharp
public struct RespawnAnchor
{
    public RespawnAnchorType Type;
    public string AnchorId;
    public Transform AnchorTransform;
    public Vector3 CachedWorldPosition;
    public Vector2 FacingHint;
    public int RoomId;
    public bool IsDynamic;
}
```

- 对静态锚点，优先使用对象引用，便于关卡作者显式布点。
- 对 `LastSafeGround`，只缓存解析后的世界坐标和法线/朝向提示，不依赖临时地面对象持续存在。
- 对动态平台，不直接把平台 Transform 当最终重生目标；只允许在记录瞬间把平台顶部稳定点烘成世界坐标，再重新做安全校验。

### 5.3 锚点记录规则

`LastSafeGround` 必须同时满足：

- 角色处于 grounded。
- 角色垂直速度绝对值低于阈值，排除刚落地弹跳或被击退。
- 当前不在危险体积内，不在危险边缘缓冲区内。
- 站立面在最小宽度、头顶净空、左右逃逸空间上通过校验。
- 角色当前状态属于稳定落地态：至少覆盖 `Idle`、`Run`、`CrouchIdle`、`CrouchWalk`，而不是只覆盖 `Idle/Run`。

### 5.4 锚点有效性校验

候选锚点在真正使用前统一走 `ValidateAnchor()`：

- 地面存在：向下 box cast 可命中可站立层。
- 头顶净空：满足站立或蹲姿所需 clearance。
- 左右安全：不与墙体重叠，且不在最小水平缝隙以下。
- 危险隔离：不在 `SpecialTrap`、`NormalTrap`、动态机关立即触发范围内。
- 动态对象失效：若引用对象已销毁、禁用或移动到危险区，则视为失效。

## 6. 各来源的锚点选择与回退链

| 来源 | 首选锚点 | 次选锚点 | 最终兜底 |
| --- | --- | --- | --- |
| `InitialSpawn` | `SceneStart` | 场景配置默认入口 | 阻止进入并报错日志 |
| `SpecialTrapFailure` | `LastSafeGround` | 房间内显式 `Checkpoint` | `SceneStart` |
| `BossFailure` | `BossEntry` | 最近 `Checkpoint` | `SceneStart` |
| `LoadGame` | 存档记录的 `Checkpoint` | 场景默认 `Checkpoint` | `SceneStart` |
| `NormalDeath` | 最近 `Checkpoint` | 场景默认 `Checkpoint` | `SceneStart` |

补充规则：

- `BossFailure` 明确禁止回落到 `LastSafeGround`，避免平台锚点污染 Boss 循环。
- `SpecialTrapFailure` 在首版即使没有房间系统，也应允许关卡显式配置“挑战段默认回位点”作为 `Checkpoint` 次选。
- 若所有候选锚点失效，系统必须输出高亮日志并回退 `SceneStart`，不能继续使用无效坐标。

## 7. 特殊陷阱体系

### 7.1 配置化分层

```csharp
public enum HazardRespawnMode
{
    DamageOnly,
    DamageAndRespawn,
}

public class HazardDefinition : ScriptableObject
{
    public string HazardId;
    public HazardRespawnMode RespawnMode;
    public float DamageAmount;
    public bool ForcesRespawnEvenOnZeroHp;
    public RespawnAnchorType PreferredAnchorType;
}
```

- `普通陷阱` = `DamageOnly`。
- `特殊陷阱` = `DamageAndRespawn`。
- `深渊` 默认使用 `DamageAndRespawn + PreferredAnchorType = LastSafeGround`。
- 未解锁水域在首版可复用同一配置模型，只是 `HazardId = water_locked`。

### 7.2 首版边界

- 首版只要求 `DeathZoneTrigger` 改为读取 `HazardDefinition` 并上报 `SpecialTrapFailure`。
- 其他特殊陷阱先不要求内容团队批量改造，但数据结构必须能无缝接入秒杀尖刺坑、酸液坑、强制回位机关。

## 8. HFSM / ActionPriority 衔接

### 8.1 中断原则

- 重生触发视为高优先级系统中断，优先级高于移动、跳跃、冲刺、受击、游泳等普通动作态。
- 但它不是普通角色状态切换，而是“状态机外层控制权切换”：先冻结角色控制，再把状态机重置到安全初始态。

### 8.2 推荐执行顺序

1. `RespawnManager` 锁定该帧唯一请求。
2. `CharacterRespawnController` 设置 `CanAct = false`，冻结输入消费。
3. 停止当前位移与残余速度，取消 dash / wall slide / swim 等持续态资源。
4. 播放短失败反馈。
5. 选定并校验锚点。
6. 通过统一复位 API 设置位置、朝向、速度、资源。
7. 将 HFSM 强制切回 `Idle`、`CrouchIdle` 或其他与落点匹配的安全地面态。
8. 恢复输入与相机控制。

### 8.3 禁止事项

- 禁止从 `DeathZoneTrigger`、`WaterZone` 等环境脚本直接改 `transform.position`。
- 禁止把 respawn 设计成单纯 `SM.ChangeState(RespawnState)` 然后在状态里处理一切；状态机不适合做跨模块调度。
- 禁止在 `Update` 内做物理复位和位置推进。

## 9. 重生状态流

### 9.1 特殊陷阱失败

```text
Hazard Trigger
-> build RespawnRequest(SpecialTrapFailure)
-> RespawnManager arbitration
-> apply hazard damage
-> lock input / clear velocity / short feedback
-> resolve LastSafeGround fallback chain
-> validate anchor
-> reposition + reset state
-> grant brief invulnerability
-> return control
```

### 9.2 Boss 失败

```text
Boss combat context marks failure
-> CharacterStats reaches death or boss-specific fail condition
-> build RespawnRequest(BossFailure)
-> RespawnManager arbitration
-> skip hazard quick-retry path
-> resolve BossEntry fallback chain
-> reset combat state / camera lock / player state
-> reposition before arena
-> return control outside boss gate
```

## 10. 状态恢复矩阵

| 维度 | `SpecialTrapFailure` | `BossFailure` | `NormalDeath` | `LoadGame` | `InitialSpawn` |
| --- | --- | --- | --- | --- | --- |
| 位置 | 回 `LastSafeGround` 链 | 回 `BossEntry` 链 | 回 `Checkpoint` | 回存档点 | 回场景起点 |
| 朝向 | 优先保留锚点提示 | 面向 Boss 入口外侧 | 使用存档点朝向 | 使用存档点朝向 | 使用场景默认 |
| 速度 | 全清零 | 全清零 | 全清零 | 全清零 | 全清零 |
| 输入缓冲 | 全清空 | 全清空 | 全清空 | 全清空 | 全清空 |
| 当前状态 | 强制回安全地面态 | 强制回安全地面态 | 强制回安全地面态 | 强制回安全地面态 | 强制回安全地面态 |
| 跳跃/冲刺资源 | 全补满 | 全补满 | 全补满 | 全补满 | 全补满 |
| HP | 扣陷阱伤害后的剩余值 | 恢复到存档规则值 | 恢复到存档规则值 | 恢复到存档值 | 初始值 |
| 能量/战斗资源 | 保持当前值 | 按存档/房间规则恢复 | 按存档规则恢复 | 按存档值恢复 | 初始值 |
| 无敌帧 | 短暂给予 | 短暂给予 | 短暂给予 | 无需额外 | 无需额外 |
| 相机 | 快速回位，不重置大场景 | 解除 Boss 锁定并回战前构图 | 回存档点构图 | 走读档构图 | 走场景入口构图 |

说明：

- `SpecialTrapFailure` 不自动回满 HP；它的惩罚就是“扣血后继续挑战”。
- `BossFailure` 与 `NormalDeath` 可以共用一部分恢复模板，但来源和锚点链必须独立。
- 若未来设计要求 `BossFailure` 保留房间内资源状态，可在 `RespawnRecoveryProfile` 中单独覆写，不影响框架。

## 11. 关键 Boss 前置点启用条件

仅当同时满足以下条件时，Boss 可启用 `BossEntry`：

- 该 Boss 被标记为关键 Boss。
- 战前存在明确的准备区 / 门外落脚区，不会让玩家重生后立刻进入战斗判定。
- 该点通过锚点安全校验，且不会与动态机关、剧情锁门、过场动画冲突。
- 关卡设计已提供无法使用时的 `Checkpoint` 回退点。

若任一条件失效，`BossFailure` 直接回最近 `Checkpoint`。

## 12. 面向 Developer 的实现约束

- 必须新增统一的 `RespawnManager` 协调层，不能继续让 hazard 脚本直接做回位。
- 必须保留 `RespawnSource` 和 `RespawnAnchorType` 的显式枚举，避免后期用字符串分支失控。
- 角色复位必须发生在受控序列中，位置设置后要立即做碰撞/地面再确认。
- 所有日志统一走 `PanCake.Metroidvania.Utils.DebugLogger`。
- 复杂复位逻辑需要中文注释，尤其是锚点校验、同帧冲突仲裁和状态清理代码块。
- 每次代码落地后，都要先做明显编译错误检查，再验证 `DeathZoneTrigger`、未解锁水域和普通死亡路径不会互相污染。

## 13. 技术风险评估

- Overall Risk: `medium`
- `CharacterRespawnController` 与现有轻量 FSM 的衔接风险为 `high`，因为当前没有正式的系统级中断层。
- 动态平台、塌陷平台、危险边缘的 `LastSafeGround` 有效性校验风险为 `medium`。
- Boss 前置点与存档点回退关系风险为 `medium`，主要取决于未来 Boss 房/房间系统落地方式。
- `HazardDefinition`、恢复矩阵、来源枚举本身风险为 `low`。

## 14. 对当前实现的直接修正建议

- 现有 `LastSafePosition` 只在 `Idle/Run` 记录，需升级为“稳定落地锚点”语义。
- 现有 `DeathZoneTrigger` 直接黑屏 + 改位置 + 清 `Time.timeScale`，后续应收口到统一重生执行器。
- 未解锁水域当前通过 `FindAnyObjectByType<DeathZoneTrigger>()` 复用逻辑，只适合作为临时验证，不应进入正式架构。
- `CharacterStats.OnDeath` 当前缺少世界层订阅者，后续 `NormalDeath` / `BossFailure` 都应从这里进入统一调度。

## 15. 交接结论

- 本文已覆盖：模块拆分、来源优先级、锚点分类、回退链、特殊陷阱扩展口、HFSM 打断原则、恢复矩阵、开发约束。
- 进入实现阶段时，建议优先顺序为：`Respawn enums + request model` -> `RespawnManager` -> `LastSafeGround` 升级 -> `DeathZoneTrigger` 接入 -> `NormalDeath` 接入 -> `BossFailure` 预埋接口。
