# Module Design: Project Architecture

> 依据 `docs/FeatureSpecs/MetroidvaniaFoundation.md`、`docs/FeatureSpecs/CorePriority.md`、`docs/ModuleDesign/CharacterFeature.md` 与 `docs/ModuleDesign/Locomotion.md`。

---

## 1. 文档目标

这份文档定义项目的**顶层模块架构**，用于把整个项目中的模块层次、依赖方向、实现顺序和协作边界显性化。

目标不是替代各模块设计文档，而是回答下面四个问题：

- 哪些模块属于底层能力，应该先做。
- 哪些模块依赖哪些前置模块。
- 哪些模块可以并行推进，哪些必须串行。
- 在 `Metroidvania-like` 项目里，整条能力链应如何从底层一路搭到内容层。

## 2. 架构原则

### 2.1 单向依赖

- 底层模块不反向依赖上层模块。
- 上层模块可以读取和组合下层模块，但不应把规则反写回底层。
- 世界内容层可以依赖角色、战斗、存档、地图等系统，但这些底层系统不能依赖具体关卡内容。

### 2.2 先能力，后内容

- 先建立稳定的角色、移动、战斗、状态、存档、地图等能力骨架。
- 再用这些能力去承接区域、能力门、捷径、Boss、奖励投放等内容设计。
- 不建议在底层能力未成型前，大量堆叠正式区域内容。

### 2.3 基础层服务卖点

- 本项目的主卖点是 `丝滑操控 + 华丽战斗`。
- 因此角色基础层、移动层、战斗层属于最优先的底层支柱。
- 世界结构、地图、升级、叙事等模块应建立在这条能力链已经稳定的前提上。

## 3. 顶层模块分层

推荐将项目分成六层：

```text
L0 Project Foundation
L1 Runtime Core
L2 Character And Action
L3 Progression And World State
L4 World Content
L5 Presentation And Tooling
```

### 3.1 L0 Project Foundation

定义项目级基础约束与通用入口：

- 项目目录结构
- 全局约定与术语
- 启动入口与主场景
- Autoload / 全局服务注册
- 通用资源组织规则

### 3.2 L1 Runtime Core

所有玩法系统都会依赖的通用运行时能力：

- 事件 / 信号约定
- 通用状态机框架
- 基础数据结构
- 配置资源读取
- 场景加载与切换基础能力
- 调试日志和基础开发工具

### 3.3 L2 Character And Action

项目核心卖点所在层，当前最优先：

- `Character Foundation`
- `Locomotion`
- Combat
- Hurt / Death / Respawn 协同
- Camera 感知与动作表现接口

### 3.4 L3 Progression And World State

将动作能力与银河恶魔城推进结构连接起来：

- Ability Unlock
- Quest System
- Inventory System
- Save / Checkpoint
- Persistent World State
- Fast Travel / Shortcut State
- Key Items / Quest Items
- Equipment / Consumables Rules
- Map Discovery / Map Markers

### 3.5 L4 World Content

承载具体游戏内容：

- Region / Room 组织
- Traversal Rooms
- Combat Rooms
- Upgrade Rooms
- NPC / Narrative Rooms
- Boss Rooms
- Secret Routes

### 3.6 L5 Presentation And Tooling

提升生产效率和最终表现：

- UI / HUD / Menu
- Audio / Music Routing
- VFX / Camera Feedback
- Editor Tooling
- Test Scenes / Automation Helpers

## 4. 当前项目推荐依赖图

```text
Project Foundation
-> Runtime Core
-> Character Foundation
-> Locomotion
-> Combat
-> Hurt / Death / Respawn
-> Ability Unlock / Quest / Item / World State
-> Map / Save / Checkpoint
-> Region / Room Content
-> Boss / NPC / Secret / Shortcut Content
-> UI / Audio / VFX / Tooling polish
```

## 5. 模块依赖矩阵

| 模块 | 直接依赖 | 说明 |
| --- | --- | --- |
| `Character Foundation` | `Runtime Core` | 提供角色基础真相 |
| `Locomotion` | `Character Foundation` | 提供移动与平台能力 |
| Combat | `Character Foundation`, `Locomotion` | 提供攻击、连段、命中反馈 |
| Respawn | `Character Foundation`, `Locomotion` | 需要角色状态与移动清理 |
| Ability Unlock | `Character Foundation`, `Locomotion`, Combat | 解锁能力并影响世界与动作 |
| Quest System | `World State`, NPC, `Ability Unlock`, `Item System` | 组织任务条件、阶段推进与事件分发 |
| Item System | `Character Foundation`, Combat, `World State` | 管理物品定义、库存、掉落与使用结果 |
| Save / Checkpoint | `Respawn`, `Ability Unlock`, `World State` | 保存进度与恢复条件 |
| Map System | `World State`, `Ability Unlock` | 展示探索状态与阻挡提示 |
| World Content | `Locomotion`, Combat, `Ability Unlock`, `Quest System`, `Item System`, `Save / Checkpoint` | 具体房间与区域依赖下层玩法能力 |
| UI / HUD | `Character Foundation`, Combat, `World State`, `Map System` | 呈现状态与反馈 |

## 5.1 `Quest` 与 `Item` 的架构定位

### `Quest System`

- 归属 `L3 Progression And World State`。
- 本质上是**进度状态编排层**，负责管理任务阶段、触发条件、NPC 对话推进、世界状态变化和奖励分发。
- 它不直接实现角色移动、战斗或房间逻辑，而是消费这些系统产生的结果。

### `Item System`

- 主体归属 `L3 Progression And World State`，但会向下影响 `L2 Character And Action`。
- 更准确地说，`Item` 需要拆成两类：
- `Key Items / Quest Items`：直接属于推进层，用于开门、解锁、任务推进、世界状态变化。
- `Equipment / Consumables / Combat Modifiers`：规则归 Item System 管，效果落到角色、战斗、世界状态等具体系统。

### 为什么这样分

- `Quest` 解决的是“世界进度如何推进”。
- `Item` 解决的是“玩家获得了什么，以及它会改变哪些系统”。
- 这两者都不应直接写进具体房间或具体角色脚本，否则很快会失控。

## 6. 当前已落文档在架构中的位置

| 文档 | 所属层 | 作用 |
| --- | --- | --- |
| `docs/FeatureSpecs/MetroidvaniaFoundation.md` | 顶层产品骨架 | 定义项目方向与世界结构 |
| `docs/FeatureSpecs/CorePriority.md` | 顶层优先级 | 定义卖点、阶段和主线优先级 |
| `docs/ModuleDesign/RuntimeCore.md` | `L1 Runtime Core` | 定义共享运行时基础能力 |
| `docs/ModuleDesign/CharacterFeature.md` | `L2 Character And Action` | 定义角色基础层 |
| `docs/ModuleDesign/Locomotion.md` | `L2 Character And Action` | 定义移动层 |
| `docs/TestCase/character-feature.md` | 测试层 | 验证角色基础层 |
| `docs/TestCase/p0a-character-locomotion.md` | 测试层 | 验证移动层 |

## 7. 推荐开发顺序

### 7.1 Phase A: 地基

- `Project Foundation`
- `Runtime Core`
- `Character Foundation`

产出目标：

- 项目能稳定启动。
- 角色基础属性、状态、运行时访问入口成型。
- 后续移动和战斗不需要重复造角色底层。

### 7.2 Phase B: 手感支柱

- `Locomotion`
- Combat 基础闭环
- Hurt / Death / Respawn 闭环

产出目标：

- 玩家跑跳冲刺墙跳抓边手感稳定。
- 基础命中、受击、死亡和回位链路打通。

### 7.3 Phase C: 银河恶魔城推进层

- `Ability Unlock`
- `Quest System`
- `Item System`
- `World State`
- `Save / Checkpoint`
- `Map System`

产出目标：

- 新能力能改变探索路径。
- 世界状态能记录解锁、捷径、机关与进度。
- 任务和物品系统能稳定驱动 NPC、门、奖励、区域阻挡与世界变化。

### 7.4 Phase D: 内容承载层

- Region / Room authoring
- Boss / NPC
- Secret / Shortcut / Upgrade 内容

产出目标：

- 用前面稳定的系统承载区域内容，而不是边做系统边硬塞正式关卡。

### 7.5 Phase E: 表现与生产效率

- UI / HUD / Menu
- Audio / VFX / Camera polish
- Editor tools
- Regression test scenes

## 8. 并行开发建议

可以并行的：

- `Character Foundation` 与 `Runtime Core` 的细化
- `Locomotion` 参数表与 `P0A` 测试房搭建
- 世界结构文档与能力门内容规划
- `Quest` 与 `Item` 的文档规划可与世界结构文档并行

不建议并行过深的：

- 在 `Locomotion` 未稳定前大规模做正式 traversal 区域
- 在 Combat 边界未清楚前大规模做 Boss
- 在 Save / World State 未成型前大量铺 checkpoint、捷径和世界机关

## 9. 模块边界规则

### 9.1 `Character Foundation`

- 不应依赖具体房间、Boss、区域和地图实现。
- 只提供角色基础真相与运行时访问入口。

### 9.2 `Locomotion`

- 依赖 `Character Foundation`，不反向定义角色基础层。
- 不直接承载完整战斗与存档规则。

### 9.3 Combat

- 依赖 `Character Foundation` 与 `Locomotion`。
- 不应把角色基础属性系统重新定义一遍。

### 9.4 World Content

- 依赖动作、推进和存档层。
- 不应通过关卡脚本偷偷实现底层系统逻辑。

### 9.5 `Quest System`

- 依赖 `World State`、NPC 事件和 `Item System`。
- 不应直接承担角色运动、战斗或地图展示逻辑。

### 9.6 `Item System`

- 依赖角色、战斗和世界状态层，但不重写这些系统。
- 物品定义、库存、获得条件和使用结果应集中管理，不应散落在房间脚本中。

## 10. 近期实施建议

基于当前文档进度，推荐下一批实际制作顺序：

1. 建立 `Runtime Core` 最小骨架
2. 建立 `Character Foundation` 脚本与资源模板
3. 建立 `Locomotion` 脚本骨架与测试场景
4. 打通 `Respawn` 与基础角色状态清理
5. 再开始 Combat 设计与实现
6. 随后进入 `Quest System` / `Item System` / `World State` 设计

## 11. 后续文档建议

建议后续按这条链继续补文档：

- `docs/ModuleDesign/RuntimeCore.md`
- Combat 设计文档
- Quest System 设计文档
- Item System 设计文档
- Ability Unlock 设计文档
- Save / Checkpoint 设计文档
- Map System 设计文档
- Region Authoring 规范文档

## 12. 结论

- 这份文档的作用是把项目的模块依赖链显性化，防止开发过程中“上层内容先行、底层能力返工”。
- 当前项目最合理的顺序仍然是：`Character Foundation -> Locomotion -> Combat / Respawn -> Progression Systems -> World Content`。
- 只要保持这条单向依赖链，后续模块扩展和多人协作都会更稳定。
