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

var yaw := 0.0
var pitch := -0.55
var zoom_dist := 6.5

var _shake := 0.0

@onready var _follow: Node3D = get_node(follow_path)
@onready var _arm: SpringArm3D = $SpringArm3D
@onready var _cam: Camera3D = $SpringArm3D/Camera3D

func _ready() -> void:
	# top_level: a rotação do personagem não arrasta a câmera
	top_level = true
	Fx.camera_rig = self

func _process(delta: float) -> void:
	global_position = _follow.global_position + Vector3(0.0, height_offset, 0.0)
	rotation = Vector3(pitch, yaw, 0.0)
	_arm.spring_length = lerpf(_arm.spring_length, zoom_dist, minf(10.0 * delta, 1.0))

	if _shake > 0.0:
		_shake = maxf(_shake - 3.5 * delta, 0.0)
		_cam.h_offset = randf_range(-1.0, 1.0) * _shake * 0.12
		_cam.v_offset = randf_range(-1.0, 1.0) * _shake * 0.12
	else:
		_cam.h_offset = 0.0
		_cam.v_offset = 0.0

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
