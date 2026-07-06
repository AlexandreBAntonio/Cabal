extends Node3D
## Apresentação do training dummy: flash branco no rig inteiro ao ser
## atingido, HP bar flutuante, balanço no stun, tombo na morte e respawn.

@onready var sim: DummySim = get_parent()
@onready var rig: DummyRig = $Rig
@onready var bar_fill: MeshInstance3D = $BarAnchor/Fill
@onready var bar_bg: MeshInstance3D = $BarAnchor/Bg

var _flash_mat := StandardMaterial3D.new()
var _saved_mats: Array[Material] = []

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
	Fx.damage_number(sim.global_position + Vector3(0.0, 2.4, 0.0), amount, is_crit)
	if _saved_mats.is_empty():
		for m in rig.meshes:
			_saved_mats.append(m.material_override)
			m.material_override = _flash_mat
		get_tree().create_timer(0.07).timeout.connect(_clear_flash)

func _clear_flash() -> void:
	if not is_instance_valid(rig):
		return
	for i in rig.meshes.size():
		rig.meshes[i].material_override = _saved_mats[i]
	_saved_mats.clear()

func _on_hp_changed(current: float, max_value: float) -> void:
	bar_fill.scale.x = maxf(current / max_value, 0.001)

func _on_stunned(duration: float) -> void:
	var tw := create_tween()
	tw.tween_property(rig, "rotation:z", 0.14, 0.06)
	tw.tween_property(rig, "rotation:z", -0.11, 0.1)
	tw.tween_property(rig, "rotation:z", 0.0, minf(duration, 0.25))

func _on_died() -> void:
	var tw := create_tween()
	tw.tween_property(rig, "rotation:x", -PI * 0.5, 0.4).set_ease(Tween.EASE_IN)
	bar_fill.visible = false
	bar_bg.visible = false

func _on_respawned() -> void:
	rig.rotation = Vector3.ZERO
	bar_fill.visible = true
	bar_bg.visible = true
