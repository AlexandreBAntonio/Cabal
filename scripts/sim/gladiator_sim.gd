class_name GladiatorSim
extends CharacterBody3D
## Camada de SIMULAÇÃO do Gladiador (GL). NUNCA lê Input diretamente:
## recebe comandos (cmd_*) do PlayerController — no futuro, bots ou rede
## usarão exatamente a mesma interface de comandos.

signal hp_changed(current: float, max_value: float)
signal mp_changed(current: float, max_value: float)
signal target_changed(new_target: Node3D)
signal skill_used(slot: int, skill: SkillData)
## reason: "no_target" | "out_of_range" | "no_mp" | "cooldown" | "busy"
signal skill_failed(slot: int, reason: String)
signal cooldown_started(slot: int, duration: float)
signal basic_attack_performed(chain_index: int)
signal dealt_damage(victim: Node3D, amount: float, is_crit: bool, heavy: bool)
signal buff_changed(active: bool, time_left: float)
signal combo_mode_changed(active: bool)
signal combo_linked(links: int, bonus: float)
signal combo_broken

# --- Stats iniciais do GL ---
@export var max_hp := 1000.0
@export var max_mp := 300.0
@export var base_attack := 50.0
@export var move_speed := 6.0
@export var mp_regen := 6.0
@export var crit_chance := 0.15
@export var crit_mult := 1.5

## Slots 1-5 (índices 0-4). Definidos como Resources em /data/skills.
@export var skills: Array[SkillData] = [
	preload("res://data/skills/rising_shot.tres"),
	preload("res://data/skills/whirlwind.tres"),
	preload("res://data/skills/charge.tres"),
	preload("res://data/skills/earthquake.tres"),
	preload("res://data/skills/berserk.tres"),
]

const ACCEL := 28.0
const DECEL := 22.0
const TURN_SPEED := 12.0
const GRAVITY := 20.0
const BASIC_RANGE := 2.6
const BASIC_DAMAGE: Array[float] = [50.0, 55.0, 70.0]
const BASIC_WINDUP := 0.18
const BASIC_RECOVER := 0.32
const CHAIN_WINDOW := 0.85       ## janela p/ encadear o próximo golpe básico
const TARGET_MAX_DIST := 25.0
const DASH_SPEED := 22.0
const DASH_IMPACT_DIST := 1.6

enum State { FREE, ATTACKING, CASTING, DASHING }

var hp := 0.0
var mp := 0.0
var state := State.FREE
var target: Node3D = null
var auto_face := true
var combo := ComboSystem.new()
var berserk_left := 0.0

var _move_dir := Vector3.ZERO
var _cooldowns := {}             ## slot -> tempo restante
var _chain_index := 0
var _chain_timer := 0.0
var _buff_damage_mult := 1.0
var _buff_attack_speed_mult := 1.0
var _dash_skill: SkillData = null
var _dash_bonus := 1.0
var _dash_traveled := 0.0
var _approach_active := false    ## golpe melee em andamento: fecha a distância sozinho
var _rng := RandomNumberGenerator.new()

@onready var _hitbox: Area3D = $SkillHitbox
@onready var _hitbox_shape: CollisionShape3D = $SkillHitbox/CollisionShape3D

func _ready() -> void:
	hp = max_hp
	mp = max_mp
	hp_changed.emit(hp, max_hp)
	mp_changed.emit(mp, max_mp)

func _physics_process(delta: float) -> void:
	_tick_timers(delta)
	combo.tick(delta)

	# alvo morreu/sumiu -> limpa
	if target != null and (not is_instance_valid(target) or not target.is_alive()):
		cmd_set_target(null)

	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	if state == State.DASHING:
		_dash_move(delta)
	else:
		_ground_move(delta)

	move_and_slide()

func _tick_timers(delta: float) -> void:
	for slot in _cooldowns.keys():
		_cooldowns[slot] = maxf(_cooldowns[slot] - delta, 0.0)
	if _chain_timer > 0.0:
		_chain_timer -= delta
		if _chain_timer <= 0.0:
			_chain_index = 0
	if berserk_left > 0.0:
		berserk_left -= delta
		if berserk_left <= 0.0:
			_buff_damage_mult = 1.0
			_buff_attack_speed_mult = 1.0
			buff_changed.emit(false, 0.0)
	if mp < max_mp:
		mp = minf(mp + mp_regen * delta, max_mp)
		mp_changed.emit(mp, max_mp)

func _ground_move(delta: float) -> void:
	# movimento travado durante combo (fiel ao Cabal) e durante ações
	var can_move := state == State.FREE and not combo.active
	var dir := _move_dir if can_move else Vector3.ZERO
	# targeting estilo Cabal: golpe melee dentro do alcance aproxima sozinho
	if _approach_active and _has_live_target() and _dist_to_target() > 1.6:
		dir = global_position.direction_to(target.global_position)
		dir.y = 0.0
		dir = dir.normalized()
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	var rate := ACCEL if dir.length() > 0.01 else DECEL
	horizontal = horizontal.move_toward(dir * move_speed, rate * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z

	if auto_face and target != null:
		_face_dir(global_position.direction_to(target.global_position), delta)
	elif dir.length() > 0.01:
		_face_dir(dir, delta)

func _dash_move(delta: float) -> void:
	if target == null or _dash_skill == null:
		_end_dash(false)
		return
	var to_target := target.global_position - global_position
	to_target.y = 0.0
	if to_target.length() <= DASH_IMPACT_DIST or _dash_traveled >= _dash_skill.dash_distance:
		_end_dash(to_target.length() <= DASH_IMPACT_DIST + 0.6)
		return
	var dir := to_target.normalized()
	velocity.x = dir.x * DASH_SPEED
	velocity.z = dir.z * DASH_SPEED
	_dash_traveled += DASH_SPEED * delta
	_face_dir(dir, delta * 2.0)

func _end_dash(impact: bool) -> void:
	var sk := _dash_skill
	var bonus := _dash_bonus
	_dash_skill = null
	velocity.x = 0.0
	velocity.z = 0.0
	state = State.FREE
	if impact and sk != null and _has_live_target():
		_deal_damage_to(target, sk.damage, sk.heavy_hit, bonus)
		if sk.stun_duration > 0.0:
			target.apply_stun(sk.stun_duration)

func _face_dir(dir: Vector3, delta: float) -> void:
	dir.y = 0.0
	if dir.length() < 0.01:
		return
	var yaw := atan2(-dir.x, -dir.z)
	rotation.y = lerp_angle(rotation.y, yaw, minf(TURN_SPEED * delta, 1.0))

func _face_target_instant() -> void:
	if target == null:
		return
	var dir := global_position.direction_to(target.global_position)
	dir.y = 0.0
	if dir.length() > 0.01:
		rotation.y = atan2(-dir.x, -dir.z)

# ------------------------------------------------------------------
# Interface de comandos (CommandInput) — usada pelo controller/bots
# ------------------------------------------------------------------

func cmd_move(world_dir: Vector3) -> void:
	world_dir.y = 0.0
	_move_dir = world_dir.limit_length(1.0)

func cmd_set_target(new_target: Node3D) -> void:
	if target == new_target:
		return
	target = new_target
	target_changed.emit(target)

## Tab: alterna entre inimigos vivos próximos, do mais perto pro mais longe.
func cmd_cycle_target() -> void:
	var enemies: Array = []
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.is_alive() and global_position.distance_to(e.global_position) <= TARGET_MAX_DIST:
			enemies.append(e)
	if enemies.is_empty():
		cmd_set_target(null)
		return
	enemies.sort_custom(func(a, b):
		return global_position.distance_squared_to(a.global_position) \
			< global_position.distance_squared_to(b.global_position))
	var idx := enemies.find(target)
	cmd_set_target(enemies[(idx + 1) % enemies.size()])

func cmd_toggle_auto_face() -> void:
	auto_face = not auto_face

func cmd_toggle_combo_mode() -> void:
	if combo.active:
		combo.stop()
		combo_mode_changed.emit(false)
	else:
		combo.start()
		combo_mode_changed.emit(true)

## Espaço: cadeia de 3 golpes (50/55/70) — encadeia apertando no ritmo.
func cmd_basic_attack() -> void:
	if state != State.FREE or combo.active:
		return
	if not _has_live_target():
		skill_failed.emit(0, "no_target")
		return
	if _dist_to_target() > BASIC_RANGE:
		skill_failed.emit(0, "out_of_range")
		return
	_face_target_instant()
	state = State.ATTACKING
	_approach_active = true
	var idx := _chain_index
	var speed := _buff_attack_speed_mult
	await get_tree().create_timer(BASIC_WINDUP / speed).timeout
	_approach_active = false
	if _has_live_target() and _dist_to_target() <= BASIC_RANGE + 0.5:
		_deal_damage_to(target, BASIC_DAMAGE[idx], false)
	basic_attack_performed.emit(idx)
	_chain_index = (idx + 1) % BASIC_DAMAGE.size()
	_chain_timer = CHAIN_WINDOW
	await get_tree().create_timer(BASIC_RECOVER / speed).timeout
	if state == State.ATTACKING:
		state = State.FREE

## Teclas 1-5: skills do quickslot (slot é 1-based).
func cmd_use_skill(slot: int) -> void:
	var i := slot - 1
	if i < 0 or i >= skills.size() or skills[i] == null:
		return
	var sk := skills[i]
	if state != State.FREE:
		skill_failed.emit(slot, "busy")
		return
	if _cooldowns.get(slot, 0.0) > 0.0:
		skill_failed.emit(slot, "cooldown")
		return
	if mp < sk.mp_cost:
		skill_failed.emit(slot, "no_mp")
		return
	var needs_target := sk.type == SkillData.Type.MELEE_SINGLE or sk.type == SkillData.Type.DASH
	if needs_target:
		if not _has_live_target():
			skill_failed.emit(slot, "no_target")
			return
		if _dist_to_target() > sk.reach:
			skill_failed.emit(slot, "out_of_range")
			return

	# Combo: timing do marcador decide encadear (instantâneo + bônus) ou quebrar
	var instant := false
	var bonus := 1.0
	if combo.active:
		if combo.try_link():
			instant = true
			bonus = 1.0 + combo.damage_bonus()
			combo_linked.emit(combo.links, combo.damage_bonus())
		else:
			combo.stop()
			combo_mode_changed.emit(false)
			combo_broken.emit()

	mp -= sk.mp_cost
	mp_changed.emit(mp, max_mp)
	_cooldowns[slot] = sk.cooldown
	cooldown_started.emit(slot, sk.cooldown)
	skill_used.emit(slot, sk)

	match sk.type:
		SkillData.Type.MELEE_SINGLE:
			_do_melee_single(sk, instant, bonus)
		SkillData.Type.MELEE_AOE:
			_do_melee_aoe(sk, instant, bonus)
		SkillData.Type.DASH:
			_do_dash(sk, bonus)
		SkillData.Type.BUFF:
			_do_buff(sk, instant)

# ------------------------------------------------------------------
# Execução das skills
# ------------------------------------------------------------------

func _do_melee_single(sk: SkillData, instant: bool, bonus: float) -> void:
	_face_target_instant()
	state = State.CASTING
	if not instant and sk.cast_time > 0.0:
		_approach_active = true
		await get_tree().create_timer(sk.cast_time).timeout
		_approach_active = false
	if _has_live_target() and _dist_to_target() <= sk.reach + 1.0:
		_deal_damage_to(target, sk.damage, sk.heavy_hit, bonus)
		if sk.stun_duration > 0.0:
			target.apply_stun(sk.stun_duration)
	state = State.FREE

func _do_melee_aoe(sk: SkillData, instant: bool, bonus: float) -> void:
	if target != null:
		_face_target_instant()
	state = State.CASTING
	if not instant and sk.cast_time > 0.0:
		await get_tree().create_timer(sk.cast_time).timeout
	var interval: float = sk.duration / float(sk.hits) if sk.hits > 1 else 0.0
	for h in sk.hits:
		var victims: Array = await _query_aoe(sk)
		for v in victims:
			_deal_damage_to(v, sk.damage, sk.heavy_hit, bonus)
			if sk.stun_duration > 0.0:
				v.apply_stun(sk.stun_duration)
		if interval > 0.0 and h < sk.hits - 1:
			await get_tree().create_timer(interval).timeout
	state = State.FREE

func _do_dash(sk: SkillData, bonus: float) -> void:
	_face_target_instant()
	state = State.DASHING
	_dash_skill = sk
	_dash_bonus = bonus
	_dash_traveled = 0.0

func _do_buff(sk: SkillData, instant: bool) -> void:
	state = State.CASTING
	if not instant and sk.cast_time > 0.0:
		await get_tree().create_timer(sk.cast_time).timeout
	berserk_left = sk.duration
	_buff_damage_mult = sk.buff_damage_mult
	_buff_attack_speed_mult = sk.buff_attack_speed_mult
	buff_changed.emit(true, sk.duration)
	state = State.FREE

## Consulta a hitbox Area3D (esfera) da skill; retorna inimigos vivos dentro.
func _query_aoe(sk: SkillData) -> Array:
	_hitbox_shape.shape.radius = sk.aoe_radius
	_hitbox.position = Vector3(0.0, 1.0, -sk.aoe_forward_offset)
	_hitbox.monitoring = true
	# Area3D atualiza overlaps por frame de física — espera dois pra garantir
	await get_tree().physics_frame
	await get_tree().physics_frame
	var out: Array = []
	for b in _hitbox.get_overlapping_bodies():
		if b.is_in_group("enemies") and b.has_method("is_alive") and b.is_alive():
			out.append(b)
	_hitbox.monitoring = false
	return out

func _deal_damage_to(victim: Node3D, base: float, heavy: bool, bonus_mult := 1.0) -> void:
	var dmg := base * bonus_mult * _buff_damage_mult * (base_attack / 50.0)
	var is_crit := _rng.randf() < crit_chance
	if is_crit:
		dmg *= crit_mult
	dmg = roundf(dmg)
	victim.apply_damage(dmg, is_crit, heavy)
	dealt_damage.emit(victim, dmg, is_crit, heavy)

# ------------------------------------------------------------------
# Consultas de estado (a UI/apresentação lê, nunca escreve)
# ------------------------------------------------------------------

func get_cooldown(slot: int) -> float:
	return _cooldowns.get(slot, 0.0)

func _has_live_target() -> bool:
	return target != null and is_instance_valid(target) and target.is_alive()

func _dist_to_target() -> float:
	if target == null:
		return INF
	var d := target.global_position - global_position
	d.y = 0.0
	return d.length()
