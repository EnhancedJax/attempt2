## Code naming

rsignal for signal receivers which require `connect`

## Collision layers

1. World
2. Player
3. Enemy
4. Interactions

|  | Collision layer | ← Collision mask (looks for, interacts with) |
| --- | --- | --- |
| 1 | Main | [Bullets] [Entities] |
| 2 | Player EBullet | PHurtbox |
| 3 | Enemy PBullet | EHurtbox |
| 4 |  |  |

> mask: What it collides with
> layer: What it is on

## Weapon system

The script `database_weapon.gd` includes:

`get_weapon(id: int) -> WeaponType` reads the weapon database (json), initiates a `WeaponType` class and returns it.

```json
0: {
  "name": "Pistol",
  "player_tooltip": "A basic pistol",
  "scene": "res://scenes/weapons/pistol.tscn"
}
```

Can create enemy system in similar fashion.
