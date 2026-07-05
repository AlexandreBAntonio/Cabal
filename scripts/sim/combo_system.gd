class_name ComboSystem
extends RefCounted
## Barra de timing estilo Cabal. Com o modo ativo, um marcador oscila na barra;
## usar a próxima skill com o marcador dentro da zona encadeia o combo
## (sem cast time, +5% de dano por elo, máx +25%). Errar quebra o combo.

const ZONE_START := 0.40
const ZONE_END := 0.62
const MARKER_SPEED := 0.9        ## ciclos por segundo
const BONUS_PER_LINK := 0.05
const MAX_BONUS := 0.25

var active := false
var marker := 0.0                ## posição 0..1 na barra
var links := 0

var _dir := 1.0

func start() -> void:
	active = true
	marker = 0.0
	_dir = 1.0
	links = 0

func stop() -> void:
	active = false
	links = 0

func tick(delta: float) -> void:
	if not active:
		return
	marker += _dir * MARKER_SPEED * delta
	if marker >= 1.0:
		marker = 1.0
		_dir = -1.0
	elif marker <= 0.0:
		marker = 0.0
		_dir = 1.0

func in_zone() -> bool:
	return marker >= ZONE_START and marker <= ZONE_END

## Tenta encadear: sucesso soma um elo, falha retorna false (chamador quebra o combo).
func try_link() -> bool:
	if in_zone():
		links += 1
		return true
	return false

func damage_bonus() -> float:
	return minf(links * BONUS_PER_LINK, MAX_BONUS)
