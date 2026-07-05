class_name PlayerController
extends Node
## Camada de INPUT: o ÚNICO lugar do projeto que lê Input.
## Traduz teclado/mouse em comandos para a simulação (cmd_*) e em
## chamadas de orbit/zoom para a câmera (que não lê Input sozinha).

const CAMERA_SENSITIVITY := 0.005
const RAY_LENGTH := 200.0

@export var sim_path: NodePath = ".."
@export var camera_rig_path: NodePath = "../CameraRig"

@onready var sim: GladiatorSim = get_node(sim_path)
@onready var rig: CameraRig = get_node(camera_rig_path)

var _orbiting := false

func _physics_process(_delta: float) -> void:
	# WASD relativo à câmera -> direção no mundo
	var iv := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var cam_basis := rig.get_camera_basis()
	var fwd := -cam_basis.z
	fwd.y = 0.0
	fwd = fwd.normalized()
	var right := cam_basis.x
	right.y = 0.0
	right = right.normalized()
	sim.cmd_move(right * iv.x + fwd * -iv.y)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_RIGHT:
				_orbiting = event.pressed
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if _orbiting else Input.MOUSE_MODE_VISIBLE
			MOUSE_BUTTON_LEFT:
				if event.pressed:
					_pick_target(event.position)
			MOUSE_BUTTON_WHEEL_UP:
				if event.pressed:
					rig.zoom(-1.0)
			MOUSE_BUTTON_WHEEL_DOWN:
				if event.pressed:
					rig.zoom(1.0)
		return

	if event is InputEventMouseMotion and _orbiting:
		rig.orbit(event.relative * CAMERA_SENSITIVITY)
		return

	if event.is_action_pressed("basic_attack"):
		sim.cmd_basic_attack()
	elif event.is_action_pressed("skill_1"):
		sim.cmd_use_skill(1)
	elif event.is_action_pressed("skill_2"):
		sim.cmd_use_skill(2)
	elif event.is_action_pressed("skill_3"):
		sim.cmd_use_skill(3)
	elif event.is_action_pressed("skill_4"):
		sim.cmd_use_skill(4)
	elif event.is_action_pressed("skill_5"):
		sim.cmd_use_skill(5)
	elif event.is_action_pressed("combo_mode"):
		sim.cmd_toggle_combo_mode()
	elif event.is_action_pressed("target_tab"):
		sim.cmd_cycle_target()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("autoface_toggle"):
		sim.cmd_toggle_auto_face()

## Clique esquerdo em inimigo: raycast da câmera e seleciona como target.
func _pick_target(screen_pos: Vector2) -> void:
	var cam := rig.get_camera()
	var from := cam.project_ray_origin(screen_pos)
	var to := from + cam.project_ray_normal(screen_pos) * RAY_LENGTH
	var query := PhysicsRayQueryParameters3D.create(from, to, 2)  # layer 2 = inimigos
	var hit := sim.get_world_3d().direct_space_state.intersect_ray(query)
	if hit and hit.collider.is_in_group("enemies") and hit.collider.is_alive():
		sim.cmd_set_target(hit.collider)
