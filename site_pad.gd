extends RefCounted
## Levels the ground under the crew's tent and balloon, feathered into the hillside. Terrain
## regions stream in and out and reload from disk, so main.gd calls apply() whenever one loads.
## Road ground is never touched, so the road beside the site stays as the game made it.

const FEATHER := 4.0
const ROAD_TEXTURE := 1
## centre x, centre z, half width, half depth, height, yaw (the same yaw as the thing on it)
const PADS: Array[Array] = [
	[187.0, -346.5, 5.5, 4.5, -1.7, 2.93],
	[199.5, -345.0, 4.5, 4.5, -1.05, 0.0],
]


## How far a point lies outside a pad's flat floor; 0 inside it.
static func _outside(pad: Array, x: float, z: float) -> float:
	var local := Vector2(x - float(pad[0]), z - float(pad[1])).rotated(float(pad[5]))
	return Vector2(maxf(absf(local.x) - float(pad[2]), 0.0), maxf(absf(local.y) - float(pad[3]), 0.0)).length()


static func height_at(x: float, z: float) -> float:
	for pad: Array in PADS:
		if _outside(pad, x, z) <= 0.0: return float(pad[4])
	return NAN


static func _texture_at(data: Object, point: Vector3) -> int:
	var bits := int(data.call("get_control", point))
	if bits == 0xffffffff: return -1
	var blend := float((bits >> 14) & 255) / 255.0
	return (bits >> 22) & 31 if blend > 0.5 else (bits >> 27) & 31


## True once every pad's ground was in memory and has been levelled.
static func apply(terrain: Object) -> bool:
	if terrain == null or terrain.get("data") == null: return false
	var data: Object = terrain.get("data")
	var changed := false
	var complete := true
	for pad: Array in PADS:
		var cx := float(pad[0])
		var cz := float(pad[1])
		var target := float(pad[4])
		if not data.call("has_regionp", Vector3(cx, 0, cz)):
			complete = false
			continue
		var reach := ceilf(Vector2(float(pad[2]), float(pad[3])).length() + FEATHER)
		var x := cx - reach
		while x <= cx + reach:
			var z := cz - reach
			while z <= cz + reach:
				var point := Vector3(x, 0, z)
				var out := _outside(pad, x, z)
				# A pad's feathered edge never touches another pad's flat floor.
				if out < FEATHER and (out <= 0.0 or is_nan(height_at(x, z))) and _texture_at(data, point) != ROAD_TEXTURE:
					var ground := float(data.call("get_height", point))
					if is_finite(ground):
						var blend: float = smoothstep(0.0, 1.0, out / FEATHER)
						var level := lerpf(target, ground, blend)
						if absf(level - ground) > 0.01:
							data.call("set_height", point, level)
							changed = true
				z += 1.0
			x += 1.0
	if changed:
		data.call("update_maps", 0, true, false)
		var collision: Variant = terrain.get("collision")
		if collision is Object and (collision as Object).has_method("build"): (collision as Object).call("build")
	return complete
