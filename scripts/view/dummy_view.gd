extends Node3D
## Apresentação do training dummy: flash branco ao ser atingido, HP bar
## flutuante, números de dano e reação a stun/morte/respawn.

@onready var sim: DummySim = get_parent()
@onready var mesh: MeshInstance3D = $Mesh
@onready var bar_fill: MeshInstance3D = $BarAnchor/Fill
@onready var bar_bg: MeshInstance3D = $BarAnchor/Bg

var _flash_mat := StandardMaterial3D.new()

func _ready() -> void:
	_flash_mat.albedo_color = Color.WHITE
	_flash_mat.emission_enabled = true
	_flash_mat.emission = Color.WHITE
	_flash_mat.emission_energy_multiplier = 2.5
	sim.damaged.connect(_on_damaged)
	sim.hp_changed.connect(_on_hp_changed)
	sim.stunned.connect(_on_stunned)
	sim.died.connect(_on_died)
	sim.respawned.connect(_on_respawned)

func _on_damaged(amount: float, is_crit: bool, _heavy: bool) -> void:
	Fx.damage_number(sim.global_position + Vector3(0.0, 2.1, 0.0), amount, is_crit)
	mesh.material_override = _flash_mat
	get_tree().create_timer(0.07).timeout.connect(_clear_flash)

func _clear_flash() -> void:
	if is_instance_valid(mesh):
		mesh.material_override = null

func _on_hp_changed(current: float, max_value: float) -> void:
	bar_fill.scale.x = maxf(current / max_value, 0.001)

func _on_stunned(duration: float) -> void:
	# balança o mesh pra vender o stun/stagger
	var tw := create_tween()
	tw.tween_property(mesh, "rotation:z", 0.12, 0.06)
	tw.tween_property(mesh, "rotation:z", -0.1, 0.1)
	tw.tween_property(mesh, "rotation:z", 0.0, minf(duration, 0.25))

func _on_died() -> void:
	var tw := create_tween()
	tw.tween_property(mesh, "rotation:x", -PI / 2.0, 0.35).set_ease(Tween.EASE_OUT)
	bar_fill.visible = false
	bar_bg.visible = false

func _on_respawned() -> void:
	mesh.rotation = Vector3.ZERO
	mesh.scale = Vector3.ONE
	bar_fill.visible = true
	bar_bg.visible = true
