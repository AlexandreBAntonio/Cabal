extends Node3D
## Cenário da arena construído por código (visual apenas — colisão fica nos
## StaticBody da cena): muralhas com ameias, arquibancadas, pilares com
## braseiros, tochas com fogo e estandartes. Texturas via FastNoiseLite.

const HALF := 30.5           ## meia-largura da arena (alinha com colisores)

var _stone := StandardMaterial3D.new()
var _stone_dark := StandardMaterial3D.new()
var _wood := StandardMaterial3D.new()
var _banner := StandardMaterial3D.new()
var _ember := StandardMaterial3D.new()

func _ready() -> void:
	_make_materials()
	_build_walls()
	_build_stands()
	_build_pillars()
	_build_torches()
	_build_banners()
	_build_center_ring()

func _make_materials() -> void:
	var noise := FastNoiseLite.new()
	noise.frequency = 0.05
	var tex := NoiseTexture2D.new()
	tex.noise = noise
	tex.seamless = true
	var ntex := NoiseTexture2D.new()
	ntex.noise = noise
	ntex.seamless = true
	ntex.as_normal_map = true
	ntex.bump_strength = 6.0

	_stone.albedo_color = Color(0.42, 0.40, 0.45)
	_stone.albedo_texture = tex
	_stone.normal_enabled = true
	_stone.normal_texture = ntex
	_stone.roughness = 0.85
	_stone_dark.albedo_color = Color(0.26, 0.25, 0.3)
	_stone_dark.albedo_texture = tex
	_stone_dark.roughness = 0.9
	_wood.albedo_color = Color(0.35, 0.24, 0.15)
	_wood.roughness = 0.9
	_banner.albedo_color = Color(0.55, 0.1, 0.1)
	_banner.roughness = 0.85
	_banner.cull_mode = BaseMaterial3D.CULL_DISABLED
	_ember.albedo_color = Color(1.0, 0.55, 0.2)
	_ember.emission_enabled = true
	_ember.emission = Color(1.0, 0.45, 0.15)
	_ember.emission_energy_multiplier = 2.5

func _build_walls() -> void:
	# 4 muralhas + ameias no topo
	for side in 4:
		var wall := _box(Vector3(0, 1.6, 0), Vector3(HALF * 2.0 + 1.0, 3.2, 1.2), _stone)
		_place_on_side(wall, side, HALF)
		var m := -HALF + 1.5
		while m <= HALF - 1.5:
			var merlon := _box(Vector3(0, 3.5, 0), Vector3(0.9, 0.6, 1.0), _stone)
			_place_on_side(merlon, side, HALF, m)
			m += 2.6

func _build_stands() -> void:
	# 3 degraus de arquibancada atrás das muralhas
	for side in 4:
		for step in 3:
			var dist := HALF + 2.5 + step * 2.8
			var h := 2.2 + step * 1.6
			var stand := _box(Vector3(0, h * 0.5, 0), Vector3(dist * 2.0 + 2.0, h, 2.8), _stone_dark)
			_place_on_side(stand, side, dist)

func _build_pillars() -> void:
	# pilares dos cantos (visual dos colisores em ±29) com braseiro no topo
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var base := Vector3(29.0 * sx, 0.0, 29.0 * sz)
			var pillar := MeshInstance3D.new()
			var mesh := CylinderMesh.new()
			mesh.top_radius = 0.85
			mesh.bottom_radius = 1.2
			mesh.height = 7.0
			pillar.mesh = mesh
			pillar.material_override = _stone
			pillar.position = base + Vector3(0, 3.5, 0)
			add_child(pillar)
			_box(base + Vector3(0, 7.1, 0), Vector3(2.2, 0.35, 2.2), _stone_dark)
			var bowl := _box(base + Vector3(0, 7.45, 0), Vector3(1.2, 0.35, 1.2), _ember)
			_flame(bowl.global_position + Vector3(0, 0.3, 0), 2.2, 24)
			_fire_light(base + Vector3(0, 8.2, 0), 2.0, 18.0)

func _build_torches() -> void:
	# tochas no topo das muralhas, 3 por lado
	for side in 4:
		for offset in [-18.0, 0.0, 18.0]:
			var pole := _box(Vector3(0, 3.8, 0), Vector3(0.12, 1.2, 0.12), _wood)
			_place_on_side(pole, side, HALF, offset)
			var cup := _box(Vector3(0, 4.4, 0), Vector3(0.3, 0.22, 0.3), _ember)
			_place_on_side(cup, side, HALF, offset)
			_flame(cup.global_position + Vector3(0, 0.2, 0), 1.0, 12)
			var lp := cup.global_position + Vector3(0, 0.6, 0)
			_fire_light(lp, 1.5, 11.0)

func _build_banners() -> void:
	# estandartes vermelhos pendurados na face interna das muralhas
	for side in 4:
		for offset in [-9.0, 9.0]:
			var cloth := _box(Vector3(0, 2.1, 0), Vector3(1.1, 2.0, 0.04), _banner)
			_place_on_side(cloth, side, HALF - 0.75, offset)

func _build_center_ring() -> void:
	# anel rúnico sutil no centro da arena
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 7.6
	torus.outer_radius = 7.9
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.15, 0.45, 0.8, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.2, 0.55, 0.9)
	mat.emission_energy_multiplier = 0.8
	ring.mesh = torus
	ring.material_override = mat
	ring.position = Vector3(0, 0.03, 0)
	ring.scale = Vector3(1, 0.08, 1)
	add_child(ring)

# ------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------

## Posiciona um nó em um dos 4 lados da arena (rotaciona o eixo junto).
func _place_on_side(node: Node3D, side: int, dist: float, along := 0.0) -> void:
	match side:
		0: node.position += Vector3(along, 0, -dist)
		1: node.position += Vector3(along, 0, dist)
		2:
			node.position += Vector3(dist, 0, along)
			node.rotation.y = PI * 0.5
		3:
			node.position += Vector3(-dist, 0, along)
			node.rotation.y = PI * 0.5

func _box(pos: Vector3, size: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	add_child(mi)
	return mi

func _flame(pos: Vector3, size_mult: float, amount: int) -> void:
	var p := GPUParticles3D.new()
	var m := ParticleProcessMaterial.new()
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	m.emission_sphere_radius = 0.18 * size_mult
	m.direction = Vector3.UP
	m.spread = 12.0
	m.initial_velocity_min = 0.8 * size_mult
	m.initial_velocity_max = 1.6 * size_mult
	m.gravity = Vector3.ZERO
	m.scale_min = 0.5
	m.scale_max = 1.0
	m.color = Color(2.4, 1.1, 0.3)
	p.process_material = m
	var quad := QuadMesh.new()
	quad.size = Vector2(0.16, 0.16) * size_mult
	var qm := StandardMaterial3D.new()
	qm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	qm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	qm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	qm.vertex_color_use_as_albedo = true
	quad.material = qm
	p.draw_pass_1 = quad
	p.amount = amount
	p.lifetime = 0.6
	add_child(p)
	p.global_position = pos
	p.emitting = true

func _fire_light(pos: Vector3, energy: float, range_m: float) -> void:
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.6, 0.3)
	l.light_energy = energy
	l.omni_range = range_m
	add_child(l)
	l.global_position = pos
