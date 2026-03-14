# Module Design: Runtime Core

> 依据 `docs/ModuleDesign/ProjectArchitecture.md`、`docs/FeatureSpecs/CorePriority.md`、`docs/ModuleDesign/CharacterFeature.md` 与 `docs/ModuleDesign/Locomotion.md`。

---

## 1. 文档目标

`Runtime Core` 是项目中所有玩法系统共享的底层运行时能力层。

它的目标不是直接产出“玩家可见玩法”，而是为后续 `Character Foundation`、`Locomotion`、Combat、Respawn、World State 等模块提供统一、稳定、可复用的基础设施。

这份文档回答四个问题：

- `Runtime Core` 到底包含哪些模块。
- 它和 `Project Foundation`、`Character Foundation` 的边界在哪里。
- 哪些能力必须先落地，后续模块才不会反复返工。
- 在 `Godot 4` 项目中，这些底层能力应该如何组织。

## 2. 定位与边界

### 2.1 `Runtime Core` 属于哪一层

- 它位于 `L1 Runtime Core`。
- 它在 `Project Foundation` 之上，在 `Character Foundation` 与所有玩法系统之下。

### 2.2 它负责什么

- 提供通用运行时约定。
- 提供可被多个系统共享的基础模块。
- 降低各玩法模块之间的耦合成本。
- 让状态、事件、配置、场景切换、调试这类横切关注点集中管理。

### 2.3 它不负责什么

- 不定义角色属性规则。
- 不定义移动、战斗、任务、物品的业务逻辑。
- 不直接承载具体房间或区域内容。
- 不因为某个上层玩法临时需要，就演变成万能杂物箱。

## 3. 核心原则

### 3.1 通用优先

- 只有会被多个模块复用的能力，才应进入 `Runtime Core`。
- 如果某段逻辑只服务某个子系统，应优先放在该子系统内部。

### 3.2 单向依赖

- `Runtime Core` 不依赖 `Character Foundation`、`Locomotion`、Combat、World Content。
- 上层模块可以依赖 `Runtime Core`，但不能把上层规则反注入回 `Runtime Core`。

### 3.3 轻量稳定

- `Runtime Core` 应尽可能小而稳定。
- 它一旦频繁变化，会带来整条依赖链的大范围返工。

## 4. 推荐模块组成

首版建议由六个子模块组成：

```text
Runtime Core
-> Event Hub
-> State Framework
-> Config And Resource Access
-> Scene Flow
-> Save Data Foundation
-> Debug And Dev Support
```

## 5. 子模块说明

### 5.1 Event Hub

作用：

- 统一组织全局或跨系统事件分发。
- 降低角色、UI、存档、地图、任务、房间之间的直接引用。

适合放入的内容：

- 通用事件频道约定
- 全局事件总线或事件中转 Autoload
- 订阅 / 取消订阅规则

不适合放入的内容：

- 具体角色受击公式
- 具体任务阶段推进逻辑

#### 推荐最小接口

```gdscript
class_name EventHub
extends Node

signal event_emitted(channel: StringName, payload: Variant)

func emit_event(channel: StringName, payload: Variant = null) -> void:
	pass

func subscribe(channel: StringName, listener: Callable) -> void:
	pass

func unsubscribe(channel: StringName, listener: Callable) -> void:
	pass
```

#### 首版事件频道建议

- `player_spawned`
- `player_died`
- `checkpoint_reached`
- `scene_transition_requested`
- `ability_unlocked`
- `ui_popup_requested`

### 5.2 State Framework

作用：

- 为角色、敌人、Boss、房间逻辑提供共享状态机基础能力。
- 统一状态生命周期与切换约定。

适合放入的内容：

- 通用状态接口
- 轻量状态机驱动器
- 切换保护与挂起机制
- 公共状态标签结构

不适合放入的内容：

- `Idle` / `Run` / `Attack` 这些具体状态实现

#### 推荐最小接口

```gdscript
class_name StateNode
extends RefCounted

func enter(context: Variant) -> void:
	pass

func exit(context: Variant) -> void:
	pass

func physics_update(context: Variant, delta: float) -> void:
	pass

func handle_input(context: Variant, input_data: Variant) -> void:
	pass
```

```gdscript
class_name StateMachineDriver
extends RefCounted

var current_state_id: StringName

func register_state(state_id: StringName, state: StateNode) -> void:
	pass

func request_transition(next_state_id: StringName) -> bool:
	pass

func update_physics(context: Variant, delta: float) -> void:
	pass
```

#### 框架职责边界

- `Runtime Core` 只提供状态生命周期和切换机制。
- `Character Foundation` 与 `Locomotion` 决定具体状态内容与切换条件。

### 5.3 Config And Resource Access

作用：

- 统一配置资源的加载、缓存、读取和默认值策略。
- 降低上层模块直接散乱读取资源的风险。

适合放入的内容：

- `Resource` 加载入口
- 配置缓存与查找
- 通用配置基类或标识结构

#### 推荐最小接口

```gdscript
class_name ConfigService
extends Node

func load_resource(path: String) -> Resource:
	return null

func get_cached_resource(path: String) -> Resource:
	return null

func clear_cache() -> void:
	pass
```

#### 首版目标

- 统一 `CharacterCombatProfile`、`CharacterMotionProfile` 等资源读取入口。
- 避免角色、移动、战斗模块各自直接散落 `load()` 调用。

### 5.4 Scene Flow

作用：

- 统一场景加载、切换、重载和过渡能力。
- 为 Respawn、快速旅行、房间切换、主菜单进入游戏提供基础支撑。

适合放入的内容：

- 场景切换服务
- 加载遮罩 / 过渡钩子
- 主场景与子场景加载约定

#### 推荐最小接口

```gdscript
class_name SceneFlow
extends Node

signal transition_started(target_path: String)
signal transition_finished(target_path: String)

func change_scene(target_path: String) -> void:
	pass

func reload_current_scene() -> void:
	pass
```

#### 首版限制

- 首版只需要支持主场景切换、重载和基础过渡。
- 分层房间流加载和大型区域 streaming 可后续再扩展。

### 5.5 Save Data Foundation

作用：

- 为后续 `Save / Checkpoint`、`World State`、地图探索、能力解锁提供统一持久化数据基础。

适合放入的内容：

- 存档槽位结构
- 通用序列化入口
- 版本字段与兼容策略
- 基础读写服务接口

不适合放入的内容：

- 某个具体能力如何解锁
- 某个具体地图格子如何显示

#### 推荐最小数据结构

```gdscript
class_name SaveSlotData
extends Resource

var slot_id: int = 0
var version: int = 1
var last_scene_path: String = ""
var checkpoint_id: StringName = &""
var world_state: Dictionary = {}
var unlocked_abilities: Dictionary = {}
```

#### 推荐最小接口

```gdscript
class_name SaveService
extends Node

func save_slot(slot_id: int, data: SaveSlotData) -> bool:
	return false

func load_slot(slot_id: int) -> SaveSlotData:
	return null
```

### 5.6 Debug And Dev Support

作用：

- 提供调试开关、日志入口、测试场景辅助和开发时便捷能力。

适合放入的内容：

- 日志封装
- Debug flag
- 开发面板入口
- 测试模式开关

#### 推荐最小接口

```gdscript
class_name DebugService
extends Node

var debug_enabled: bool = true

func log_info(channel: StringName, message: String) -> void:
	pass

func log_warning(channel: StringName, message: String) -> void:
	pass

func log_error(channel: StringName, message: String) -> void:
	pass
```

## 6. 推荐目录组织

```text
autoload/
-> event_hub.gd
-> config_service.gd
-> scene_flow.gd
-> save_service.gd
-> debug_service.gd

scripts/core/
-> state/
   -> state_node.gd
   -> state_machine_driver.gd
-> events/
-> config/
-> scene/
-> save/
-> debug/
```

### 推荐首版文件清单

```text
autoload/event_hub.gd
autoload/config_service.gd
autoload/scene_flow.gd
autoload/save_service.gd
autoload/debug_service.gd
scripts/core/state/state_node.gd
scripts/core/state/state_machine_driver.gd
scripts/core/save/save_slot_data.gd
```

## 7. 与其他层的边界

### 7.1 与 `Project Foundation` 的边界

- `Project Foundation` 负责项目初始化、目录规则、入口场景、Autoload 注册约定。
- `Runtime Core` 负责这些约定之上的可复用运行时能力。

### 7.2 与 `Character Foundation` 的边界

- `Runtime Core` 提供状态框架、事件系统、配置读取、日志和存档基础。
- `Character Foundation` 才负责 `CharacterStats`、`CharacterSignals`、`CharacterContext`、`DamageReceiver`。

### 7.3 与 `Locomotion` 的边界

- `Locomotion` 可以使用 `State Framework`、事件、配置读取和调试支持。
- `Runtime Core` 不定义跳跃、冲刺、墙跳、抓边这些移动业务。

## 8. 推荐依赖关系

```text
Project Foundation
-> Runtime Core
   -> Character Foundation
      -> Locomotion
      -> Combat
   -> Save / Checkpoint
   -> World State
   -> Map System
```

## 9. 首版必须先落地的能力

为了支撑当前最优先路线，建议 `Runtime Core` 首版先完成以下最小集：

### 9.1 通用状态接口

- 为 `Character Foundation` 和 `Locomotion` 提供统一状态机基类或接口。

### 9.2 配置资源读取入口

- 为 `CharacterCombatProfile`、`CharacterMotionProfile` 等资源提供统一读取约定。

### 9.3 场景流转基础服务

- 为后续 `Respawn` 和测试场景切换提供基础场景服务。

### 9.4 基础日志与调试入口

- 为移动调参、受击调试、能力解锁验证提供统一输出方式。

### 9.5 存档数据基础结构

- 先定义存档结构和接口，不必立即做完整系统。

## 10. 首版 Autoload 建议

建议首版注册以下全局服务：

| Autoload | 责任 |
| --- | --- |
| `EventHub` | 跨系统事件分发 |
| `ConfigService` | 共享资源读取与缓存 |
| `SceneFlow` | 场景切换与重载 |
| `SaveService` | 存档读写入口 |
| `DebugService` | 日志与调试开关 |

这些服务应保持轻量，不应在首版承担业务逻辑。

## 11. 与当前文档链的关系

| 文档 | 如何依赖 `Runtime Core` |
| --- | --- |
| `docs/ModuleDesign/CharacterFeature.md` | 依赖状态框架、配置读取、事件与日志基础 |
| `docs/ModuleDesign/Locomotion.md` | 依赖状态框架、配置读取、调试支持 |
| `docs/TestCase/character-feature.md` | 依赖日志与测试辅助能力 |
| `docs/TestCase/p0a-character-locomotion.md` | 依赖调试输出与测试场景支持 |

## 12. 实装骨架建议

### 12.1 推荐落地顺序

1. 写 `StateNode` 与 `StateMachineDriver`
2. 写 `DebugService`
3. 写 `ConfigService`
4. 写 `EventHub`
5. 写 `SceneFlow`
6. 写 `SaveSlotData` 与 `SaveService`

### 12.2 第一批验证目标

- `Character Foundation` 能直接依赖 `StateMachineDriver` 和 `DebugService`
- `Locomotion` 能直接依赖 `State Framework` 和 `ConfigService`
- 测试场景能通过 `SceneFlow` 重载
- 基础存档结构能被创建、序列化、反序列化

## 13. 开发顺序建议

推荐顺序：

1. 明确 `autoload` 级全局服务清单
2. 建立 `State Framework` 最小接口
3. 建立配置资源读取与缓存入口
4. 建立场景流转基础服务
5. 建立日志和 debug 支持
6. 建立存档数据基础结构
7. 再开始 `Character Foundation` 代码骨架

## 14. 不应过早放入 Runtime Core 的内容

- 角色专属逻辑
- 某个 Boss 的专用阶段机制
- 某个区域的机关脚本
- 某个任务的单独规则
- 仅某个 UI 页面使用的一次性工具

## 15. 后续可衔接文档

在这份文档之后，最适合继续补的文档是：

- `Character Foundation` 实装骨架
- `Locomotion` 实装骨架
- `Save / Checkpoint` 设计文档
- Combat 设计文档

## 16. 结论

- `Runtime Core` 是“所有玩法系统共享的最小底层能力层”，不是大而全的万能层。
- 它的价值在于让 `Character Foundation`、`Locomotion`、Respawn、World State 等模块建立在统一基础之上。
- 只要这层先收稳，后续往上搭动作、推进和内容层都会顺很多。
