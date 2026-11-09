extends Node3D
## The Mare Fair crew's lodge tent beside their balloon, a real home with three double beds. The
## game puts two sleepers in each bed, the player and his partner in the first. Striped like the
## balloon. The door faces -Z. Built in code, and modelled on Trixie's wagon
## (world/buildings/trixie_wagon.gd). Its HouseInterior is the game's own authored home script,
## made directly: mod scripts must never extend a game script, which breaks the packaged game.

const HOME_SCRIPT := "res://world/buildings/authored_home.gd"
const HOME_KIND := "mare_fair_tent"
const DOORWAY_SCRIPT := "res://world/buildings/open_doorway.gd"
const PLACE_ID := "house:mare_fair_tent"
## Beside the road on the town side of the hill, the front wall parallel to it and the door facing it.
const POSE := Vector3(187.0, -1.7, -346.5)
const YAW := 2.93
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
const TIMBER := Color(0.42, 0.27, 0.15)
const BEAM := 0.18
## The canvas is two skins this far apart, so the walls and door edges have some thickness.
const CANVAS := 0.08
const POLE_RADIUS := 0.07
const TABLE := "res://world/buildings/fluttershy/interior/round_table.glb"
const TABLE_SCALE := 1.5
const TABLE_TOP := 0.537
const TABLE_AT := Vector3(2.9, 0.0, -2.5)
const LAMP := "res://world/props/lamps/kit_lamp.gd"
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
	node.rotation.y = YAW


func _ready() -> void:
	_shell()
	_furnish()
	_add_home()
	_poster()
	set_process(true)


func _exit_tree() -> void:
	if is_inside_tree(): get_tree().call_group("grass_footprints", "remove_exclusion", GRASS_TOKEN)


func _process(_delta: float) -> void:
	if Engine.get_process_frames() % 15 != 0: return
	if _landed:
		# Grass can be rebuilt as the player travels; re-registering an unchanged footprint is free.
		get_tree().call_group("grass_footprints", "add_exclusion", GRASS_TOKEN, global_transform, Vector2(HALF_X + 0.15, HALF_Z + 0.15))
		return
	# The tent stands on its levelled pad (site_pad.gd), so it takes the pad's height rather than
	# whatever ground a ray finds before the pad has been levelled.
	global_position.y = POSE.y
	_landed = true


func _quad(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	_triangle(tool, a, b, c)
	_triangle(tool, a, c, d)


## One outward-facing triangle. The shader draws both sides and lights the inside as facing in.
func _triangle(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	var normal := (c - a).cross(b - a).normalized()
	var points := [a, b, c]
	if normal.dot((a + b + c) / 3.0 - Vector3(0, EAVES * 0.5, 0)) < 0.0:
		normal = -normal
		points = [a, c, b]
	for point: Vector3 in points:
		tool.set_normal(normal)
		tool.add_vertex(point)


func _shell() -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var x := HALF_X
	var z := HALF_Z
	var gap := DOOR_WIDTH * 0.5
	_skin(tool, x, z, EAVES, PEAK)
	_skin(tool, x - CANVAS, z - CANVAS, EAVES - CANVAS * 0.5, PEAK - CANVAS * 1.5)
	# The door's edges, joining the two skins.
	var inner := z - CANVAS
	_quad(tool, Vector3(-gap, 0, -z), Vector3(-gap, 0, -inner), Vector3(-gap, DOOR_HEIGHT, -inner), Vector3(-gap, DOOR_HEIGHT, -z))
	_quad(tool, Vector3(gap, 0, -inner), Vector3(gap, 0, -z), Vector3(gap, DOOR_HEIGHT, -z), Vector3(gap, DOOR_HEIGHT, -inner))
	_quad(tool, Vector3(-gap, DOOR_HEIGHT, -z), Vector3(gap, DOOR_HEIGHT, -z), Vector3(gap, DOOR_HEIGHT, -inner), Vector3(-gap, DOOR_HEIGHT, -inner))
	var mesh := MeshInstance3D.new()
	mesh.name = "Canvas"
	mesh.mesh = tool.commit()
	var material := ShaderMaterial.new()
	material.shader = STRIPES
	material.set_shader_parameter("stripe_count", 16.0)
	material.set_shader_parameter("canvas", 1.0)
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
	_frame()
	# The floorboards. Their solid goes on the walls' body: a shape under a plain node collides with nothing.
	FITTINGS.box(self, Vector3(0, FLOOR_TOP * 0.5 - 0.1, 0), Vector3(x * 2.0, FLOOR_TOP + 0.2, z * 2.0), WOOD)
	_wall(body, Vector3(0, FLOOR_TOP * 0.5 - 0.1, 0), Vector3(x * 2.0, FLOOR_TOP + 0.2, z * 2.0))
	var light := OmniLight3D.new()
	light.position = Vector3(0, 2.5, 0)
	light.light_color = Color(1.0, 0.86, 0.68)
	# A soft fill; the lantern on the table is the real light.
	light.light_energy = 0.45
	light.omni_range = 8.0
	add_child(light)


## One skin of canvas: walls with the door cut out of the front, and a roof rising to one peak.
func _skin(tool: SurfaceTool, x: float, z: float, eaves: float, peak_y: float) -> void:
	var gap := DOOR_WIDTH * 0.5
	# Back and sides.
	_quad(tool, Vector3(x, 0, z), Vector3(-x, 0, z), Vector3(-x, eaves, z), Vector3(x, eaves, z))
	_quad(tool, Vector3(x, 0, -z), Vector3(x, 0, z), Vector3(x, eaves, z), Vector3(x, eaves, -z))
	_quad(tool, Vector3(-x, 0, z), Vector3(-x, 0, -z), Vector3(-x, eaves, -z), Vector3(-x, eaves, z))
	# Front, around the door.
	_quad(tool, Vector3(-x, 0, -z), Vector3(-gap, 0, -z), Vector3(-gap, eaves, -z), Vector3(-x, eaves, -z))
	_quad(tool, Vector3(gap, 0, -z), Vector3(x, 0, -z), Vector3(x, eaves, -z), Vector3(gap, eaves, -z))
	_quad(tool, Vector3(-gap, DOOR_HEIGHT, -z), Vector3(gap, DOOR_HEIGHT, -z), Vector3(gap, eaves, -z), Vector3(-gap, eaves, -z))
	var peak := Vector3(0, peak_y, 0)
	var corners := [Vector3(-x, eaves, z), Vector3(x, eaves, z), Vector3(x, eaves, -z), Vector3(-x, eaves, -z)]
	for i in 4:
		_triangle(tool, corners[i], corners[(i + 1) % 4], peak)


## The game's round table in the front corner, with a lamp from the game's kit on it. The lamp
## moves into the home once it exists (_add_home), so the crew switch it like any household.
func _furnish() -> void:
	var table: Node3D = (load(TABLE) as PackedScene).instantiate()
	table.name = "Table"
	table.scale = Vector3.ONE * TABLE_SCALE
	table.position = Vector3(TABLE_AT.x, FLOOR_TOP, TABLE_AT.z)
	add_child(table)
	var body := StaticBody3D.new()
	body.name = "TableBody"
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = 0.464 * TABLE_SCALE
	cylinder.height = TABLE_TOP * TABLE_SCALE
	shape.shape = cylinder
	shape.position = Vector3(TABLE_AT.x, FLOOR_TOP + cylinder.height * 0.5, TABLE_AT.z)
	body.add_child(shape)
	add_child(body)
	var lamp: Variant = (load(LAMP) as Script).call("create", "table_lamp")
	if lamp is Node3D:
		(lamp as Node3D).name = "Lantern"
		(lamp as Node3D).position = Vector3(TABLE_AT.x, FLOOR_TOP + TABLE_TOP * TABLE_SCALE, TABLE_AT.z)
		add_child(lamp)


## A timber frame inside the canvas: a post in each corner, joined by beams along the top, and a
## centre pole holding up the peak.
func _frame() -> void:
	var inset := BEAM * 0.5 + 0.04 + CANVAS
	var x := HALF_X - inset
	var z := HALF_Z - inset
	var height := EAVES - FLOOR_TOP
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			FITTINGS.box(self, Vector3(sx * x, FLOOR_TOP + height * 0.5, sz * z), Vector3(BEAM, height, BEAM), TIMBER)
	var top := EAVES - BEAM * 0.5
	for sz: float in [-1.0, 1.0]:
		FITTINGS.box(self, Vector3(0, top, sz * z), Vector3(x * 2.0 + BEAM, BEAM, BEAM), TIMBER)
	for sx: float in [-1.0, 1.0]:
		FITTINGS.box(self, Vector3(sx * x, top, 0), Vector3(BEAM, BEAM, z * 2.0 + BEAM), TIMBER)
	FITTINGS.rod(self, Vector3(0, FLOOR_TOP, 0), Vector3(0, PEAK - CANVAS * 1.5, 0), POLE_RADIUS, TIMBER)


## Somepony keeps asking.
func _poster() -> void:
	var at := Vector3(2.9, 1.65, HALF_Z - CANVAS - 0.03)
	var paper := MeshInstance3D.new()
	paper.name = "GatorPoster"
	var quad := QuadMesh.new()
	quad.size = Vector2(1.3, 0.95)
	paper.mesh = quad
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.93, 0.87, 0.72)
	paper.material_override = material
	paper.position = at
	paper.rotation.y = PI
	add_child(paper)
	var text := Label3D.new()
	text.text = "gator mare is
NOT
a mascot"
	text.font_size = 72
	text.outline_size = 0
	text.pixel_size = 0.0022
	text.modulate = Color(0.32, 0.08, 0.08)
	text.shaded = true
	text.position = Vector3(0, 0, 0.01)
	paper.add_child(text)


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
	# House travel asks the home's parent for its "FrontDoor"; an open flap always lets ponies by.
	if get_node_or_null("FrontDoor") == null:
		var door := Node.new()
		door.name = "FrontDoor"
		door.set_script(load(DOORWAY_SCRIPT))
		add_child(door)
	var home: Node3D = (load(HOME_SCRIPT) as Script).new() as Node3D
	home.set("home_kind", HOME_KIND)
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
	# The household lamps runtime only switches lamps inside a house's own node.
	var lantern := get_node_or_null("Lantern")
	if lantern != null: lantern.reparent(home)
