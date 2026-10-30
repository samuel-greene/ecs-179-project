# ECS179 Prototype

A Godot 2D combat prototype built from reusable scenes. Friendly units chase enemies and fight in melee; enemies chase friendly units or towers; towers fire projectiles that lead moving targets. Use the example scenes as starting points for new units, artwork, and battles.

## Open and run

1. Open the project in Godot. `project.godot` currently declares **Godot 4.7** and the **Forward Plus** renderer; use a matching editor version to avoid compatibility surprises.
2. In Godot's Project Manager, choose **Import** and select `project.godot`. Let the editor finish importing resources.
3. Press **F6** with `Scenes/battle_scene.tscn` open to run the example battle, or **F5** to run the configured main scene.
4. The battle plays automatically. There are no player controls, menus, wave spawning, or victory/defeat screens yet. Stop and rerun it to reset.

The sample battle contains one enemy, one friendly, one tower, a background, and a camera. Watch Godot's Output and Debugger panels while experimenting; health changes and deaths are printed to Output. If Godot asks for a main scene, select `Scenes/battle_scene.tscn`.

## Where things live

```text
project.godot                  Project settings and main-scene reference
Scenes/
  battle_scene.tscn            Playable example and layout starting point
  Templates/
    EnemyExample.tscn          Moving melee enemy
    FriendlyExample.tscn      Moving melee ally
    TowerExample.tscn         Stationary ranged ally
    ProjectileExample.tscn    Projectile used by the example tower
    EnvironmentExample.tscn   Flat-color background
Scripts/
  Core/                       Movement, targeting, and attack behavior
  Components (Data)/          HealthComponent.gd (class name: Health)
  Utils/NodeUtils.gd          Nearest-node lookup by group
```

`icon.svg` is the placeholder artwork used throughout the examples. There is no additional art pack or external dependency to install.

## Use the templates

### Choose how widely a change should apply

- **Edit a template** when every instance should receive the change. For example, replacing `EnemyExample`'s texture updates its instances unless they override it.
- **Override an instance** when only one unit in one battle should differ. Select the instance in `battle_scene.tscn` and change its exported properties in the Inspector. For child properties, use **Editable Children** on the instance when needed. Use the Inspector's revert control to return a property to its template value.
- **Create an inherited scene** for a reusable variant that should continue receiving changes from its base. Right-click an example in the FileSystem dock, choose **New Inherited Scene**, and save it under a new name, such as `Scenes/Friendlies/Scout.tscn` for a variant of `FriendlyExample.tscn`. Create the folder if needed. Use `Scenes/Enemies/` for enemy variants.
- **Duplicate a scene file** for an independent starting point. Later edits to the original scene will not update the copy's node layout or property values. Referenced scripts and resources can still be shared.

For most new content, start with an inherited scene. Drag the saved `.tscn` from the FileSystem dock into the battle's scene tree to add an instance, then position it in the 2D view.

### Keep the required node structure

The scripts look up children by exact name. Preserve these names and root types, or update the scripts alongside your scene changes:

| Example | Root type and script | Required direct children |
| --- | --- | --- |
| Enemy | `CharacterBody2D`, `Enemy.gd` | `Health`, `MeleeAttack`, `CollisionShape2D` |
| Friendly | `CharacterBody2D`, `Friendly.gd` | `Health`, `MeleeAttack`, `CollisionShape2D` |
| Tower | `StaticBody2D`, `Tower.gd` | `Health`, `RangeAttack`, `CollisionShape2D` |
| Projectile | `Area2D`, `Projectile.gd` | `Collider` (`CollisionShape2D`) |
| Environment | `Node2D`, no script | No script-required children |

`Health` uses `Scripts/Components (Data)/HealthComponent.gd`. The attack children use their corresponding scripts in `Scripts/Core/`. Visual nodes such as `Icon` can be replaced or renamed because the current combat scripts do not reference them.

Enemy, friendly, and tower scripts register their roots in groups at runtime:

- `Enemy` joins `enemies` and targets `friendlies`.
- `Friendly` joins `friendlies` and targets `enemies`.
- `Tower` joins `friendlies` and targets `enemies`.

Units initially choose the nearest target by distance between root positions. They keep that target until it becomes invalid, then search again. Adding a closer unit does not immediately make an existing unit switch targets. Towers count as friendly targets for enemies.

## Fine-tune combat in the Inspector

Select the indicated node in an example or variant scene to change these exported properties. Godot displays names such as `move_speed` as **Move Speed**.

| Node | Property | Current example value | Effect |
| --- | --- | --- | --- |
| Enemy root | `move_speed` | `150` | Movement speed in pixels per second |
| Friendly root | `move_speed` | `170` | Movement speed in pixels per second |
| Enemy/Friendly `Health` | `max_health`, `starting_health` | `20`, `20` | Healing cap and health at spawn |
| Tower `Health` | `max_health`, `starting_health` | `50`, `50` | Healing cap and health at spawn |
| Enemy `MeleeAttack` | `damage`, `attack_range`, `cooldown_time` | `5`, `20`, `1` | Damage per hit, reach in pixels, seconds between hits |
| Friendly `MeleeAttack` | `damage`, `attack_range`, `cooldown_time` | `5`, `30`, `1` | Damage per hit, reach in pixels, seconds between hits |
| Tower `RangeAttack` | `damage`, `attack_range`, `cooldown_time` | `5`, `300`, `1` | Damage per projectile, firing range, seconds between shots |
| Tower `RangeAttack` | `projectile_speed` | `1000` | Projectile speed in pixels per second |
| Tower `RangeAttack` | `projectile` | `ProjectileExample.tscn` | Scene instantiated for each shot |
| Tower `RangeAttack` | `target_group` | `enemies` | Group a projectile is allowed to damage |

Use positive health, speed, and cooldown values. Set both health fields when changing a unit's durability: `current_health` starts from `starting_health`; increasing `max_health` alone does not increase spawn health. Keep starting health at or below the maximum.

For a rough damage comparison, use `damage / cooldown_time` as damage per second. Travel time, range, collisions, and missed projectiles also affect actual results. Change one variable at a time and rerun the same battle to compare.

**Two settings that do not currently affect gameplay:** the `Cooldown` Timer children in the melee examples are unused; change `MeleeAttack.cooldown_time` instead. The tower root's exported `size` property is also unused; change its visual and collision shape directly.

### Example: add a heavy enemy

1. Create an inherited scene from `EnemyExample.tscn` and save it as `Scenes/Enemies/HeavyEnemy.tscn`.
2. Set the root's **Move Speed** to `90`.
3. Set `Health`'s **Max Health** and **Starting Health** to `60`.
4. Set `MeleeAttack`'s **Damage** to `10` and **Cooldown Time** to `1.5`.
5. Give its `Icon` a distinct texture or tint. If its visible body is larger, resize `CollisionShape2D` to match.
6. Drag the new scene into `battle_scene.tscn`, place it away from the other bodies, and run the battle.

Collision shapes are resources and may be shared between instances or copies. Before resizing a shape for one variant, use **Make Unique** on its Shape resource in the Inspector so you do not accidentally resize other units.

### Example: add a rapid-fire tower and custom projectile

1. Create a variant of `ProjectileExample.tscn`, such as `Scenes/Projectiles/Bolt.tscn`. Keep its `Projectile` script and `Collider` child; replace the sprite and adjust the collider if needed.
2. Create a variant of `TowerExample.tscn`, such as `Scenes/Towers/RapidTower.tscn`.
3. On `RangeAttack`, assign `Bolt.tscn` to **Projectile**. Set **Damage** to `2`, **Cooldown Time** to `0.25`, and **Attack Range** to `350` as an initial experiment.
4. Add the tower to the battle and test against several enemies.

The attack supplies each projectile's damage, speed, and target group when it fires. Those values are not exported on the projectile scene. Projectiles travel in a straight line toward a predicted intercept; they do not home after firing or rotate their sprite automatically. A missed projectile currently keeps traveling indefinitely, so add a lifetime or off-screen cleanup in `Projectile.gd` before building large or long-running battles.

## Replace the placeholder art and improve presentation

### Sprites and silhouettes

1. Create an `Assets/` folder and add your textures. Let Godot import them, then assign a texture to the example's `Icon` node or the projectile's `Sprite2D`.
2. Adjust the **sprite child's** scale and position to get the intended visual size. The friendly and enemy icons currently use scale `0.3`; the projectile uses `0.14`; the tower uses the icon's original size. New artwork may need different scales.
3. Fit the collision shape to the gameplay footprint. Changing a sprite's scale does not resize its sibling collider. Prefer adjusting the sprite and shape separately over scaling the entire physics body.
4. Give allies, enemies, towers, and projectiles distinct silhouettes and colors. For a quick pass, use each sprite's **Self Modulate** property to tint the existing icon.

Keep a consistent art style and pixel density. For pixel art, set texture filtering to **Nearest** in the relevant CanvasItem or project settings; for smooth artwork, choose filtering that suits the assets. Keep projectiles visible against the background and avoid effects that hide unit positions.

### Background, camera, and draw order

- `EnvironmentExample.tscn` contains a `ColorRect` covering a 1500 × 1000 area centered on its origin. Change its color for a quick palette adjustment, or add a background sprite or `TileMapLayer` for scenery. Its root uses `z_index = -1` to draw behind the units.
- Decorative scenery does not block movement automatically. Add physics bodies and collision shapes where you want obstacles. Current units move directly toward targets; pathfinding around obstacles requires additional code.
- Use the `Camera2D` in `battle_scene.tscn` to frame the action. Adjust its position and zoom after laying out the battle, and check the result at your intended window size. The existing camera has no follow script.
- For a top-down look, place appropriate world objects under a parent with **Y Sort Enabled**, and position their origins near their feet. Use explicit `z_index` values for backgrounds and effects where needed.
- Add a `CanvasLayer` with `Control` children for screen-space UI, so labels and menus stay fixed as the camera changes.

### Animation, sound, and health feedback

You can replace `Icon` with an `AnimatedSprite2D`, or add an `AnimationPlayer` and `AudioStreamPlayer2D` children. Playing movement and attack animations requires wiring them into the scripts; merely adding animation nodes does not trigger them.

The `Health` component provides useful hooks for feedback:

| Signal/property | Suggested use |
| --- | --- |
| `received_damage(amount)` | Update a health bar, flash the sprite, play a hit sound |
| `healed(amount)` | Update a health bar or show a heal effect |
| `died` | Spawn a death effect or notify battle logic |
| `current_health`, `max_health` | Initialize a health bar when the unit spawns |

Connect these signals in the editor or in a script. Damage/healing signals carry the amount changed, not the remaining health; read `current_health` for the bar value. The current enemy, friendly, and tower scripts call `queue_free()` on death. To show an effect after the unit disappears, spawn it under the battle scene; to play a death animation on the unit itself, change that cleanup behavior to wait for the animation.

## Add battles and new behavior

### Build another battle

Duplicate `Scenes/battle_scene.tscn` into a new scene, then add, remove, and reposition instances of your saved variants. Keep a camera and an environment in the new scene. Test it with **F6**, and use **Project → Project Settings → Application → Run → Main Scene** if it should become the game's starting scene.

Keep units within the camera's view and avoid starting physics bodies inside one another. Add opponents to test each side: a scene containing only friendlies has no enemy target and will remain idle. A projectile scene run by itself has no launch data and will not demonstrate tower firing.

### Spawn units from code

For waves or scripted encounters, add a separate controller `Node` under your battle root. For example, this script spawns an existing enemy once when the battle starts:

```gdscript
extends Node

@export var enemy_scene: PackedScene = preload("res://Scenes/Templates/EnemyExample.tscn")
@export var spawn_position: Vector2 = Vector2(300, -150)

func _ready() -> void:
    var enemy := enemy_scene.instantiate() as Enemy
    get_tree().current_scene.add_child(enemy)
    enemy.global_position = spawn_position
```

Assign your enemy variant to `enemy_scene` in the Inspector. To turn this into waves, call a spawn function from a Timer and track surviving enemies. Wave timing, score, currency, upgrades, and win/loss conditions all need new logic; the templates currently provide combat only.

### Know where a script change is needed

- **Movement and target selection:** `Enemy.gd`, `Friendly.gd`, and `Tower.gd`.
- **Melee damage and timing:** `MeleeAttack.gd`.
- **Ranged attacks and intercept prediction:** `RangeAttack.gd`.
- **Projectile movement and hit handling:** `Projectile.gd`.
- **Health rules and signals:** `HealthComponent.gd`.
- **Nearest-target lookup:** `NodeUtils.gd`.

The existing root scripts expect specific attack types. Turning a melee friendly into a ranged unit requires changing its script's `MeleeAttack` reference and attack behavior, as well as adding a configured `RangeAttack` node. Swapping the scene child alone is insufficient.

Likewise, changing `RangeAttack.target_group` controls projectile hit eligibility, but does not change the tower's target search. The current tower searches `enemies`, stores an `Enemy` target, and the ranged attack reads that target's `velocity`. An enemy tower or attacks against stationary targets need corresponding targeting/type changes in code.

## Check your changes

After adding a variant or replacing its art, run a small battle and check that:

- The unit appears at the intended size and position, and its collider matches its footprint. Enable **Debug → Visible Collision Shapes** while running to inspect it.
- It finds an opponent, approaches or shoots at the expected range, and deals damage at the intended rate.
- Health reaches zero and the defeated unit disappears; surviving units acquire another target.
- Projectiles use the intended artwork and damage the intended group. If hits fail, check the projectile's collision mask against the target's collision layer, the group membership, and the target's direct `Health` child.
- The camera, background, and UI remain readable at different window sizes.
- Godot's Debugger shows no new errors.

Range checks measure from the attack node to the nearest point on a target's circle or rectangle collider. Other shape types fall back to the collider's origin; targets without the expected `CollisionShape2D` child use their root position. If visual reach feels wrong, check collider size and attack-node placement before changing damage or cooldown.

Commit the new scenes, scripts, and source assets along with Godot's generated `.uid` sidecar files where present. The `.godot/` directory is generated editor/import data and is already ignored by this repository.
