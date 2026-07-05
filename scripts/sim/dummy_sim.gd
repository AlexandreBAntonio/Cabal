class_name DummySim
extends CharacterBody3D
## Simulação do training dummy: HP alto, imóvel, opcionalmente respawna.
## A apresentação (flash, HP bar, números de dano) reage via signals.

signal damaged(amount: float, is_crit: bool, heavy: bool)
signal stunned(duration: float)
signal hp_changed(current: float, max_value: float)
signal died
signal respawned

@export var max_hp := 5000.0
@export var respawn_enabled := false
@export var respawn_time := 5.0

var hp := 0.0
var alive := true
var stun_left := 0.0

func _ready() -> void:
	hp = max_hp
	add_to_group("enemies")

func is_alive() -> bool:
	return alive

func apply_damage(amount: float, is_crit := false, heavy := false) -> void:
	if not alive:
		return
	hp = maxf(hp - amount, 0.0)
	damaged.emit(amount, is_crit, heavy)
	hp_changed.emit(hp, max_hp)
	if hp <= 0.0:
		_die()

func apply_stun(duration: float) -> void:
	if not alive:
		return
	stun_left = maxf(stun_left, duration)
	stunned.emit(duration)

func _physics_process(delta: float) -> void:
	if stun_left > 0.0:
		stun_left -= delta

func _die() -> void:
	alive = false
	remove_from_group("enemies")
	# morto não bloqueia movimento nem recebe hits
	collision_layer = 0
	died.emit()
	if respawn_enabled:
		get_tree().create_timer(respawn_time).timeout.connect(_respawn)

func _respawn() -> void:
	hp = max_hp
	alive = true
	stun_left = 0.0
	collision_layer = 2
	add_to_group("enemies")
	hp_changed.emit(hp, max_hp)
	respawned.emit()
