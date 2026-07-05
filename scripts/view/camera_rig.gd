class_name CameraRig
extends Node3D
## Apresentação: câmera orbital third-person estilo Cabal (atrás e acima).
## NÃO lê Input — recebe orbit()/zoom() do PlayerController.
## SpringArm3D cuida da colisão da câmera com o cenário.

@export var follow_path: NodePath = ".."
@export var min_zoom := 2.5
@export var max_zoom := 12.0
@export var zoom_step := 0.8
@export var min_pitch := -1.25
@export var max_pitch := -0.12
@export var height_offset := 1.6

const BASE_FOV := 72.0

var yaw := 0.0
var pitch := -0.55
var zoom_dist := 6.5

var _shake := 0.0
var _fov_kick := 0.0
var _sim: GladiatorSim = null

@onready var _follow: Node3D = get_node(follow_path)
@onready var _arm: SpringArm3D = $SpringArm3D
@onready var _cam: Camera3D = $SpringArm3D/Camera3D

func _ready() -> void:
	# top_level: a rotação do personagem não arrasta a câmera
	top_level = true
	Fx.camera_rig = self
	global_position = _follow.global_position + Vector3(0.0, height_offset, 0.0)
	_cam.fov = BASE_FOV
	_sim = _follow as GladiatorSim
	if _sim != null:
		_sim.skill_used.connect(_on_skill_used)

func _process(delta: float) -> void:
	# follow suavizado: mata o "grude" duro no personagem
	var anchor := _follow.global_position + Vector3(0.0, height_offset, 0.0)
	global_position = global_position.lerp(anchor, 1.0 - exp(-14.0 * delta))
	rotation = Vector3(pitch, yaw, 0.0)
	_arm.spring_length = lerpf(_arm.spring_length, zoom_dist, minf(10.0 * delta, 1.0))

	# FOV dinâmico: abre com velocidade e dá "kick" no dash
	_fov_kick = move_toward(_fov_kick, 0.0, 26.0 * delta)
	var speed_ratio := 0.0
	if _sim != null:
		speed_ratio = clampf(Vector3(_sim.velocity.x, 0.0, _sim.velocity.z).length() / _sim.move_speed, 0.0, 1.5)
	_cam.fov = BASE_FOV + speed_ratio * 3.0 + _fov_kick

	if _shake > 0.0:
		_shake = maxf(_shake - 3.5 * delta, 0.0)
		_cam.h_offset = randf_range(-1.0, 1.0) * _shake * 0.12
		_cam.v_offset = randf_range(-1.0, 1.0) * _shake * 0.12
	else:
		_cam.h_offset = 0.0
		_cam.v_offset = 0.0

func _on_skill_used(_slot: int, sk: SkillData) -> void:
	if sk.type == SkillData.Type.DASH:
		_fov_kick = 9.0

func orbit(relative: Vector2) -> void:
	yaw -= relative.x
	pitch = clampf(pitch - relative.y, min_pitch, max_pitch)

func zoom(direction: float) -> void:
	zoom_dist = clampf(zoom_dist + direction * zoom_step, min_zoom, max_zoom)

func add_shake(strength: float) -> void:
	_shake = maxf(_shake, strength)

func get_camera() -> Camera3D:
	return _cam

func get_camera_basis() -> Basis:
	return _cam.global_transform.basis
