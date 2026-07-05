extends Node3D
## Apresentação do jogador: reage a signals da simulação, nunca altera gameplay.
## Placeholders procedurais (punch de escala, tint no Berserk) + AnimationPlayer
## esqueletado: quando existir animação com o nome esperado (attack_1..3,
## skill_1..5), ela toca no lugar do placeholder — ponto de integração Mixamo.

@export var sim_path: NodePath = ".."

@onready var sim: GladiatorSim = get_node(sim_path)
@onready var mesh: MeshInstance3D = $Mesh
@onready var anim: AnimationPlayer = $AnimationPlayer

var _base_color: Color

func _ready() -> void:
	_base_color = (mesh.get_active_material(0) as StandardMaterial3D).albedo_color
	sim.basic_attack_performed.connect(_on_basic_attack)
	sim.skill_used.connect(_on_skill_used)
	sim.dealt_damage.connect(_on_dealt_damage)
	sim.buff_changed.connect(_on_buff_changed)

func _on_basic_attack(chain_index: int) -> void:
	_play_or_punch("attack_%d" % (chain_index + 1), 1.0 + 0.08 * chain_index)

func _on_skill_used(slot: int, _skill: SkillData) -> void:
	_play_or_punch("skill_%d" % slot, 1.25)

## Hit stop e screen shake: o "peso" do combate.
func _on_dealt_damage(_victim: Node3D, _amount: float, is_crit: bool, heavy: bool) -> void:
	Fx.hit_stop(0.12 if heavy else 0.06)
	if heavy:
		Fx.shake(1.0)
	elif is_crit:
		Fx.shake(0.35)

func _on_buff_changed(active: bool, _time_left: float) -> void:
	var mat := mesh.get_active_material(0) as StandardMaterial3D
	mat.albedo_color = Color(0.9, 0.25, 0.2) if active else _base_color

func _play_or_punch(anim_name: String, strength: float) -> void:
	if anim.has_animation(anim_name):
		anim.play(anim_name)
		return
	# placeholder: "punch" de escala no mesh
	mesh.scale = Vector3(1.0 + 0.12 * strength, 1.0 - 0.08 * strength, 1.0 + 0.12 * strength)
	var tw := create_tween()
	tw.tween_property(mesh, "scale", Vector3.ONE, 0.2).set_ease(Tween.EASE_OUT)
