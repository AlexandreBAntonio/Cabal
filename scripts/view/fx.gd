extends Node
## Autoload "Fx" — hit feedback global (camada de apresentação):
## hit stop, screen shake e números de dano flutuantes.

var camera_rig: CameraRig = null

var _stopping := false

## Hit stop: ~0.06s em acertos normais, ~0.12s em skills pesadas.
func hit_stop(duration: float) -> void:
	if _stopping:
		return
	_stopping = true
	Engine.time_scale = 0.05
	# timer ignora time_scale pra não congelar o jogo pra sempre
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0
	_stopping = false

func shake(strength := 1.0) -> void:
	if camera_rig != null:
		camera_rig.add_shake(strength)

## Número de dano flutuante; crítico em amarelo e maior.
func damage_number(pos: Vector3, amount: float, is_crit: bool) -> void:
	var label := Label3D.new()
	label.text = str(int(roundf(amount))) + ("!" if is_crit else "")
	label.font_size = 96 if is_crit else 56
	label.outline_size = 14
	label.modulate = Color(1.0, 0.8, 0.15) if is_crit else Color.WHITE
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	get_tree().current_scene.add_child(label)
	label.global_position = pos + Vector3(randf_range(-0.4, 0.4), 0.0, randf_range(-0.2, 0.2))
	var tw := label.create_tween()
	tw.tween_property(label, "position:y", label.position.y + 1.7, 0.75)
	tw.parallel().tween_property(label, "modulate:a", 0.0, 0.75).set_ease(Tween.EASE_IN)
	tw.tween_callback(label.queue_free)
