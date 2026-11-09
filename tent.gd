extends Node3D
## The Mare Fair crew's lodge tent beside their balloon, a real home with three double beds. The
## game puts two sleepers in each bed, the player and his partner in the first. Striped like the
## balloon. The door faces -Z. Built in code, and modelled on Trixie's wagon
## (world/buildings/trixie_wagon.gd).

class TentHome extends "res://world/buildings/authored_home.gd":
	func _init() -> void: home_kind = "mare_fair_tent"

	## Population refreshes list residents only; a married player keeps the first bed with her.
	func set_sleepers(ids: Array) -> void:
		var everyone := ids.duplicate()
		if has_meta("player_partner") and "player" not in everyone: everyone.append("player")
		super(everyone)

const PLACE_ID := "house:mare_fair_tent"
const POSE := Vector3(220.0, -3.6, -300.0)
const STRIPES := preload("res://mods/mare_fair/envelope.gdshader")
const FITTINGS := preload("res://world/vehicles/balloon/basket.gd")
const DOUBLE_BED := "res://world/props/household/double-pony-bed.glb"
const CANOPY_BED := "res://world/props/household/canopy-pony-bed.glb"
const OWNER := "soiree"
const HALF_X := 4.5
const HALF_Z := 3.5
const EAVES := 2.7
const PEAK := 5.0
const DOOR_WIDTH := 1.6
const DOOR_HEIGHT := 2.2
const FLOOR_TOP := 0.05
const GRASS_TOKEN := "mare_fair:tent"
const WOOD := Color(0.72, 0.55, 0.36)
## The same size and even scale as the game's own house beds (house_beds.gd).
const BED_SIZE := Vector3(2.05, 1.1, 2.1)
const BED_SCALE := Vector3(2.1, 2.1, 2.1)
const MATTRESS_TOP := 0.6

var _landed := false


static func attach(town: Node) -> void:
	if not town is Node3D or town.get_node_or_null("MareFairTent") != null: return
	var node := (load("res://mods/mare_fair/tent.gd") as Script).new() as Node3D
	node.name = "MareFairTent"
	town.add_child(node)
	node.global_position = POSE


func _ready() -> void:
	_shell()
	_add_home()
	set_process(true)


func _exit_tree() -> void:
	if is_inside_tree(): get_tree().call_group("grass_footprints", "remove_exclusion", GRASS_TOKEN)


func _process(_delta: float) -> void:
	if Engine.get_process_frames() % 15 != 0: return
	if _landed:
		# Grass can be rebuilt as the player travels; re-registering an unchanged footprint is free.
		get_tree().call_group("grass_footprints", "add_exclusion", GRASS_TOKEN, global_transform, Vector2(HALF_X + 0.15, HALF_Z + 0.15))
		return
	var exclude: Array[RID] = []
	for body in find_children("*", "CollisionObject3D", true, false):
		exclude.append((body as CollisionObject3D).get_rid())
	var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 40.0, global_position + Vector3.DOWN * 80.0, 1, exclude)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty(): return
	global_position.y = hit.position.y
	_landed = true


func _quad(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	var normal := (b - a).cross(d - a).normalized()
	for point: Vector3 in [a, b, c, a, c, d]:
		tool.set_normal(normal)
		tool.add_vertex(point)


func _shell() -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var x := HALF_X
	var z := HALF_Z
	var gap := DOOR_WIDTH * 0.5
	# Back and sides.
	_quad(tool, Vector3(x, 0, z), Vector3(-x, 0, z), Vector3(-x, EAVES, z), Vector3(x, EAVES, z))
	_quad(tool, Vector3(x, 0, -z), Vector3(x, 0, z), Vector3(x, EAVES, z), Vector3(x, EAVES, -z))
	_quad(tool, Vector3(-x, 0, z), Vector3(-x, 0, -z), Vector3(-x, EAVES, -z), Vector3(-x, EAVES, z))
	# Front, around the door.
	_quad(tool, Vector3(-x, 0, -z), Vector3(-gap, 0, -z), Vector3(-gap, EAVES, -z), Vector3(-x, EAVES, -z))
	_quad(tool, Vector3(gap, 0, -z), Vector3(x, 0, -z), Vector3(x, EAVES, -z), Vector3(gap, EAVES, -z))
	_quad(tool, Vector3(-gap, DOOR_HEIGHT, -z), Vector3(gap, DOOR_HEIGHT, -z), Vector3(gap, EAVES, -z), Vector3(-gap, EAVES, -z))
	# Roof, to one peak.
	var peak := Vector3(0, PEAK, 0)
	var corners := [Vector3(-x, EAVES, z), Vector3(x, EAVES, z), Vector3(x, EAVES, -z), Vector3(-x, EAVES, -z)]
	for i in 4:
		var a: Vector3 = corners[i]
		var b: Vector3 = corners[(i + 1) % 4]
		var normal := (b - a).cross(peak - a).normalized()
		if normal.y < 0.0: normal = -normal
		for point: Vector3 in [a, b, peak]:
			tool.set_normal(normal)
			tool.add_vertex(point)
	var mesh := MeshInstance3D.new()
	mesh.name = "Canvas"
	mesh.mesh = tool.commit()
	var material := ShaderMaterial.new()
	material.shader = STRIPES
	material.set_shader_parameter("stripe_count", 16.0)
	mesh.material_override = material
	add_child(mesh)
	var body := StaticBody3D.new()
	body.name = "Walls"
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	var side := (x - gap) * 0.5
	_wall(body, Vector3(0, EAVES * 0.5, z), Vector3(x * 2.0, EAVES, 0.15))
	_wall(body, Vector3(x, EAVES * 0.5, 0), Vector3(0.15, EAVES, z * 2.0))
	_wall(body, Vector3(-x, EAVES * 0.5, 0), Vector3(0.15, EAVES, z * 2.0))
	_wall(body, Vector3(-(gap + side), EAVES * 0.5, -z), Vector3(side * 2.0, EAVES, 0.15))
	_wall(body, Vector3(gap + side, EAVES * 0.5, -z), Vector3(side * 2.0, EAVES, 0.15))
	FITTINGS.box(self, Vector3(0, FLOOR_TOP * 0.5 - 0.1, 0), Vector3(x * 2.0, FLOOR_TOP + 0.2, z * 2.0), WOOD, true)
	var light := OmniLight3D.new()
	light.position = Vector3(0, 2.5, 0)
	light.light_color = Color(1.0, 0.86, 0.68)
	light.light_energy = 0.9
	light.omni_range = 8.0
	add_child(light)


func _wall(body: StaticBody3D, at: Vector3, size: Vector3) -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = at
	body.add_child(shape)


func _bed(home: Node3D, path: String, at: Vector3, yaw: float, slot: String, side: Vector3) -> Node3D:
	# Only the model is scaled: the game reads the bed's basis for sleeping lanes in metres.
	var bed := Node3D.new()
	bed.name = "Bed_" + slot
	var model: Node3D = (load(path) as PackedScene).instantiate()
	model.scale = BED_SCALE
	bed.add_child(model)
	bed.position = Vector3(at.x, FLOOR_TOP, at.z)
	bed.rotation.y = yaw
	var body := StaticBody3D.new()
	body.collision_mask = 0
	var box := BoxShape3D.new()
	box.size = Vector3(BED_SIZE.x, MATTRESS_TOP, BED_SIZE.z)
	var shape := CollisionShape3D.new()
	shape.shape = box
	shape.position.y = MATTRESS_TOP * 0.5
	body.add_child(shape)
	bed.add_child(body)
	add_child(bed)
	bed.set_meta("mattress_top", MATTRESS_TOP)
	bed.set_meta("bed_size", BED_SIZE)
	bed.set_meta("side_local", side)
	bed.set_meta("house", home)
	bed.set_meta("slot", slot)
	return bed


func _add_home() -> void:
	var home: Node3D = TentHome.new()
	home.name = "HouseInterior"
	home.furnish = false
	home.transform = Transform3D(Basis(Vector3.UP, PI).scaled(Vector3.ONE * 10.0), Vector3.ZERO)
	var k := 0.1
	home.floor_y = FLOOR_TOP * k
	home.floors.append(Rect2(-(HALF_X - 0.2) * k, -(HALF_Z - 0.2) * k, (HALF_X - 0.2) * 2.0 * k, (HALF_Z - 0.2) * 2.0 * k))
	home.doorway = Vector3(0.0, FLOOR_TOP * k, HALF_Z * k)
	home.door_width = DOOR_WIDTH * k
	home.approach = Vector3(0.0, 0.0, (HALF_Z + 1.5) * k)
	home.set_meta("reserved_for", OWNER)
	var clear := BED_SIZE.x * 0.5 + 0.25
	home.bed = _bed(home, CANOPY_BED, Vector3(0.0, 0.0, HALF_Z - 1.25), PI, "lodge_main", Vector3(clear, 0, 0))
	home._extra_beds.append(_bed(home, DOUBLE_BED, Vector3(HALF_X - 1.25, 0.0, 0.3), -PI * 0.5, "lodge_right", Vector3(clear, 0, 0)))
	home._extra_beds.append(_bed(home, DOUBLE_BED, Vector3(-HALF_X + 1.25, 0.0, 0.3), PI * 0.5, "lodge_left", Vector3(clear, 0, 0)))
	add_child(home)
