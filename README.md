## Code naming

rsignal for signal receivers which require `connect`

## Collision layers

1. World
2. Player
3. Enemy
4. Interactions

> mask: A scans for object that has layer in ask of mask
> layer: A is in layer

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
