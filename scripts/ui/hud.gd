extends CanvasLayer
## UI mínima estilo Cabal: HP/MP no canto inferior, quickslot bar com
## cooldowns, barra de combo com marcador, target frame no topo e
## mensagens de feedback ("Fora de alcance" etc.).
## Apresentação pura: lê o estado da simulação, nunca o altera.

const SLOT_SIZE := Vector2(56, 56)
const COMBO_BAR_SIZE := Vector2(320, 22)

@export var sim_path: NodePath

@onready var sim: GladiatorSim = get_node(sim_path)

var _hp_fill: ColorRect
var _mp_fill: ColorRect
var _hp_label: Label
var _mp_label: Label
var _slot_cds: Array[Label] = []
var _slot_dims: Array[ColorRect] = []
var _combo_root: Control
var _combo_marker: ColorRect
var _combo_label: Label
var _target_root: Control
var _target_fill: ColorRect
var _target_label: Label
var _msg_label: Label
var _buff_label: Label

func _ready() -> void:
	_build_ui()
	sim.skill_failed.connect(_on_skill_failed)
	sim.combo_broken.connect(func(): _show_message("Combo quebrado!"))
	sim.combo_linked.connect(func(links, bonus):
		_show_message("Combo x%d (+%d%%)" % [links, int(bonus * 100)]))

func _process(_delta: float) -> void:
	_hp_fill.scale.x = sim.hp / sim.max_hp
	_mp_fill.scale.x = sim.mp / sim.max_mp
	_hp_label.text = "HP %d / %d" % [int(sim.hp), int(sim.max_hp)]
	_mp_label.text = "MP %d / %d" % [int(sim.mp), int(sim.max_mp)]

	for i in 5:
		var cd := sim.get_cooldown(i + 1)
		_slot_cds[i].text = "%.1f" % cd if cd > 0.0 else ""
		_slot_dims[i].visible = cd > 0.0

	_combo_root.visible = sim.combo.active
	if sim.combo.active:
		_combo_marker.position.x = sim.combo.marker * (COMBO_BAR_SIZE.x - 4.0)
		_combo_label.text = "COMBO x%d (+%d%%)" % [sim.combo.links, int(sim.combo.damage_bonus() * 100)]

	var t: DummySim = sim.target as DummySim
	if t != null and is_instance_valid(t) and t.is_alive():
		_target_root.visible = true
		_target_label.text = "%s  %d / %d" % [t.name, int(t.hp), int(t.max_hp)]
		_target_fill.scale.x = t.hp / t.max_hp
	else:
		_target_root.visible = false

	_buff_label.visible = sim.berserk_left > 0.0
	if _buff_label.visible:
		_buff_label.text = "BERSERK %.1fs" % sim.berserk_left

func _on_skill_failed(_slot: int, reason: String) -> void:
	match reason:
		"out_of_range": _show_message("Fora de alcance")
		"no_mp": _show_message("MP insuficiente")
		"cooldown": _show_message("Em cooldown")
		"no_target": _show_message("Sem alvo (Tab ou clique)")
		"busy": pass

func _show_message(text: String) -> void:
	_msg_label.text = text
	_msg_label.modulate.a = 1.0
	var tw := _msg_label.create_tween()
	tw.tween_property(_msg_label, "modulate:a", 0.0, 1.2).set_delay(0.6)

# ------------------------------------------------------------------
# Construção da UI (placeholders com ColorRect/Label)
# ------------------------------------------------------------------

func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# --- HP/MP (canto inferior esquerdo) ---
	var bars := VBoxContainer.new()
	bars.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	bars.position = Vector2(24, -96)
	bars.add_theme_constant_override("separation", 6)
	root.add_child(bars)
	var hp := _make_bar(Color(0.75, 0.15, 0.15), Vector2(260, 20))
	_hp_fill = hp[1]
	_hp_label = hp[2]
	bars.add_child(hp[0])
	var mp := _make_bar(Color(0.15, 0.35, 0.85), Vector2(260, 20))
	_mp_fill = mp[1]
	_mp_label = mp[2]
	bars.add_child(mp[0])

	# --- Quickslots (centro inferior) ---
	var slots := HBoxContainer.new()
	slots.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	slots.add_theme_constant_override("separation", 8)
	slots.position = Vector2(-(SLOT_SIZE.x * 5 + 32) / 2.0, -80)
	root.add_child(slots)
	for i in 5:
		slots.add_child(_make_slot(i))

	# --- Barra de combo (acima dos quickslots) ---
	_combo_root = Control.new()
	_combo_root.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_combo_root.position = Vector2(-COMBO_BAR_SIZE.x / 2.0, -150)
	_combo_root.visible = false
	root.add_child(_combo_root)
	var track := ColorRect.new()
	track.color = Color(0.08, 0.08, 0.1, 0.9)
	track.size = COMBO_BAR_SIZE
	_combo_root.add_child(track)
	var zone := ColorRect.new()
	zone.color = Color(0.9, 0.75, 0.2, 0.85)
	zone.position = Vector2(ComboSystem.ZONE_START * COMBO_BAR_SIZE.x, 0)
	zone.size = Vector2((ComboSystem.ZONE_END - ComboSystem.ZONE_START) * COMBO_BAR_SIZE.x, COMBO_BAR_SIZE.y)
	_combo_root.add_child(zone)
	_combo_marker = ColorRect.new()
	_combo_marker.color = Color.WHITE
	_combo_marker.size = Vector2(4, COMBO_BAR_SIZE.y + 8)
	_combo_marker.position.y = -4
	_combo_root.add_child(_combo_marker)
	_combo_label = Label.new()
	_combo_label.position = Vector2(0, -26)
	_combo_root.add_child(_combo_label)

	# --- Target frame (topo) ---
	_target_root = Control.new()
	_target_root.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_target_root.position = Vector2(-130, 18)
	_target_root.visible = false
	root.add_child(_target_root)
	var tbar := _make_bar(Color(0.8, 0.2, 0.15), Vector2(260, 18))
	_target_fill = tbar[1]
	_target_label = tbar[2]
	_target_root.add_child(tbar[0])

	# --- Mensagens de feedback (centro) ---
	_msg_label = Label.new()
	_msg_label.set_anchors_preset(Control.PRESET_CENTER)
	_msg_label.position = Vector2(-120, 60)
	_msg_label.custom_minimum_size = Vector2(240, 0)
	_msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_msg_label.add_theme_font_size_override("font_size", 22)
	_msg_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.3))
	_msg_label.modulate.a = 0.0
	root.add_child(_msg_label)

	# --- Indicador do Berserk ---
	_buff_label = Label.new()
	_buff_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_buff_label.position = Vector2(-60, -190)
	_buff_label.add_theme_font_size_override("font_size", 18)
	_buff_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.25))
	_buff_label.visible = false
	root.add_child(_buff_label)

## Retorna [container, fill, label] — barra com fundo escuro e fill colorido.
func _make_bar(color: Color, bar_size: Vector2) -> Array:
	var holder := Control.new()
	holder.custom_minimum_size = bar_size
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.06, 0.08, 0.9)
	bg.size = bar_size
	holder.add_child(bg)
	var fill := ColorRect.new()
	fill.color = color
	fill.size = bar_size - Vector2(4, 4)
	fill.position = Vector2(2, 2)
	holder.add_child(fill)
	var label := Label.new()
	label.size = bar_size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 13)
	holder.add_child(label)
	return [holder, fill, label]

func _make_slot(index: int) -> Control:
	var panel := Panel.new()
	panel.custom_minimum_size = SLOT_SIZE
	var key := Label.new()
	key.text = str(index + 1)
	key.position = Vector2(5, 2)
	key.add_theme_font_size_override("font_size", 14)
	panel.add_child(key)
	var skill_name := Label.new()
	# acesso defensivo: se o .tres carregou sem o script (cache de import
	# corrompido), mostra slot vazio em vez de quebrar a HUD inteira
	var sk: Resource = sim.skills[index] if index < sim.skills.size() else null
	skill_name.text = (sk as SkillData).display_name.left(9) if sk is SkillData else ""
	skill_name.position = Vector2(3, SLOT_SIZE.y - 20)
	skill_name.add_theme_font_size_override("font_size", 10)
	panel.add_child(skill_name)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.size = SLOT_SIZE
	dim.visible = false
	panel.add_child(dim)
	_slot_dims.append(dim)
	var cd := Label.new()
	cd.size = SLOT_SIZE
	cd.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cd.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cd.add_theme_font_size_override("font_size", 18)
	panel.add_child(cd)
	_slot_cds.append(cd)
	return panel
