extends RefCounted
## Levels the ground under the crew's tent and balloon, feathered into the hillside. Terrain
## regions stream in and out and reload from disk, so main.gd calls apply() whenever one loads.

const FEATHER := 6.0
## centre x, centre z, half width, half depth, height
const PADS: Array[Array] = [
	[220.0, -300.0, 6.5, 5.5, -3.6],
	[232.0, -307.0, 4.5, 4.5, -1.7],
]


static func height_at(x: float, z: float) -> float:
	for pad: Array in PADS:
		if absf(x - float(pad[0])) <= float(pad[2]) and absf(z - float(pad[1])) <= float(pad[3]): return float(pad[4])
	return NAN


## True once every pad's ground was in memory and has been levelled.
static func apply(terrain: Object) -> bool:
	if terrain == null or terrain.get("data") == null: return false
	var data: Object = terrain.get("data")
	var changed := false
	var complete := true
	for pad: Array in PADS:
		var cx := float(pad[0])
		var cz := float(pad[1])
		var hx := float(pad[2])
		var hz := float(pad[3])
		var target := float(pad[4])
		if not data.call("has_regionp", Vector3(cx, 0, cz)):
			complete = false
			continue
		var x := cx - hx - FEATHER
		while x <= cx + hx + FEATHER:
			var z := cz - hz - FEATHER
			while z <= cz + hz + FEATHER:
				var point := Vector3(x, 0, z)
				var out := Vector2(maxf(absf(x - cx) - hx, 0.0), maxf(absf(z - cz) - hz, 0.0)).length()
				# A pad's feathered edge never touches another pad's flat floor.
				if out < FEATHER and (out <= 0.0 or is_nan(height_at(x, z))):
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
