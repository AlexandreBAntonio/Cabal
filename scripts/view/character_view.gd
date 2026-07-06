extends Node3D
## Apresentação do jogador: anima o rig procedural conforme estado/signals da
## simulação. AnimationPlayer segue esqueletado: se existir animação com o
## nome esperado (attack_1..3, skill_1..5), ela tem prioridade — ponto de
## integração pros modelos reais (Mixamo).

@export var sim_path: NodePath = ".."

@onready var sim: GladiatorSim = get_node(sim_path)
@onready var rig: PlayerRig = $Rig
@onready var anim: AnimationPlayer = $AnimationPlayer

var _walk_phase := 0.0
var _attack_tw: Tween = null

func _ready() -> void:
	sim.basic_attack_performed.connect(_on_basic_attack)
	sim.skill_used.connect(_on_skill_used)
	sim.dealt_damage.connect(_on_dealt_damage)
	sim.buff_changed.connect(_on_buff_changed)

func _process(delta: float) -> void:
	var hv := Vector3(sim.velocity.x, 0.0, sim.velocity.z)
	var ratio := clampf(hv.length() / sim.move_speed, 0.0, 1.5)

	# ciclo de caminhada: pernas/braços em contra-fase + bob do corpo
	if ratio > 0.05:
		_walk_phase += delta * (3.0 + 9.0 * ratio)
	var swing := sin(_walk_phase) * 0.7 * ratio
	rig.leg_l.rotation.x = swing
	rig.leg_r.rotation.x = -swing
	if not _attacking():
		rig.arm_l.rotation.x = lerpf(rig.arm_l.rotation.x, -swing * 0.55, minf(12.0 * delta, 1.0))
		rig.arm_r.rotation.x = lerpf(rig.arm_r.rotation.x, swing * 0.55, minf(12.0 * delta, 1.0))
		rig.arm_l.rotation.z = lerpf(rig.arm_l.rotation.z, 0.08, minf(12.0 * delta, 1.0))
		rig.arm_r.rotation.z = lerpf(rig.arm_r.rotation.z, -0.08, minf(12.0 * delta, 1.0))
	var breathe := sin(Time.get_ticks_msec() / 600.0) * 0.012
	rig.body.position.y = absf(sin(_walk_phase)) * 0.06 * ratio + breathe

	# inclinação do corpo na direção do movimento
	var local := sim.global_transform.basis.inverse() * hv
	var t := minf(10.0 * delta, 1.0)
	rotation.x = lerpf(rotation.x, local.z / sim.move_speed * 0.08, t)
	rotation.z = lerpf(rotation.z, -local.x / sim.move_speed * 0.06, t)

func _attacking() -> bool:
	return _attack_tw != null and _attack_tw.is_running()

func _on_basic_attack(chain_index: int) -> void:
	var anim_name := "attack_%d" % (chain_index + 1)
	if anim.has_animation(anim_name):
		anim.play(anim_name)
		return
	# corte procedural: ergue o braço da espada e desce em arco
	_kill_attack_tween()
	rig.arm_r.rotation.x = -2.4
	rig.arm_r.rotation.z = -0.5 + 0.35 * chain_index
	_attack_tw = create_tween()
	_attack_tw.tween_property(rig.arm_r, "rotation:x", 0.7, 0.1).set_ease(Tween.EASE_IN)
	_attack_tw.tween_property(rig.arm_r, "rotation:x", 0.0, 0.28).set_ease(Tween.EASE_OUT)
	_attack_tw.parallel().tween_property(rig.arm_r, "rotation:z", -0.08, 0.28)

func _on_skill_used(slot: int, skill: SkillData) -> void:
	var anim_name := "skill_%d" % slot
	if anim.has_animation(anim_name):
		anim.play(anim_name)
		return
	_kill_attack_tween()
	_attack_tw = create_tween()
	match slot:
		1:
			# Rising Shot: corte ascendente
			rig.arm_r.rotation.x = 0.9
			_attack_tw.tween_property(rig.arm_r, "rotation:x", -2.6, 0.16).set_ease(Tween.EASE_OUT)
			_attack_tw.tween_property(rig.arm_r, "rotation:x", 0.0, 0.35)
		2:
			# Whirlwind: braços abertos + corpo girando
			rig.arm_l.rotation.z = 1.3
			rig.arm_r.rotation.z = -1.3
			_attack_tw.tween_property(self, "rotation:y", rotation.y + TAU * 4.0, skill.duration)
			_attack_tw.tween_callback(func():
				rotation.y = 0.0
				rig.arm_l.rotation.z = 0.08
				rig.arm_r.rotation.z = -0.08)
		3:
			# Charge: espada apontada à frente
			rig.arm_r.rotation.x = -1.5
			_attack_tw.tween_interval(0.5)
			_attack_tw.tween_property(rig.arm_r, "rotation:x", 0.0, 0.25)
		4:
			# Earthquake: golpe com as duas mãos de cima pra baixo
			rig.arm_r.rotation.x = -2.8
			rig.arm_l.rotation.x = -2.8
			_attack_tw.tween_interval(maxf(skill.cast_time - 0.1, 0.05))
			_attack_tw.tween_property(rig.arm_r, "rotation:x", 0.9, 0.08).set_ease(Tween.EASE_IN)
			_attack_tw.parallel().tween_property(rig.arm_l, "rotation:x", 0.9, 0.08).set_ease(Tween.EASE_IN)
			_attack_tw.tween_property(rig.arm_r, "rotation:x", 0.0, 0.3)
			_attack_tw.parallel().tween_property(rig.arm_l, "rotation:x", 0.0, 0.3)
		5:
			# Berserk: flexiona os dois braços
			rig.arm_l.rotation.x = -1.8
			rig.arm_r.rotation.x = -1.8
			_attack_tw.tween_interval(0.35)
			_attack_tw.tween_property(rig.arm_l, "rotation:x", 0.0, 0.3)
			_attack_tw.parallel().tween_property(rig.arm_r, "rotation:x", 0.0, 0.3)

## Hit stop e screen shake: o "peso" do combate.
func _on_dealt_damage(_victim: Node3D, _amount: float, is_crit: bool, heavy: bool) -> void:
	Fx.hit_stop(0.12 if heavy else 0.06)
	if heavy:
		Fx.shake(1.0)
	elif is_crit:
		Fx.shake(0.35)

func _on_buff_changed(active: bool, _time_left: float) -> void:
	rig.set_berserk(active)

func _kill_attack_tween() -> void:
	if _attack_tw != null and _attack_tw.is_valid():
		_attack_tw.kill()
