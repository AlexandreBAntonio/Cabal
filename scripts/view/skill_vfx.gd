extends Node3D
## VFX procedurais das skills — zero assets externos, tudo gerado em código.
## Apresentação pura: reage a signals/estado da simulação, nunca altera gameplay.
## Cores em HDR (>1.0) de propósito: o glow do Environment faz o bloom.

@export var sim_path: NodePath = ".."

@onready var sim: GladiatorSim = get_node(sim_path)

var _berserk_aura: GPUParticles3D
var _charge_trail: GPUParticles3D

func _ready() -> void:
	sim.skill_used.connect(_on_skill_used)
	sim.dealt_damage.connect(_on_dealt_damage)
	sim.buff_changed.connect(_on_buff_changed)
	sim.basic_attack_performed.connect(_on_basic_attack)
	_berserk_aura = _make_attached_emitter(Color(2.2, 0.5, 0.35), 26, 0.14, 1.4)
	_charge_trail = _make_attached_emitter(Color(0.8, 1.4, 2.4), 46, 0.24, 0.2)

func _process(_delta: float) -> void:
	# rastro do Charge só enquanto a simulação está no dash
	_charge_trail.emitting = sim.state == GladiatorSim.State.DASHING

func _on_skill_used(slot: int, sk: SkillData) -> void:
	match slot:
		2:
			_whirlwind_ring(sk.duration)
		4:
			var fwd: Vector3 = -sim.global_transform.basis.z
			var center: Vector3 = sim.global_position + fwd * sk.aoe_forward_offset
			_telegraph(center, sk.aoe_radius, maxf(sk.cast_time, 0.2))
			# impacto no chão quando o cast termina
			get_tree().create_timer(sk.cast_time).timeout.connect(func():
				_shockwave(center, sk.aoe_radius, Color(2.0, 1.1, 0.4, 0.9))
				_burst(center + Vector3.UP * 0.3, Color(1.4, 1.1, 0.8), 40, 0.3, 8.0, 0.7, 70.0, -4.0))

func _on_basic_attack(_chain_index: int) -> void:
	var fwd: Vector3 = -sim.global_transform.basis.z
	_burst(sim.global_position + fwd * 1.2 + Vector3.UP * 1.2,
		Color(1.8, 1.8, 2.2), 8, 0.1, 3.0, 0.25, 60.0, 0.0)

func _on_dealt_damage(victim: Node3D, _amount: float, is_crit: bool, heavy: bool) -> void:
	var pos: Vector3 = victim.global_position + Vector3.UP * 1.2
	if heavy:
		_burst(pos, Color(2.2, 1.2, 0.4), 26, 0.22, 7.0, 0.5, 100.0, -5.0)
		_shockwave(victim.global_position, 2.0, Color(1.8, 0.9, 0.4, 0.8))
	elif is_crit:
		_burst(pos, Color(2.6, 2.0, 0.5), 22, 0.18, 6.0, 0.45, 120.0, -5.0)
	else:
		_burst(pos, Color(2.0, 1.8, 1.3), 12, 0.13, 4.5, 0.35, 100.0, -6.0)

func _on_buff_changed(active: bool, _time_left: float) -> void:
	_berserk_aura.emitting = active
	if active:
		_shockwave(sim.global_position, 1.6, Color(2.4, 0.6, 0.4, 0.9))

# ------------------------------------------------------------------
# Fábrica de efeitos
# ------------------------------------------------------------------

## Explosão one-shot de partículas em um ponto do mundo (se autodestrói).
func _burst(pos: Vector3, color: Color, amount: int, size: float, speed: float,
		life: float, spread: float, gravity_y: float) -> void:
	var p := GPUParticles3D.new()
	var m := ParticleProcessMaterial.new()
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	m.emission_sphere_radius = 0.25
	m.direction = Vector3.UP
	m.spread = spread
	m.initial_velocity_min = speed * 0.5
	m.initial_velocity_max = speed
	m.gravity = Vector3(0.0, gravity_y, 0.0)
	m.scale_min = 0.5
	m.scale_max = 1.0
	m.color = color
	p.process_material = m
	p.draw_pass_1 = _particle_quad(size)
	p.amount = amount
	p.lifetime = life
	p.one_shot = true
	p.explosiveness = 1.0
	get_tree().current_scene.add_child(p)
	p.global_position = pos
	p.emitting = true
	p.finished.connect(p.queue_free)

## Emissor preso ao personagem (aura do Berserk, rastro do Charge).
func _make_attached_emitter(color: Color, amount: int, size: float, up_speed: float) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	var m := ParticleProcessMaterial.new()
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	m.emission_sphere_radius = 0.5
	m.direction = Vector3.UP
	m.spread = 25.0
	m.initial_velocity_min = up_speed * 0.5
	m.initial_velocity_max = up_speed
	m.gravity = Vector3.ZERO
	m.scale_min = 0.6
	m.scale_max = 1.0
	m.color = color
	p.process_material = m
	p.draw_pass_1 = _particle_quad(size)
	p.amount = amount
	p.lifetime = 0.5
	p.local_coords = false   # partículas ficam pra trás quando o corpo se move
	p.emitting = false
	p.position = Vector3(0.0, 1.0, 0.0)
	add_child(p)
	return p

## Anel de lâminas girando ao redor do personagem (Whirlwind).
func _whirlwind_ring(duration: float) -> void:
	var p := GPUParticles3D.new()
	var m := ParticleProcessMaterial.new()
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	m.emission_ring_axis = Vector3.UP
	m.emission_ring_radius = 2.4
	m.emission_ring_inner_radius = 1.2
	m.emission_ring_height = 0.5
	m.initial_velocity_min = 0.0
	m.initial_velocity_max = 0.5
	m.tangential_accel_min = 22.0
	m.tangential_accel_max = 30.0
	m.gravity = Vector3.ZERO
	m.scale_min = 0.5
	m.scale_max = 1.0
	m.color = Color(0.9, 1.6, 2.6)
	p.process_material = m
	p.draw_pass_1 = _particle_quad(0.2)
	p.amount = 90
	p.lifetime = 0.55
	p.position = Vector3(0.0, 1.0, 0.0)
	add_child(p)
	p.emitting = true
	get_tree().create_timer(duration).timeout.connect(func():
		if is_instance_valid(p):
			p.emitting = false)
	get_tree().create_timer(duration + 0.8).timeout.connect(func():
		if is_instance_valid(p):
			p.queue_free())

## Onda de choque expansiva no chão.
func _shockwave(pos: Vector3, radius: float, color: Color) -> void:
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.85
	torus.outer_radius = 1.0
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = color
	ring.mesh = torus
	ring.material_override = mat
	get_tree().current_scene.add_child(ring)
	ring.global_position = pos + Vector3(0.0, 0.12, 0.0)
	ring.scale = Vector3(0.5, 0.25, 0.5)
	var tw := ring.create_tween()
	tw.set_parallel(true)
	tw.tween_property(ring, "scale", Vector3(radius, 0.25, radius), 0.35).set_ease(Tween.EASE_OUT)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.38)
	tw.chain().tween_callback(ring.queue_free)

## Aviso no chão da área do Earthquake durante o cast.
func _telegraph(pos: Vector3, radius: float, duration: float) -> void:
	var disc := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = 0.04
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1.6, 0.7, 0.2, 0.0)
	disc.mesh = cyl
	disc.material_override = mat
	get_tree().current_scene.add_child(disc)
	disc.global_position = pos + Vector3(0.0, 0.06, 0.0)
	var tw := disc.create_tween()
	tw.tween_property(mat, "albedo_color:a", 0.3, duration * 0.7)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.15)
	tw.tween_callback(disc.queue_free)

## Quad billboard emissivo usado como partícula.
func _particle_quad(size: float) -> QuadMesh:
	var quad := QuadMesh.new()
	quad.size = Vector2(size, size)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.vertex_color_use_as_albedo = true
	quad.material = mat
	return quad
